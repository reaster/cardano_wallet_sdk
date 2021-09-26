import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:cardano_wallet_sdk/src/address/shelley_address.dart';
import 'package:cardano_wallet_sdk/src/asset/asset.dart';
import 'package:cardano_wallet_sdk/src/transaction/spec/shelley_spec.dart';
import 'package:cardano_wallet_sdk/src/util/blake2bhash.dart';

///
/// Manages details of building a correct transaction, such as fee calculation, change
/// callculation, time-to-live constraints (ttl) and signing.
///
class TransactionBuilder {
  List<ShelleyTransactionInput> _inputs = [];
  List<ShelleyTransactionOutput> _outputs = [];
  int _fee = 0;
  int _ttl = 0;
  List<int>? _metadataHash;
  int? _validityStartInterval;
  List<ShelleyMultiAsset> _mint = [];
  ShelleyTransactionWitnessSet? _witnessSet;
  CBORMetadata? _metadata;

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

  ShelleyTransaction build() {
    final body = buildBody();
    final ShelleyTransaction tx = ShelleyTransaction(body: body, witnessSet: _witnessSet, metadata: _metadata);
    final txHex = tx.toCborHex;
    print(txHex);
    return tx;
  }

  TransactionBuilder metadataHash(List<int>? metadataHash) {
    _metadataHash = metadataHash;
    return this;
  }

  TransactionBuilder validityStartInterval(int validityStartInterval) {
    _validityStartInterval = validityStartInterval;
    return this;
  }

  TransactionBuilder fee(int fee) {
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

  TransactionBuilder send({ShelleyAddress? shelleyAddress, String? address, int lovelace = 0, int ada = 0}) {
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

// pub fn min_fee(tx: &Transaction, linear_fee: &LinearFee) -> Result<Coin, JsError> {
//     to_bignum(tx.to_bytes().len() as u64)
//         .checked_mul(&linear_fee.coefficient())?
//         .checked_add(&linear_fee.constant())
// }
// Specifies an amount of ADA in terms of lovelace
// pub type Coin = BigNum;
// #[derive(Clone, Debug, Eq, Ord, PartialEq, PartialOrd)]
// pub struct LinearFee {
//     constant: Coin,
//     coefficient: Coin,

  ///
  /// calculate transaction fee based on transaction lnegth and minimum constant
  ///
  int minFee({required ShelleyTransaction transaction, LinearFee linearFee = defaultLinearFee}) {
    final len = transaction.toCborList().getData().length;
    return len * linearFee.coefficient + linearFee.constant;
  }
}

///
/// Used in calculating Cardano transaction fees.
///
class LinearFee {
  final int constant;
  final int coefficient;

  const LinearFee({required this.constant, required this.coefficient});
}

/// fee calculation factors
/// TODO update this from blockchain
/// TODO verify fee calculation context of this values
const defaultLinearFee = LinearFee(constant: 2, coefficient: 500);

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
