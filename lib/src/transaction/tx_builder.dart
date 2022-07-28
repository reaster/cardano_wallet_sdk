// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:oxidized/oxidized.dart';
import '../hd/hd_account.dart';
import '../address/shelley_address.dart';
import '../asset/asset.dart';
import '../blockchain/blockchain_adapter.dart';
import '../util/ada_types.dart';
import '../wallet/wallet.dart';
import './min_fee_function.dart';
import './transaction.dart';
import './model/bc_tx.dart';
import './model/bc_tx_body_ext.dart';
import './model/bc_tx_ext.dart';
import 'coin_selection.dart';

///
/// This builder manages the details of assembling a balanced transaction, including
/// fee calculation, change callculation, time-to-live constraints (ttl) and signing.
///
/// Using the build() and sign() methods, transactions can be built manually. However,
/// you have to ensure the inputs, outputs and fee add up to zero (i.e. the isBalanced
/// property should be true). Using the buildAndSign() method automates this process
/// given a recipient and amount.
///
/// Coin selection is not currently handled internally, see CoinSelectionAlgorithm.
///
class TxBuilder {
  final logger = Logger('TxBuilder');
  BlockchainAdapter? _blockchainAdapter;
  CoinSelectionAlgorithm _coinSelectionFunction = largestFirst;
  Wallet? _wallet; //TODO prefer not to depend on high-level API
  List<BcTransactionInput> _inputs = [];
  FlatMultiAsset? _spendRequest;
  List<BcTransactionOutput> _outputs = [];
  AbstractAddress? _toAddress;
  ShelleyReceiveKit? _changeAddress;
  //calculated internally
  Coin _fee = coinZero;
  //fixes min fee if set
  Coin _minFee = coinZero;
  int _ttl = 0;
  List<int>? _metadataHash;
  int? _validityStartInterval;
  List<BcMultiAsset> _mint = [];
  BcTransactionWitnessSet? _witnessSet;
  BcMetadata? _metadata;
  MinFeeFunction _minFeeFunction = simpleMinFee;
  LinearFee _linearFee = defaultLinearFee;
  int _currentSlot = 0;
  DateTime _currentSlotTimestamp = DateTime.now().toUtc();

  /// Added to current slot to get ttl. Currently 900sec or 15min.
  final defaultTtlDelta = 900;

  /// How often to check current slot. If 1 minute old, update
  final staleSlotCuttoff = const Duration(seconds: 60);

  BcTransactionBody _buildBody() => BcTransactionBody(
        inputs: _inputs,
        outputs: _outputs,
        fee: _fee,
        ttl: _ttl,
        metadataHash: _metadataHash,
        validityStartInterval: _validityStartInterval ?? 0,
        mint: _mint,
      );

  /// simple build - assemble transaction without any validation
  BcTransaction build() => BcTransaction(
      body: _buildBody(), witnessSet: _witnessSet, metadata: _metadata);

  /// manually sign transacion and set single witnessSet.
  BcTransaction sign() {
    final body = _buildBody();
    // Map<ShelleyAddress, Bip32KeyPair> utxoKeyPairs = _loadUtxosAndTheirKeys();
    final signingKeys =
        _loadUtxosAndTheirKeys().values.map((p) => p.signingKey).toList();
    //_witnessSet = _sign(body: body, keyPairSet: utxoKeyPairs.values.toSet());
    return BcTransaction(
            body: body, witnessSet: _witnessSet, metadata: _metadata)
        .sign(signingKeys);
  }

  /// Check if inputs and outputs including fee, add up to zero or balance out.
  bool get isBalanced {
    final result = _buildBody()
        .transactionIsBalanced(cache: _blockchainAdapter!, fee: _fee);
    return result.isOk() && result.unwrap();
  }

  AbstractAddress? _utxosFromTransaction(
      BcTransactionInput input, Set<AbstractAddress> ownSet) {
    final RawTransaction? tx =
        _blockchainAdapter!.cachedTransaction(input.transactionId);
    if (tx != null) {
      final txOutput = tx.outputs[input.index];
      if (ownSet.contains(txOutput.address)) {
        return txOutput.address;
      }
    }
    return null;
  }

  /// TODO don't support spending Byron UTxOs
  Map<ShelleyAddress, ShelleyUtxoKit> _loadUtxosAndTheirKeys() {
    Set<AbstractAddress> ownedAddresses = _wallet!.addresses.toSet();
    Set<ShelleyAddress> utxos = {};
    for (BcTransactionInput input in _inputs) {
      AbstractAddress? utxo = _utxosFromTransaction(input, ownedAddresses);
      if (utxo != null) {
        if (utxo.addressType == AddressType.byron) {
          logger.severe("don't support spending Byron UTxOs: $utxo");
        } else {
          utxos.add(utxo as ShelleyAddress);
        }
      }
    }
    final utxoKitList = _wallet!.findSigningKeyForUtxos(utxos: utxos);
    return utxoKitList;
  }

  // BcTransactionWitnessSet signAndBuildWitnesses(
  //     Map<ShelleyAddress, Bip32KeyPair> utxoKeyPairs, List<int> signature) {
  //   List<BcVkeyWitness> vkeyWitnesses = [];
  //   for (final keyPair in utxoKeyPairs.values) {
  //     final BcVkeyWitness witness =
  //         BcVkeyWitness(signature: signature, vkey: keyPair.verifyKey!.rawKey);
  //     vkeyWitnesses.add(witness);
  //   }
  //   return BcTransactionWitnessSet(
  //       vkeyWitnesses: vkeyWitnesses, nativeScripts: []);
  // }

  ///
  /// Automates building a valid, signed transaction inlcuding checking required inputs, calculating
  /// ttl, fee and change.
  ///
  /// Coin selection must be done externally and assigned to the 'inputs' property.
  /// The fee is automaticly calculated and adjusted based on the final transaction size.
  /// If no outputs are supplied, a toAddress and value are required instead.
  /// An unused changeAddress should be supplied weather it's needed or not.
  /// Bip32KeyPair is required for signing the transaction and supplying the public key to the witness.
  /// The same instance of BlockchainAdapter must be supplied that read the blockchain balances as
  /// it will contain the cached UTxOs needed to calculate the input amounts.
  ///
  /// TODO handle edge case where selectd coins have to be changed based on fee adjustment.
  /// TODO have a simpler builder that takes hard-coded outputs? this builder would call that one
  ///
  Future<Result<BcTransaction, String>> buildAndSign(
      {bool mustBalance = true}) async {
    final dataCheck = _checkContraints();
    if (dataCheck.isErr()) return Err(dataCheck.unwrapErr());
    //calculate time to live if not supplied
    if (_ttl == 0) {
      final result = await calculateTimeToLive();
      if (result.isErr()) {
        return Err(result.unwrapErr());
      }
      _ttl = result.unwrap();
    }
    //treat spendRequest.fee as minFee if set:
    if (_minFee == 0 && _spendRequest != null && _spendRequest!.fee != 0) {
      _minFee = _spendRequest!.fee;
    }
    //make sure existing spendRequest.fee is not zero
    if (_spendRequest != null && _spendRequest!.fee == 0) {
      _spendRequest = FlatMultiAsset(
          assets: _spendRequest!.assets,
          fee: _minFee > 0 ? _minFee : defaultFee);
    }
    bool balanced = true;
    do {
      if (_spendRequest != null) {
        final inputsResult = await _coinSelectionFunction(
          spendRequest: _spendRequest!,
          unspentInputsAvailable: _wallet!.unspentTransactions,
          ownedAddresses: _wallet!.addresses.toSet(),
        );
        if (inputsResult.isOk()) {
          _inputs = inputsResult.unwrap().inputs;
        } else {
          final coinSelErr = inputsResult.unwrapErr();
          return Err(coinSelErr.message);
        }
      }
      if (_inputs.isEmpty) {
        return Err("inputs are empty");
      }
      //convert value into spend output if not zero
      if (_toAddress != null && _outputs.isEmpty && _spendRequest != null) {
        final outputResult = flatMultiAssetToOutput(
            toAddress: _toAddress!, spendRequest: _spendRequest!);
        if (outputResult.isErr()) {
          return Err(outputResult.unwrapErr());
        }
        _outputs.add(outputResult.unwrap());
      }
      if (_outputs.isEmpty) {
        return Err("no outputs specified");
      }
      var body = _buildBody();
      //adjust change to balance transaction
      final balanceResult = body.balancedOutputsWithChange(
          changeAddress: _changeAddress!.address,
          cache: _blockchainAdapter!,
          fee: _fee);
      if (balanceResult.isErr()) return Err(balanceResult.unwrapErr());
      _outputs = balanceResult.unwrap();
      //build the complete (fake) signed transaction so we can calculate a more accurate fee
      body = _buildBody();
      Map<AbstractAddress, ShelleyUtxoKit> utxoKeyPairs =
          _loadUtxosAndTheirKeys();
      if (utxoKeyPairs.isEmpty) {
        return Err("no UTxOs found in transaction");
      }
      final signingKeys = utxoKeyPairs.values.map((p) => p.signingKey).toList();
      var tx = BcTransaction(
              body: body, witnessSet: _witnessSet, metadata: _metadata)
          .sign(signingKeys, fakeSignature: true);
      _fee = calculateMinFee(tx: tx, minFee: _minFee);
      //rebalance change to fit the new fee
      final balanceResult2 = body.balancedOutputsWithChange(
          changeAddress: _changeAddress!.address,
          cache: _blockchainAdapter!,
          fee: _fee);
      if (balanceResult2.isErr()) return Err(balanceResult2.unwrapErr());
      _outputs = balanceResult2.unwrap();
      body = _buildBody();
      //re-sign to capture changes
      tx = BcTransaction(
              body: body, witnessSet: _witnessSet, metadata: _metadata)
          .sign(signingKeys, fakeSignature: false);
      if (mustBalance) {
        final balancedResult = tx.body
            .transactionIsBalanced(cache: _blockchainAdapter!, fee: _fee);
        if (balancedResult.isErr()) return Err(balancedResult.unwrapErr());
      }
      //now, double check our UTxOs still cover the new fee
      if (_spendRequest != null) {
        _spendRequest =
            FlatMultiAsset(assets: _spendRequest!.assets, fee: _fee);

        final inputsResult = await _coinSelectionFunction(
          spendRequest: _spendRequest!,
          unspentInputsAvailable: _wallet!.unspentTransactions,
          ownedAddresses: _wallet!.addresses.toSet(),
        );
        if (inputsResult.isOk()) {
          final inputs2 = inputsResult.unwrap().inputs;
          balanced = const ListEquality().equals(_inputs, inputs2);
        } else {
          final coinSelErr = inputsResult.unwrapErr();
          return Err(coinSelErr.message);
        }
      }
      if (balanced) {
        return Ok(tx);
      }
    } while (!balanced);
    return Err("should never land here");
  }

  Result<BcTransactionOutput, String> flatMultiAssetToOutput(
      {required AbstractAddress toAddress,
      required FlatMultiAsset spendRequest}) {
    Coin coin = spendRequest.assets[lovelaceHex] ?? coinZero;
    final builder = MultiAssetBuilder(coin: coin);
    for (final assetId in spendRequest.assets.keys) {
      if (assetId == lovelaceHex) continue;
      CurrencyAsset? asset = _blockchainAdapter!.cachedCurrencyAsset(assetId);
      if (asset != null) {
        builder.nativeAsset(
            policyId: asset.policyId,
            hexName: asset.assetName,
            value: spendRequest.assets[assetId] ?? coinZero);
      } else {
        return Err("no asset found in BlockchainAdapter for assetId: $assetId");
      }
    }
    return Ok(BcTransactionOutput(
        address: toAddress.toString(), value: builder.build()));
  }

  Result<bool, String> _checkContraints() {
    if (_blockchainAdapter == null) {
      return Err("'blockchainAdapter' property must be set");
    }
    if (_outputs.isEmpty && _spendRequest == null && _toAddress == null) {
      return Err(
          "when 'outputs' is not set, 'spendRequest' and 'toAddress' properties must be set");
    }
    if (_spendRequest != null) {
      if (_minFee != 0 &&
          _spendRequest!.fee != 0 &&
          _minFee != _spendRequest!.fee) {
        return Err(
            "specified fees conflict minFee: $_minFee and spendRequest.fee: ${_spendRequest!.fee}. Specify only one.");
      }
    }
    if (_changeAddress == null) {
      return Err("'changeAddress' property must be set");
    }
    return Ok(true);
  }

  /// Because transaction size effects fees, this method should be called last, after all other
  /// BcTransactionBody properties are set.
  /// if minFee is set, then this determines the lower minimum fee bound.
  Coin calculateMinFee({required BcTransaction tx, Coin minFee = 0}) {
    Coin calculatedFee =
        _minFeeFunction(transaction: tx, linearFee: _linearFee);
    final fee = (calculatedFee < minFee) ? minFee : calculatedFee;
    return fee;
  }

  /// return true if the ttl-focused current slot is stale or needs to be refreshed based
  /// on the current time and staleSlotCuttoff.
  bool get isCurrentSlotUnsetOrStale {
    if (_currentSlot == 0) return true; //not set
    final now = DateTime.now().toUtc();
    final cutoff = _currentSlotTimestamp.add(staleSlotCuttoff);
    final isStale = cutoff.isBefore(now); //cuttoff reached?
    return isStale;
  }

  /// Set the time range in which this transaction is valid.
  /// Time-to-live (TTL) - represents a slot, or deadline by which a transaction must be submitted.
  /// The TTL is an absolute slot number, rather than a relative one, which means that the ttl value
  /// should be greater than the current slot number. A transaction becomes invalid once its ttl expires.
  /// Currently each slot is one second and each epoch currently includes 432,000 slots (5 days).
  Future<Result<int, String>> calculateTimeToLive() async {
    if (isCurrentSlotUnsetOrStale) {
      final result = await _blockchainAdapter!.latestBlock();
      if (result.isErr()) {
        return Err(result.unwrapErr());
      } else {
        final block = result.unwrap();
        _currentSlot = block.slot;
        _currentSlotTimestamp = block.time;
      }
    }
    if (_ttl != 0) {
      if (_ttl < _currentSlot) {
        return Err(
            "specified ttl of $_ttl can't be less than current slot: $_currentSlot");
      }
      return Ok(_ttl);
    }

    return Ok(_currentSlot + defaultTtlDelta);
  }

  void blockchainAdapter(BlockchainAdapter blockchainAdapter) =>
      _blockchainAdapter = blockchainAdapter;

  // void keyPair(Bip32KeyPair keyPair) => _keyPair = keyPair;

  void wallet(Wallet wallet) {
    _wallet = wallet;
    // _keyPair = _wallet!.rootKeyPair;
  }

  void spendRequest(FlatMultiAsset spendRequest) =>
      _spendRequest = spendRequest;

  void changeAddress(ShelleyReceiveKit changeAddress) =>
      _changeAddress = changeAddress;

  void toAddress(AbstractAddress toAddress) => _toAddress = toAddress;

  void currentSlot(int currentSlot) => _currentSlot = currentSlot;

  void minFeeFunction(MinFeeFunction feeFunction) =>
      _minFeeFunction = feeFunction;

  void linearFee(LinearFee linearFee) => _linearFee = linearFee;

  void metadataHash(List<int>? metadataHash) => _metadataHash = metadataHash;

  void validityStartInterval(int validityStartInterval) =>
      _validityStartInterval = validityStartInterval;

  //void fee(Coin fee) => _fee = fee;

  void coinSelectionFunction(CoinSelectionAlgorithm coinSelectionFunction) =>
      _coinSelectionFunction = coinSelectionFunction;

  void minFee(Coin minFee) => _minFee = minFee;

  void mint(BcMultiAsset mint) => _mint.add(mint);

  void mints(List<BcMultiAsset> mint) => _mint = mint;

  void ttl(int ttl) => _ttl = ttl;

  void inputs(List<BcTransactionInput> inputs) => _inputs = inputs;

  void txInput(BcTransactionInput input) => _inputs.add(input);

  void input({required String transactionId, required int index}) =>
      txInput(BcTransactionInput(transactionId: transactionId, index: index));

  void txOutput(BcTransactionOutput output) => _outputs.add(output);

  void witnessSet(BcTransactionWitnessSet witnessSet) =>
      _witnessSet = witnessSet;

  void metadata(BcMetadata metadata) => _metadata = metadata;

  /// build a single BcTransactionOutput, handle complex output construction
  void output({
    ShelleyAddress? shelleyAddress,
    String? address,
    MultiAssetBuilder? multiAssetBuilder,
    BcValue? value,
    bool autoAddMinting = true,
  }) {
    assert(address != null || shelleyAddress != null);
    assert(!(address != null && shelleyAddress != null));
    final String addr =
        shelleyAddress != null ? shelleyAddress.toBech32() : address!;
    assert(multiAssetBuilder != null || value != null);
    assert(!(multiAssetBuilder != null && value != null));
    final val = value ?? multiAssetBuilder!.build();
    final output = BcTransactionOutput(address: addr, value: val);
    _outputs.add(output);
    if (autoAddMinting) {
      _mint.addAll(val.multiAssets);
    }
  }

  // void coinSelectionFunction(CoinSelectionAlgorithm coinSelectionFunction) =>
  //     _coinSelectionFunction = coinSelectionFunction;

  // void unspentInputsAvailable(List<WalletTransaction> unspentInputsAvailable) =>
  //     _unspentInputsAvailable = unspentInputsAvailable;

  // void coinSelectionOutputsRequested(List<BcMultiAsset> coinSelectionOutputsRequested) =>
  //     _coinSelectionOutputsRequested = coinSelectionOutputsRequested;

  // void coinSelectionOwnedAddresses(Set<ShelleyAddress> coinSelectionOwnedAddresses) =>
  //     _coinSelectionOwnedAddresses = coinSelectionOwnedAddresses;

  // void coinSelectionLimit(int coinSelectionLimit) => _coinSelectionLimit = coinSelectionLimit;

  // TransactionBuilder send({ShelleyAddress? shelleyAddress, String? address, Coin lovelace = 0, Coin ada = 0}) {
  //   assert(address != null || shelleyAddress != null);
  //   assert(!(address != null && shelleyAddress != null));
  //   final String addr = shelleyAddress != null ? shelleyAddress.toBech32() : address!;
  //   final amount = lovelace + ada * 1000000;
  //   return txOutput(BcTransactionOutput(address: addr, value: BcValue(coin: amount, multiAssets: [])));
  // }
}

//typedef CurrentEpochFunction = Future<int> Function();

///
/// Special builder for creating BcValue objects containing multi-asset transactions.
///
class MultiAssetBuilder {
  final Coin coin;
  final List<BcMultiAsset> _multiAssets = [];
  MultiAssetBuilder({required this.coin});
  BcValue build() => BcValue(coin: coin, multiAssets: _multiAssets);
  MultiAssetBuilder nativeAsset(
      {required String policyId, String? hexName, required Coin value}) {
    final nativeAsset = BcMultiAsset(policyId: policyId, assets: [
      BcAsset(name: hexName ?? '', value: value),
    ]);
    _multiAssets.add(nativeAsset);
    return this;
  }

  MultiAssetBuilder nativeAsset2({
    required String policyId,
    String? hexName1,
    required int value1,
    String? hexName2,
    required int value2,
  }) {
    final nativeAsset = BcMultiAsset(policyId: policyId, assets: [
      BcAsset(name: hexName1 ?? '', value: value1),
      BcAsset(name: hexName2 ?? '', value: value2),
    ]);
    _multiAssets.add(nativeAsset);
    return this;
  }

  MultiAssetBuilder asset(CurrencyAsset asset) {
    final nativeAsset = BcMultiAsset(policyId: asset.policyId, assets: [
      BcAsset(name: asset.assetName, value: int.parse(asset.quantity)),
    ]);
    _multiAssets.add(nativeAsset);
    return this;
  }
}
