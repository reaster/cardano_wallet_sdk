// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:logger/logger.dart';
import '../address/shelley_address.dart';
import '../util/ada_types.dart';
import '../asset/asset.dart';

enum TransactionType { deposit, withdrawal }
enum TransactionStatus { pending, unspent, spent }
enum TemperalSortOrder { ascending, descending }

///
/// Raw transactions mirror the data on the blockchain.
/// Amounts in lovelace.
///
abstract class RawTransaction {
  String get txId;
  String get blockHash;

  /// index within block
  int get blockIndex;
  TransactionStatus get status;
  Coin get fees;
  DateTime get time;
  List<TransactionInput> get inputs;
  List<TransactionOutput> get outputs;
}

///
/// Transaction from owning wallet perspective (i.e. filters raw transaction deposits
/// and withdrawals specific to owned addresses).
///
abstract class WalletTransaction extends RawTransaction {
  TransactionType get type;
  Coin get amount;
  Map<String, Coin> get currencies;
  Coin currencyAmount({required String assetId});
  bool containsCurrency({required String assetId});
  Set<ShelleyAddress> get ownedAddresses;
}

///
/// Amount and type for a specific native token.
///
class TransactionAmount {
  final String unit;
  final Coin quantity;
  TransactionAmount({required this.unit, required this.quantity});
  @override
  String toString() => "TransactionAmount(unit: $unit quantity: $quantity)";
}

///
/// Inputs or outputs for a given transaction.
///
class TransactionInput {
  final ShelleyAddress address;
  final List<TransactionAmount> amounts;
  final String txHash;
  final int outputIndex;
  TransactionInput(
      {required this.address,
      required this.amounts,
      required this.txHash,
      required this.outputIndex});
  @override
  String toString() =>
      "TransactionInput(address: $address count: ${amounts.length})";
}

class TransactionOutput {
  final ShelleyAddress address;
  final List<TransactionAmount> amounts;
  final bool isChange;
  TransactionOutput(
      {required this.address, required this.amounts, this.isChange = false});
  @override
  String toString() =>
      "TransactionOutput(address: $address, isChange: $isChange, count: ${amounts.length})";
}

class WalletTransactionImpl implements WalletTransaction {
  final RawTransaction rawTransaction;
  @override
  final Map<String, Coin> currencies;
  @override
  final Set<ShelleyAddress> ownedAddresses;
  WalletTransactionImpl(
      {required this.rawTransaction, required Set<ShelleyAddress> addressSet})
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
  Coin get fees => payedFees ? rawTransaction.fees : coinZero;
  @override
  DateTime get time => rawTransaction.time;
  @override
  List<TransactionInput> get inputs => rawTransaction.inputs;
  @override
  List<TransactionOutput> get outputs => rawTransaction.outputs;

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
  Coin get amount => currencies[lovelaceHex] ?? coinZero;

  @override
  TransactionType get type =>
      amount >= coinZero ? TransactionType.deposit : TransactionType.withdrawal;

  @override
  String toString() =>
      "WalletTransaction(amount: $amount fees: $fees status: $status type: $type coins: ${currencies.length} id: $txId)";

  @override
  bool containsCurrency({required String assetId}) =>
      currencies[assetId] != null;

  @override
  Coin currencyAmount({required String assetId}) =>
      currencies[assetId] ?? coinZero;

  bool get payedFees => type == TransactionType.withdrawal;
}

class RawTransactionImpl implements RawTransaction {
  @override
  final String txId;
  @override
  final String blockHash;
  @override
  final int blockIndex;
  @override
  final TransactionStatus status;
  @override
  final Coin fees;
  @override
  final List<TransactionInput> inputs;
  @override
  final List<TransactionOutput> outputs;
  @override
  final DateTime time;
  // Set<String>? _assetPolicyIds;
  // Map<String, Coin> _cachedSums = {};
  RawTransactionImpl({
    required this.txId,
    required this.blockHash,
    required this.blockIndex,
    required this.status,
    required this.fees,
    required this.inputs,
    required this.outputs,
    required this.time,
  });

  /// set status property, returning a new immutable RawTransactionImpl copy
  RawTransactionImpl toStatus(TransactionStatus status) => this.status == status
      ? this
      : RawTransactionImpl(
          txId: txId,
          blockHash: blockHash,
          blockIndex: blockIndex,
          status: status,
          fees: fees,
          inputs: List.from(inputs),
          outputs: List.from(outputs),
          time: time,
        );

  @override
  String toString() => "RawTransaction(fees: $fees status: $status id: $txId)";
}

///
/// Transaction extension -  wallet attribute collection methods
///
extension TransactionScanner on RawTransaction {
  /// assetIds found in transactioins. TODO confirm unit == assetId
  Set<String> get assetIds {
    Set<String> result = {lovelaceHex};
    for (var input in inputs) {
      for (var amount in input.amounts) {
        if (amount.unit.isNotEmpty) result.add(amount.unit);
      }
    }
    for (var output in outputs) {
      for (var amount in output.amounts) {
        if (amount.unit.isNotEmpty) result.add(amount.unit);
      }
    }
    return result;
  }

  static final _logger = Logger();

  ///
  /// return a map of all currencies with their net quantity change for a given set of
  /// addresses (i.e. a specific wallet).
  /// An AssetId is the hex representation of a policyId concatenated to the coin name
  /// in hex (i.e. unit).
  ///
  Map<AssetId, Coin> sumCurrencies({required Set<ShelleyAddress> addressSet}) {
    //if (_cachedSums.isEmpty) {
    Map<String, Coin> result = {lovelaceHex: coinZero};
    for (var input in inputs) {
      final bool myMoney = addressSet.contains(input.address);
      if (myMoney) {
        for (var amount in input.amounts) {
          final Coin beginning = result[amount.unit] ?? coinZero;
          result[amount.unit] = beginning - amount.quantity;
          _logger.i(
              "$time tx: ${txId.substring(0, 5)}.. innput: ${input.address.toString().substring(0, 15)}.. $beginning - ${amount.quantity} = ${result[amount.unit]}");
        }
      }
    }
    for (var output in outputs) {
      final bool myMoney = addressSet.contains(output.address);
      if (myMoney) {
        for (var amount in output.amounts) {
          final Coin beginning = result[amount.unit] ?? coinZero;
          result[amount.unit] = beginning + amount.quantity;
          _logger.i(
              "$time tx: ${txId.substring(0, 5)}.. output: ${output.address.toString().substring(0, 15)}.. $beginning + ${amount.quantity} = ${result[amount.unit]}");
        }
      }
    }
    return result;
  }

  ///
  /// filter addresses to those found in this wallet
  ///
  Set<ShelleyAddress> filterAddresses(
      {required Set<ShelleyAddress> addressSet}) {
    Set<ShelleyAddress> result = {};
    for (var input in inputs) {
      if (addressSet.contains(input.address)) {
        result.add(input.address);
      }
    }
    for (var output in outputs) {
      if (addressSet.contains(output.address)) {
        result.add(output.address);
      }
    }
    _logger.i(
        "filterAddresses(input addresses: ${addressSet.length} -> filtered addresses: ${result.length})");
    return result;
  }
}

// class UtxoOutputAmount {
//   /// The unit of the value
//   final String unit;

//   /// The quantity of the unit
//   final Coin quantity;
//   UtxoOutputAmount({required this.unit, required this.quantity});
// }

// class UtxoInput {
//   /// Input address
//   final ShelleyAddress address;
//   final List<UtxoOutputAmount> amount;
//   UtxoInput({required this.address, required this.amount});
// }

// class UtxoOutput {
//   /// Output address
//   final ShelleyAddress address;
//   final List<UtxoOutputAmount> amount;
//   UtxoOutput({required this.address, required this.amount});
// }

// /// Unspent transaction output
// class Utxo {
//   final List<UtxoInput> inputs;
//   final List<UtxoOutput> outputs;
//   Utxo(this.inputs, this.outputs);
// }

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
