import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:cardano_wallet_sdk/src/address/shelley_address.dart';
import 'package:cardano_wallet_sdk/src/asset/asset.dart';
import 'package:cardano_wallet_sdk/src/transaction/min_fee_function.dart';
import 'package:cardano_wallet_sdk/src/transaction/spec/shelley_spec.dart';
import 'package:cardano_wallet_sdk/src/util/blake2bhash.dart';
import 'package:cardano_wallet_sdk/src/util/ada_types.dart';
import 'package:cardano_wallet_sdk/src/blockchain/blockchain_adapter.dart';
import 'package:oxidized/oxidized.dart';

///
/// Manages details of building a correct transaction, including fee calculation, change
/// callculation, time-to-live constraints (ttl) and signing.
///
class TransactionBuilder {
  BlockchainAdapter? _blockchainAdapter;
  List<ShelleyTransactionInput> _inputs = [];
  List<ShelleyTransactionOutput> _outputs = [];
  Coin _fee = 0;
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
  final staleSlotCuttoff = Duration(seconds: 60);

  List<int> transactionBodyHash() => blake2bHash256(buildBody().toCborMap().getData());

  ShelleyTransactionBody buildBody() => ShelleyTransactionBody(
        inputs: _inputs,
        outputs: _outputs,
        fee: _fee,
        ttl: _ttl,
        metadataHash: _metadataHash,
        validityStartInterval: _validityStartInterval,
        mint: _mint.isEmpty ? null : _mint,
      );

  Future<Result<ShelleyTransaction, String>> build() async {
    final dataCheck = _checkContraints();
    if (dataCheck.isErr()) return Err(dataCheck.unwrapErr());
    _optionallySetupChangeOutput();
    if (_ttl == 0) {
      final result = await _calculateTimeToLive();
      if (result.isErr()) {
        return Err(result.unwrapErr());
      }
      _ttl = result.unwrap();
    }
    var body = buildBody();
    var tx = ShelleyTransaction(body: body, witnessSet: _witnessSet, metadata: _metadata);
    _fee = _calculateMinFee(tx);
    body = buildBody();
    tx = ShelleyTransaction(body: body, witnessSet: _witnessSet, metadata: _metadata);
    final txHex = tx.toCborHex;
    print(txHex);
    return Ok(tx);
  }

  void _optionallySetupChangeOutput() {
    //TODO
  }

  Result<bool, String> _checkContraints() {
    if (_blockchainAdapter == null) return Err("'blockchainAdapter' property must be set");
    return Ok(true);
  }

  /// Because transaction size effects fees, this method should be called last, after all other
  /// ShelleyTransactionBody properties are set.
  Coin _calculateMinFee(ShelleyTransaction tx) {
    Coin calculatedFee = _minFeeFunction(transaction: tx, linearFee: _linearFee);
    final fee = (calculatedFee < _fee) ? _fee : calculatedFee;
    return fee;
  }

  bool get currentSlotUnsetOrStale {
    if (currentSlot == 0) return true; //not set
    final now = DateTime.now().toUtc();
    return _currentSlotTimestamp.add(staleSlotCuttoff).isBefore(now); //cuttoff reached?
  }

  /// Set the time range in which this transaction is valid.
  /// Time-to-live (TTL) - represents a slot, or deadline by which a transaction must be submitted.
  /// The TTL is an absolute slot number, rather than a relative one, which means that the ttl value
  /// should be greater than the current slot number. A transaction becomes invalid once its ttl expires.
  /// Currently each slot is one second and each epoch currently includes 432,000 slots (5 days).
  Future<Result<int, String>> _calculateTimeToLive() async {
    if (currentSlotUnsetOrStale) {
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
        return Err("specified ttl of $_ttl can't be less than current slot: $_currentSlot");
      }
      return Ok(_ttl);
    }

    return Ok(_currentSlot + defaultTtlDelta);
  }

  TransactionBuilder blockchainAdapter(BlockchainAdapter blockchainAdapter) {
    _blockchainAdapter = blockchainAdapter;
    return this;
  }

  TransactionBuilder currentSlot(int currentSlot) {
    _currentSlot = currentSlot;
    return this;
  }

  TransactionBuilder minFeeFunction(MinFeeFunction feeFunction) {
    _minFeeFunction = feeFunction;
    return this;
  }

  TransactionBuilder linearFee(LinearFee linearFee) {
    _linearFee = linearFee;
    return this;
  }

  TransactionBuilder metadataHash(List<int>? metadataHash) {
    _metadataHash = metadataHash;
    return this;
  }

  TransactionBuilder validityStartInterval(int validityStartInterval) {
    _validityStartInterval = validityStartInterval;
    return this;
  }

  TransactionBuilder fee(Coin fee) {
    _fee = fee;
    return this;
  }

  TransactionBuilder mint(ShelleyMultiAsset mint) {
    _mint.add(mint);
    return this;
  }

  TransactionBuilder mints(List<ShelleyMultiAsset> mint) {
    _mint = mint;
    return this;
  }

  TransactionBuilder ttl(int ttl) {
    _ttl = ttl;
    return this;
  }

  TransactionBuilder txInput(ShelleyTransactionInput input) {
    _inputs.add(input);
    return this;
  }

  TransactionBuilder input({required String transactionId, required int index}) {
    return txInput(ShelleyTransactionInput(transactionId: transactionId, index: index));
  }

  TransactionBuilder txOutput(ShelleyTransactionOutput output) {
    _outputs.add(output);
    return this;
  }

  TransactionBuilder output({
    ShelleyAddress? shelleyAddress,
    String? address,
    MultiAssetBuilder? multiAssetBuilder,
    ShelleyValue? value,
    bool autoAddMinting = true,
  }) {
    assert(address != null || shelleyAddress != null);
    assert(!(address != null && shelleyAddress != null));
    final String addr = shelleyAddress != null ? shelleyAddress.toBech32() : address!;
    assert(multiAssetBuilder != null || value != null);
    assert(!(multiAssetBuilder != null && value != null));
    final val = value ?? multiAssetBuilder!.build();
    final output = ShelleyTransactionOutput(address: addr, value: val);
    _outputs.add(output);
    if (autoAddMinting) {
      _mint.addAll(val.multiAssets);
    }
    return this;
  }

  TransactionBuilder send({ShelleyAddress? shelleyAddress, String? address, Coin lovelace = 0, Coin ada = 0}) {
    assert(address != null || shelleyAddress != null);
    assert(!(address != null && shelleyAddress != null));
    final String addr = shelleyAddress != null ? shelleyAddress.toBech32() : address!;
    final amount = lovelace + ada * 1000000;
    return txOutput(ShelleyTransactionOutput(address: addr, value: ShelleyValue(coin: amount, multiAssets: [])));
  }

  TransactionBuilder witnessSet(ShelleyTransactionWitnessSet witnessSet) {
    _witnessSet = witnessSet;
    return this;
  }

  TransactionBuilder metadata(CBORMetadata metadata) {
    _metadata = metadata;
    return this;
  }
}

typedef CurrentEpochFunction = Future<int> Function();

///
/// Special builder for creating ShelleyValue objects containing multi-asset transactions.
///
class MultiAssetBuilder {
  final int coin;
  List<ShelleyMultiAsset> _multiAssets = [];
  MultiAssetBuilder({required this.coin});
  ShelleyValue build() => ShelleyValue(coin: coin, multiAssets: _multiAssets);
  MultiAssetBuilder nativeAsset({required String policyId, String? hexName, required int value}) {
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
