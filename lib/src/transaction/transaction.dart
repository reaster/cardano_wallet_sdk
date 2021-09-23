// import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:cardano_wallet_sdk/src/asset/asset.dart';

enum TransactionType { deposit, withdrawal }
enum TransactionStatus { pending, confirmed }
enum TemperalSortOrder { ascending, descending }

/// Amounts in lovelace.
abstract class Transaction {
  String get txId;
  TransactionStatus get status;
  int get fees;
  DateTime get time;
  List<TransactionIO> get inputs;
  List<TransactionIO> get outputs;
}

///
/// Transaction from owning wallet perspective (i.e. deposit or withdrawal specific to owned addresses).
///
abstract class WalletTransaction extends Transaction {
  TransactionType get type;
  int get amount;
  Map<String, int> get currencies;
  int currencyAmount({required String assetId});
  bool containsCurrency({required String assetId});
  Set<String> get ownedAddresses;
}

class TransactionAmount {
  final String unit;
  final int quantity;
  TransactionAmount({required this.unit, required this.quantity});
  @override
  String toString() => "TransactionAmount(unit: $unit quantity: $quantity)";
}

class TransactionIO {
  final String address;
  final List<TransactionAmount> amounts;
  TransactionIO({required this.address, required this.amounts});
  @override
  String toString() =>
      "TransactionIO(address: $address count: ${amounts.length})";
}

class WalletTransactionImpl implements WalletTransaction {
  final Transaction baseTransaction;
  final Map<String, int> currencies;
  final Set<String> ownedAddresses;
  WalletTransactionImpl(
      {required this.baseTransaction, required Set<String> addressSet})
      : currencies = baseTransaction.sumCurrencies(addressSet: addressSet),
        ownedAddresses =
            baseTransaction.filterAddresses(addressSet: addressSet);

  @override
  String get txId => baseTransaction.txId;
  @override
  TransactionStatus get status => baseTransaction.status;
  @override
  int get fees => payedFees ? baseTransaction.fees : 0;
  @override
  DateTime get time => baseTransaction.time;
  @override
  List<TransactionIO> get inputs => baseTransaction.inputs;
  @override
  List<TransactionIO> get outputs => baseTransaction.outputs;

  String currencyBalancesByTicker(
          {required Map<String, CurrencyAsset> assetByAssetId,
          String? filterAssetId}) =>
      currencies.entries
          .where((e) =>
              filterAssetId == null ||
              e.key != filterAssetId ||
              assetByAssetId[e.key] != null)
          .map((e) => MapEntry(assetByAssetId[e.key]!, e.value))
          .map((e) => "${e.key.symbol}:${e.value}")
          .join(', ');

  @override
  int get amount => currencies[lovelaceHex] ?? 0;

  @override
  TransactionType get type =>
      amount >= 0 ? TransactionType.deposit : TransactionType.withdrawal;

  @override
  String toString() =>
      "Transaction(amount: $amount fees: $fees status: $status type: $type coins: ${currencies.length} id: $txId)";

  @override
  bool containsCurrency({required String assetId}) =>
      currencies[assetId] != null;

  @override
  int currencyAmount({required String assetId}) => currencies[assetId] ?? 0;

  bool get payedFees => type == TransactionType.withdrawal;
}

class TransactionImpl implements Transaction {
  final String txId;
  final TransactionStatus status;
  final int fees;
  final List<TransactionIO> inputs;
  final List<TransactionIO> outputs;
  final DateTime time;
  Set<String>? _assetPolicyIds;
  Map<String, int> _cachedSums = {};
  TransactionImpl({
    required this.txId,
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
extension TransactionScanner on Transaction {
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
  Map<String, int> sumCurrencies({required Set<String> addressSet}) {
    //if (_cachedSums.isEmpty) {
    Map<String, int> result = {lovelaceHex: 0};
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
          final int beginning = result[amount.unit] ?? 0;
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

  Block({required this.time, this.height, required this.hash});
  @override
  String toString() => "Block(#$height $time hash: $hash)";
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
