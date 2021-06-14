enum TransactionType { deposit, withdrawal }
enum TransactionStatus { pending, confirmed }

/// Amounts in lovelace.
abstract class Transaction {
  String get txId;
  TransactionStatus get status;
  int get fees;
  DateTime get time;
  List<TransactionIO> get inputs;
  List<TransactionIO> get outputs;
  Set<String> get assetPolicyIds;
  Map<String, int> sumCurrencies({required Set<String> addressSet});
}

/// Transaction from owning wallet perspective (i.e. deposit or withdrawal).
abstract class WalletTransaction extends Transaction {
  TransactionType get type;
  int get amount;
  Map<String, int> get currencies;
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
  String toString() => "TransactionIO(address: $address count: ${amounts.length})";
}

class WalletTransactionImpl implements WalletTransaction {
  final Transaction baseTransaction;
  final Map<String, int> currencies;
  WalletTransactionImpl({required this.baseTransaction, required Set<String> addressSet})
      : currencies = baseTransaction.sumCurrencies(addressSet: addressSet);

  @override
  String get txId => baseTransaction.txId;
  @override
  TransactionStatus get status => baseTransaction.status;
  @override
  int get fees => baseTransaction.fees;
  @override
  DateTime get time => baseTransaction.time;
  @override
  List<TransactionIO> get inputs => baseTransaction.inputs;
  @override
  List<TransactionIO> get outputs => baseTransaction.outputs;
  @override
  Map<String, int> sumCurrencies({required Set<String> addressSet}) => baseTransaction.sumCurrencies(addressSet: addressSet);

  @override
  int get amount => currencies['lovelace'] ?? 0;

  @override
  TransactionType get type => amount >= 0 ? TransactionType.deposit : TransactionType.withdrawal;

  @override
  Set<String> get assetPolicyIds => baseTransaction.assetPolicyIds;

  @override
  String toString() => "Transaction(amount: $amount fees: $fees status: $status type: $type coins: ${currencies.length} id: $txId)";
}

class TransactionImpl implements Transaction {
  final String txId;
  final TransactionStatus status;
  final int fees;
  final List<TransactionIO> inputs;
  final List<TransactionIO> outputs;
  final DateTime time;
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

  @override
  Set<String> get assetPolicyIds {
    Set<String> result = {'lovelace'};
    inputs.forEach((tranIO) => tranIO.amounts.forEach((amount) {
          if (amount.unit.isNotEmpty) result.add(amount.unit);
        }));
    outputs.forEach((tranIO) => tranIO.amounts.forEach((amount) {
          if (amount.unit.isNotEmpty) result.add(amount.unit);
        }));
    return result;
  }

  //return a map of all currencies with their net quantity change for a given set of
  //addresses (i.e. a specific wallet).
  @override
  Map<String, int> sumCurrencies({required Set<String> addressSet}) {
    Map<String, int> result = {'lovelace': 0};
    for (var tranIO in inputs) {
      if (addressSet.contains(tranIO.address)) {
        for (var amount in tranIO.amounts) {
          result[amount.unit] = (result[amount.unit] ?? 0) - amount.quantity;
        }
      }
    }
    for (var tranIO in outputs) {
      if (addressSet.contains(tranIO.address)) {
        for (var amount in tranIO.amounts) {
          result[amount.unit] = (result[amount.unit] ?? 0) + amount.quantity;
        }
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
