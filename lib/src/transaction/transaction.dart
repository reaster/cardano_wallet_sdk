// import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:cardano_wallet_sdk/src/asset/asset.dart';
import 'package:cardano_wallet_sdk/src/util/ada_types.dart';

enum TransactionType { deposit, withdrawal }
enum TransactionStatus { pending, confirmed }
enum TemperalSortOrder { ascending, descending }

/// Amounts in lovelace.
abstract class RawTransaction {
  String get txId;
  String get blockHash;

  /// index within block
  int get blockIndex;
  TransactionStatus get status;
  Coin get fees;
  DateTime get time;
  List<TransactionIO> get inputs;
  List<TransactionIO> get outputs;
}

///
/// Transaction from owning wallet perspective (i.e. deposit or withdrawal specific to owned addresses).
///
abstract class WalletTransaction extends RawTransaction {
  TransactionType get type;
  Coin get amount;
  Map<String, Coin> get currencies;
  Coin currencyAmount({required String assetId});
  bool containsCurrency({required String assetId});
  Set<String> get ownedAddresses;
}

class TransactionAmount {
  final String unit;
  final Coin quantity;
  TransactionAmount({required this.unit, required this.quantity});
  @override
  String toString() => "TransactionAmount(unit: $unit quantity: $quantity)";
}

class TransactionIO {
  final String address;
  final List<TransactionAmount> amounts;
  TransactionIO({required this.address, required this.amounts});
  @override
  String toString() => "TransactionIO(address: $address count: ${amounts.length})";
}

class WalletTransactionImpl implements WalletTransaction {
  final RawTransaction rawTransaction;
  final Map<String, Coin> currencies;
  final Set<String> ownedAddresses;
  WalletTransactionImpl({required this.rawTransaction, required Set<String> addressSet})
      : currencies = rawTransaction.sumCurrencies(addressSet: addressSet),
        ownedAddresses = rawTransaction.filterAddresses(addressSet: addressSet);

  @override
  String get txId => rawTransaction.txId;
  @override
  String get blockHash => rawTransaction.blockHash;
  @override
  int get blockIndex => rawTransaction.blockIndex;
  @override
  TransactionStatus get status => rawTransaction.status;
  @override
  Coin get fees => payedFees ? rawTransaction.fees : 0;
  @override
  DateTime get time => rawTransaction.time;
  @override
  List<TransactionIO> get inputs => rawTransaction.inputs;
  @override
  List<TransactionIO> get outputs => rawTransaction.outputs;

  String currencyBalancesByTicker({required Map<String, CurrencyAsset> assetByAssetId, String? filterAssetId}) =>
      currencies.entries
          .where((e) => filterAssetId == null || e.key != filterAssetId || assetByAssetId[e.key] != null)
          .map((e) => MapEntry(assetByAssetId[e.key]!, e.value))
          .map((e) => "${e.key.symbol}:${e.value}")
          .join(', ');

  @override
  Coin get amount => currencies[lovelaceHex] ?? 0;

  @override
  TransactionType get type => amount >= 0 ? TransactionType.deposit : TransactionType.withdrawal;

  @override
  String toString() =>
      "Transaction(amount: $amount fees: $fees status: $status type: $type coins: ${currencies.length} id: $txId)";

  @override
  bool containsCurrency({required String assetId}) => currencies[assetId] != null;

  @override
  Coin currencyAmount({required String assetId}) => currencies[assetId] ?? 0;

  bool get payedFees => type == TransactionType.withdrawal;
}

class TransactionImpl implements RawTransaction {
  final String txId;
  final String blockHash;
  final int blockIndex;
  final TransactionStatus status;
  final Coin fees;
  final List<TransactionIO> inputs;
  final List<TransactionIO> outputs;
  final DateTime time;
  Set<String>? _assetPolicyIds;
  Map<String, Coin> _cachedSums = {};
  TransactionImpl({
    required this.txId,
    required this.blockHash,
    required this.blockIndex,
    required this.status,
    required this.fees,
    required this.inputs,
    required this.outputs,
    required this.time,
  });

  @override
  String toString() => "Transaction(fees: $fees status: $status id: $txId)";
}

///
/// Transaction extension -  wallet attribute collection methods
///
extension TransactionScanner on RawTransaction {
  /// assetIds found in transactioins. TODO confirm unit == assetId
  Set<String> get assetIds {
    Set<String> result = {lovelaceHex};
    inputs.forEach((tranIO) => tranIO.amounts.forEach((amount) {
          if (amount.unit.isNotEmpty) result.add(amount.unit);
        }));
    outputs.forEach((tranIO) => tranIO.amounts.forEach((amount) {
          if (amount.unit.isNotEmpty) result.add(amount.unit);
        }));
    return result;
  }

  ///
  ///return a map of all currencies with their net quantity change for a given set of
  ///addresses (i.e. a specific wallet).
  ///
  Map<String, Coin> sumCurrencies({required Set<String> addressSet}) {
    //if (_cachedSums.isEmpty) {
    Map<String, Coin> result = {lovelaceHex: 0};
    for (var tranIO in inputs) {
      final bool myMoney = addressSet.contains(tranIO.address);
      if (myMoney) {
        for (var amount in tranIO.amounts) {
          final int beginning = result[amount.unit] ?? 0;
          result[amount.unit] = beginning - amount.quantity;
          print(
              "${time} tx: ${txId.substring(0, 5)}.. innput: ${tranIO.address.substring(0, 15)}.. $beginning - ${amount.quantity} = ${result[amount.unit]}");
        }
      }
    }
    for (var tranIO in outputs) {
      final bool myMoney = addressSet.contains(tranIO.address);
      if (myMoney) {
        for (var amount in tranIO.amounts) {
          final Coin beginning = result[amount.unit] ?? 0;
          result[amount.unit] = beginning + amount.quantity;
          print(
              "${time} tx: ${txId.substring(0, 5)}.. output: ${tranIO.address.substring(0, 15)}.. $beginning + ${amount.quantity} = ${result[amount.unit]}");
        }
      }
    }
    return result;
  }

  ///
  ///filter addresses to those found in this transaction
  ///
  Set<String> filterAddresses({required Set<String> addressSet}) {
    Set<String> result = {};
    for (var tranIO in inputs) {
      if (addressSet.contains(tranIO.address)) {
        result.add(tranIO.address);
      }
    }
    for (var tranIO in outputs) {
      if (addressSet.contains(tranIO.address)) {
        result.add(tranIO.address);
      }
    }
    return result;
  }
}

/// Block record
class Block {
  /// Block creation time in UTC
  final DateTime time;

  /// Block number
  final int? height;

  /// Hash of the block
  final String hash;

  /// absolute slot number
  final int slot;
  final int epoch;
  //slot with in epoch
  final int epochSlot;

  Block(
      {required this.time,
      this.height,
      required this.hash,
      required this.slot,
      required this.epoch,
      required this.epochSlot});
  @override
  String toString() => "Block(#$height $time slot:$slot hash: $hash)";
}

//     /// Fees of the transaction in Lovelaces
//     @BuiltValueField(wireName: r'fees')
//     String get fees;

//     /// Deposit within the transaction in Lovelaces
//     @BuiltValueField(wireName: r'deposit')
//     String get deposit;

//     /// Size of the transaction in Bytes
//     @BuiltValueField(wireName: r'size')
//     int get size;

//     /// Left (included) endpoint of the timelock validity intervals
//     @BuiltValueField(wireName: r'invalid_before')
//     String? get invalidBefore;

//     /// Right (excluded) endpoint of the timelock validity intervals
//     @BuiltValueField(wireName: r'invalid_hereafter')
//     String? get invalidHereafter;

//     /// Count of UTXOs within the transaction
//     @BuiltValueField(wireName: r'utxo_count')
//     int get utxoCount;

//     /// Count of the withdrawal within the transaction
//     @BuiltValueField(wireName: r'withdrawal_count')
//     int get withdrawalCount;

// }

//    @BuiltValueField(wireName: r'block')
//     String get block;

//     /// Transaction index within the block
//     @BuiltValueField(wireName: r'index')
//     int get index;

//     @BuiltValueField(wireName: r'output_amount')
//     BuiltList<TxContentOutputAmount> get outputAmount;

//     /// Fees of the transaction in Lovelaces
//     @BuiltValueField(wireName: r'fees')
//     String get fees;

//     /// Deposit within the transaction in Lovelaces
//     @BuiltValueField(wireName: r'deposit')
//     String get deposit;

//     /// Size of the transaction in Bytes
//     @BuiltValueField(wireName: r'size')
//     int get size;

//     /// Left (included) endpoint of the timelock validity intervals
//     @BuiltValueField(wireName: r'invalid_before')
//     String? get invalidBefore;

//     /// Right (excluded) endpoint of the timelock validity intervals
//     @BuiltValueField(wireName: r'invalid_hereafter')
//     String? get invalidHereafter;

//     /// Count of UTXOs within the transaction
//     @BuiltValueField(wireName: r'utxo_count')
//     int get utxoCount;

//     /// Count of the withdrawal within the transaction
//     @BuiltValueField(wireName: r'withdrawal_count')
//     int get withdrawalCount;

//     /// Count of the delegations within the transaction
//     @BuiltValueField(wireName: r'delegation_count')
//     int get delegationCount;

//     /// Count of the stake keys (de)registrations and delegations within the transaction
//     @BuiltValueField(wireName: r'stake_cert_count')
//     int get stakeCertCount;

//     /// Count of the stake pool registrations and updates within the transaction
//     @BuiltValueField(wireName: r'pool_update_count')
//     int get poolUpdateCount;

//     /// Count of the stake pool retirements within the transaction
//     @BuiltValueField(wireName: r'pool_retire_count')
//     int get poolRetireCount;
