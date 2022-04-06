// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:bip32_ed25519/api.dart';
import 'package:oxidized/oxidized.dart';
import 'package:pinenacl/tweetnacl.dart';
import '../address/hd_wallet.dart';
import '../address/shelley_address.dart';
import '../asset/asset.dart';
import '../blockchain/blockchain_adapter.dart';
import '../util/blake2bhash.dart';
import '../util/ada_types.dart';
import './transaction.dart';
import '../wallet/wallet.dart';
import './spec/shelley_spec.dart';
import './spec/shelley_tx_body_logic_ext.dart';
import './min_fee_function.dart';

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
class TransactionBuilder {
  BlockchainAdapter? _blockchainAdapter;
  Wallet? _wallet;
  Bip32KeyPair? _keyPair;
  List<ShelleyTransactionInput> _inputs = [];
  List<ShelleyTransactionOutput> _outputs = [];
  ShelleyAddress? _toAddress;
  ShelleyAddress? _changeAddress;
  ShelleyValue _value = ShelleyValue(coin: 0, multiAssets: []);
  Coin _fee = defaultFee;
  Coin _minFee = coinZero;
  int _ttl = 0;
  List<int>? _metadataHash;
  int? _validityStartInterval;
  List<ShelleyMultiAsset> _mint = [];
  ShelleyTransactionWitnessSet? _witnessSet;
  CBORMetadata? _metadata;
  MinFeeFunction _minFeeFunction = simpleMinFee;
  LinearFee _linearFee = defaultLinearFee;
  int _currentSlot = 0;
  DateTime _currentSlotTimestamp = DateTime.now().toUtc();

  /// Added to current slot to get ttl. Currently 900sec or 15min.
  final defaultTtlDelta = 900;

  /// How often to check current slot. If 1 minute old, update
  final staleSlotCuttoff = const Duration(seconds: 60);

  ShelleyTransactionBody _buildBody() => ShelleyTransactionBody(
        inputs: _inputs,
        outputs: _outputs,
        fee: _fee,
        ttl: _ttl,
        metadataHash: _metadataHash,
        validityStartInterval: _validityStartInterval ?? 0,
        mint: _mint,
      );

  /// simple build - assemble transaction without any validation
  ShelleyTransaction build() => ShelleyTransaction(
      body: _buildBody(), witnessSet: _witnessSet, metadata: _metadata);

  /// manually sign transacion and set single witnessSet.
  ShelleyTransaction sign() {
    final body = _buildBody();
    Map<ShelleyAddress, Bip32KeyPair> utxoKeyPairs = _loadUtxosAndTheirKeys();
    _witnessSet = _sign(body: body, keyPairSet: utxoKeyPairs.values.toSet());
    return ShelleyTransaction(
        body: body, witnessSet: _witnessSet, metadata: _metadata);
  }

  /// Check if inputs and outputs including fee, add up to zero or balance out.
  bool get isBalanced {
    final result = _buildBody()
        .transactionIsBalanced(cache: _blockchainAdapter!, fee: _fee);
    return result.isOk() && result.unwrap();
  }

  ShelleyAddress? _utxosFromTransaction(
      ShelleyTransactionInput input, Set<ShelleyAddress> ownSet) {
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

  Map<ShelleyAddress, Bip32KeyPair> _loadUtxosAndTheirKeys() {
    Set<ShelleyAddress> ownedAddresses = _wallet!.addresses.toSet();
    Map<ShelleyAddress, Bip32KeyPair> utxoKeyPairs = {};
    for (ShelleyTransactionInput input in _inputs) {
      ShelleyAddress? utxo = _utxosFromTransaction(input, ownedAddresses);
      if (utxo != null) {
        Bip32KeyPair? keyPair =
            _wallet!.findKeyPairForChangeAddress(address: utxo);
        if (keyPair != null) {
          utxoKeyPairs[utxo] = keyPair;
        }
      }
    }
    return utxoKeyPairs;
  }

  ShelleyTransactionWitnessSet signAndBuildWitnesses(
      Map<ShelleyAddress, Bip32KeyPair> utxoKeyPairs, List<int> signature) {
    List<ShelleyVkeyWitness> vkeyWitnesses = [];
    for (final keyPair in utxoKeyPairs.values) {
      final ShelleyVkeyWitness witness = ShelleyVkeyWitness(
          signature: signature, vkey: keyPair.verifyKey!.rawKey);
      vkeyWitnesses.add(witness);
    }
    return ShelleyTransactionWitnessSet(
        vkeyWitnesses: vkeyWitnesses, nativeScripts: []);
  }

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
  /// it will contain the cached Utx0s needed to calculate the input amounts.
  ///
  /// TODO handle edge case where selectd coins have to be changed based on fee adjustment.
  ///
  Future<Result<ShelleyTransaction, String>> buildAndSign(
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
    if (_inputs.isEmpty) return Err("inputs are empty");
    //convert value into spend output if not zero
    if (_value.coin > coinZero && _toAddress != null) {
      ShelleyTransactionOutput spendOutput = ShelleyTransactionOutput(
          address: _toAddress!.toBech32(), value: _value);
      _outputs.add(spendOutput);
    }
    var body = _buildBody();
    //adjust change to balance transaction
    final balanceResult = body.balancedOutputsWithChange(
        changeAddress: _changeAddress!, cache: _blockchainAdapter!, fee: _fee);
    if (balanceResult.isErr()) return Err(balanceResult.unwrapErr());
    _outputs = balanceResult.unwrap();
    //build the complete signed transaction so we can calculate a more accurate fee
    body = _buildBody();
    Map<ShelleyAddress, Bip32KeyPair> utxoKeyPairs = _loadUtxosAndTheirKeys();
    if (utxoKeyPairs.isEmpty) {
      return Err("no UTxOs found in transaction");
    }
    _witnessSet = _sign(
        body: body,
        keyPairSet: utxoKeyPairs.values.toSet(),
        fakeSignature: true);
    var tx = ShelleyTransaction(
        body: body, witnessSet: _witnessSet, metadata: _metadata);
    _fee = calculateMinFee(tx: tx, minFee: _minFee);
    //rebalance change to fit the new fee
    final balanceResult2 = body.balancedOutputsWithChange(
        changeAddress: _changeAddress!, cache: _blockchainAdapter!, fee: _fee);
    if (balanceResult2.isErr()) return Err(balanceResult2.unwrapErr());
    _outputs = balanceResult2.unwrap();
    body = _buildBody();
    //re-sign to capture changes
    _witnessSet = _sign(body: body, keyPairSet: utxoKeyPairs.values.toSet());
    tx = ShelleyTransaction(
        body: body, witnessSet: _witnessSet, metadata: _metadata);
    if (mustBalance) {
      final balancedResult =
          tx.body.transactionIsBalanced(cache: _blockchainAdapter!, fee: _fee);
      if (balancedResult.isErr()) return Err(balancedResult.unwrapErr());
    }
    return Ok(tx);
  }

  ShelleyTransactionWitnessSet _sign({
    required ShelleyTransactionBody body,
    required Set<Bip32KeyPair> keyPairSet,
    bool fakeSignature = false,
  }) {
    final bodyData = body.toCborMap().getData();
    List<int> hash = blake2bHash256(bodyData);
    List<ShelleyVkeyWitness> witnesses = [];
    for (Bip32KeyPair keyPair in keyPairSet) {
      final signedMessage =
          fakeSignature ? _fakeSign(hash) : keyPair.signingKey!.sign(hash);
      final witness = ShelleyVkeyWitness(
          vkey: keyPair.verifyKey!.rawKey, signature: signedMessage.signature);
      witnesses.add(witness);
    }
    return ShelleyTransactionWitnessSet(
        vkeyWitnesses: witnesses, nativeScripts: []);
  }

  /// Generate fake signature that just has to be correct length for size calculation.
  SignedMessage _fakeSign(List<int> message) {
    var sm = Uint8List(message.length + TweetNaCl.signatureLength);
    sm.fillRange(
        0, sm.length, 42); //file fake sig with meaning of life & everything.
    return SignedMessage.fromList(signedMessage: sm);
  }

  //List<int> get transactionBodyHash => blake2bHash256(_buildBody().toCborMap().getData());

  Result<bool, String> _checkContraints() {
    if (_blockchainAdapter == null) {
      return Err("'blockchainAdapter' property must be set");
    }
    if (_inputs.isEmpty) return Err("'inputs' property must be set");
    if (_outputs.isEmpty && (_value.coin == 0 || _toAddress == null)) {
      return Err(
          "when 'outputs' is empty, 'toAddress' and 'value' properties must be set");
    }
    if (_keyPair == null) {
      return Err("'kit' (ShelleyAddressKit) property must be set");
    }
    if (_changeAddress == null) {
      return Err("'changeAddress' property must be set");
    }
    return Ok(true);
  }

  /// Because transaction size effects fees, this method should be called last, after all other
  /// ShelleyTransactionBody properties are set.
  /// if minFee is set, then this determines the lower minimum fee bound.
  Coin calculateMinFee({required ShelleyTransaction tx, Coin minFee = 0}) {
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
    _keyPair = _wallet!.rootKeyPair;
  }

  void value(ShelleyValue value) => _value = value;

  void changeAddress(ShelleyAddress changeAddress) =>
      _changeAddress = changeAddress;

  void toAddress(ShelleyAddress toAddress) => _toAddress = toAddress;

  void currentSlot(int currentSlot) => _currentSlot = currentSlot;

  void minFeeFunction(MinFeeFunction feeFunction) =>
      _minFeeFunction = feeFunction;

  void linearFee(LinearFee linearFee) => _linearFee = linearFee;

  void metadataHash(List<int>? metadataHash) => _metadataHash = metadataHash;

  void validityStartInterval(int validityStartInterval) =>
      _validityStartInterval = validityStartInterval;

  void fee(Coin fee) => _fee = fee;

  void minFee(Coin minFee) => _minFee = minFee;

  void mint(ShelleyMultiAsset mint) => _mint.add(mint);

  void mints(List<ShelleyMultiAsset> mint) => _mint = mint;

  void ttl(int ttl) => _ttl = ttl;

  void inputs(List<ShelleyTransactionInput> inputs) => _inputs = inputs;

  void txInput(ShelleyTransactionInput input) => _inputs.add(input);

  void input({required String transactionId, required int index}) => txInput(
      ShelleyTransactionInput(transactionId: transactionId, index: index));

  void txOutput(ShelleyTransactionOutput output) => _outputs.add(output);

  void witnessSet(ShelleyTransactionWitnessSet witnessSet) =>
      _witnessSet = witnessSet;

  void metadata(CBORMetadata metadata) => _metadata = metadata;

  /// build a single ShelleyTransactionOutput, handle complex output construction
  void output({
    ShelleyAddress? shelleyAddress,
    String? address,
    MultiAssetBuilder? multiAssetBuilder,
    ShelleyValue? value,
    bool autoAddMinting = true,
  }) {
    assert(address != null || shelleyAddress != null);
    assert(!(address != null && shelleyAddress != null));
    final String addr =
        shelleyAddress != null ? shelleyAddress.toBech32() : address!;
    assert(multiAssetBuilder != null || value != null);
    assert(!(multiAssetBuilder != null && value != null));
    final val = value ?? multiAssetBuilder!.build();
    final output = ShelleyTransactionOutput(address: addr, value: val);
    _outputs.add(output);
    if (autoAddMinting) {
      _mint.addAll(val.multiAssets);
    }
  }

  // void coinSelectionFunction(CoinSelectionAlgorithm coinSelectionFunction) =>
  //     _coinSelectionFunction = coinSelectionFunction;

  // void unspentInputsAvailable(List<WalletTransaction> unspentInputsAvailable) =>
  //     _unspentInputsAvailable = unspentInputsAvailable;

  // void coinSelectionOutputsRequested(List<MultiAssetRequest> coinSelectionOutputsRequested) =>
  //     _coinSelectionOutputsRequested = coinSelectionOutputsRequested;

  // void coinSelectionOwnedAddresses(Set<ShelleyAddress> coinSelectionOwnedAddresses) =>
  //     _coinSelectionOwnedAddresses = coinSelectionOwnedAddresses;

  // void coinSelectionLimit(int coinSelectionLimit) => _coinSelectionLimit = coinSelectionLimit;

  // TransactionBuilder send({ShelleyAddress? shelleyAddress, String? address, Coin lovelace = 0, Coin ada = 0}) {
  //   assert(address != null || shelleyAddress != null);
  //   assert(!(address != null && shelleyAddress != null));
  //   final String addr = shelleyAddress != null ? shelleyAddress.toBech32() : address!;
  //   final amount = lovelace + ada * 1000000;
  //   return txOutput(ShelleyTransactionOutput(address: addr, value: ShelleyValue(coin: amount, multiAssets: [])));
  // }
}

typedef CurrentEpochFunction = Future<int> Function();

///
/// Special builder for creating ShelleyValue objects containing multi-asset transactions.
///
class MultiAssetBuilder {
  final int coin;
  final List<ShelleyMultiAsset> _multiAssets = [];
  MultiAssetBuilder({required this.coin});
  ShelleyValue build() => ShelleyValue(coin: coin, multiAssets: _multiAssets);
  MultiAssetBuilder nativeAsset(
      {required String policyId, String? hexName, required int value}) {
    final nativeAsset = ShelleyMultiAsset(policyId: policyId, assets: [
      ShelleyAsset(name: hexName ?? '', value: value),
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
    final nativeAsset = ShelleyMultiAsset(policyId: policyId, assets: [
      ShelleyAsset(name: hexName1 ?? '', value: value1),
      ShelleyAsset(name: hexName2 ?? '', value: value2),
    ]);
    _multiAssets.add(nativeAsset);
    return this;
  }

  MultiAssetBuilder asset(CurrencyAsset asset) {
    final nativeAsset = ShelleyMultiAsset(policyId: asset.policyId, assets: [
      ShelleyAsset(name: asset.assetName, value: int.parse(asset.quantity)),
    ]);
    _multiAssets.add(nativeAsset);
    return this;
  }
}
