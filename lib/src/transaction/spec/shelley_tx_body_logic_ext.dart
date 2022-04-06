// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:logger/logger.dart';
import 'package:oxidized/oxidized.dart';
import 'package:collection/collection.dart';
import '../../address/shelley_address.dart';
import '../../asset/asset.dart';
import '../../blockchain/blockchain_cache.dart';
import '../../util/ada_types.dart';
import '../transaction.dart';
import './shelley_spec.dart';

///
/// Handle balance checks and generating/modifying the correct change output so
/// that the sum of inputs and output is zero (i.e. is balanced).
///
extension ShelleyTransactionBodyLogic on ShelleyTransactionBody {
  ///
  /// Sum currency amounts accross transaction. The sums should all be zero if the
  /// transaction is balanced.
  /// All transactions referenced by the inputs must be in the cache.
  ///
  Result<Map<AssetId, Coin>, String> sumCurrencyIO({
    required BlockchainCache cache,
    Coin fee = 0,
    Logger? logger,
  }) {
    logger ??= Logger();
    Map<AssetId, Coin> sums = {};
    for (final input in inputs) {
      RawTransaction? tx = cache.cachedTransaction(input.transactionId);
      if (tx == null) {
        return Err("transaction '${input.transactionId}' not in cache");
      }
      if (tx.outputs.length <= input.index) {
        return Err(
            "transaction '${input.transactionId}' index[${input.index}] out of range[0..${tx.outputs.length - 1}]");
      }
      final output = tx.outputs[input.index];
      for (final amount in output.amounts) {
        sums[amount.unit] = amount.quantity + (sums[amount.unit] ?? coinZero);
      }
    }
    for (final ShelleyTransactionOutput output in outputs) {
      sums[lovelaceHex] = (sums[lovelaceHex] ?? coinZero) - output.value.coin;
      for (final assets in output.value.multiAssets) {
        final policyId = assets.policyId;
        for (final asset in assets.assets) {
          final assetId = policyId + asset.name;
          sums[assetId] = (sums[assetId] ?? coinZero) - asset.value;
        }
      }
    }
    logger.i(" ====> sumCurrencyIO - should all be zero if balanced:");
    for (final assetId in sums.keys) {
      if (assetId == lovelaceHex) {
        logger.i(
            "   ==> lovelace: ${sums[assetId]} - fee($fee) = ${(sums[lovelaceHex] ?? coinZero) - fee}");
      } else {
        logger.i("   ==> $assetId: ${sums[assetId]}");
      }
    }
    sums[lovelaceHex] = (sums[lovelaceHex] ?? coinZero) - fee;
    return Ok(sums);
  }

  ///
  /// just return true or false if the transaction is balanced.
  ///
  Result<bool, String> transactionIsBalanced({
    required BlockchainCache cache,
    Coin fee = 0,
  }) {
    final result = sumCurrencyIO(cache: cache, fee: fee);
    if (result.isErr()) return Err(result.unwrapErr());
    final sums = result.unwrap();
    final isAllZeros = sums.values.every((sum) => sum == coinZero);
    return Ok(isAllZeros);
  }

  ///
  /// Balance transaction by adding/modifying change outputs to match inputs and fee.
  /// If no change adjustments are needed, returns input list.
  /// All native tokens must have a CurrencyAsset in the cache.
  /// To avoid adding multiple change outputs, changeAddress should be the same for a given tx.
  ///
  Result<List<ShelleyTransactionOutput>, String> balancedOutputsWithChange({
    required ShelleyAddress changeAddress,
    required BlockchainCache cache,
    Coin fee = 0,
  }) {
    //get the differences for each native token:
    final sumResult = sumCurrencyIO(cache: cache, fee: fee);
    if (sumResult.isErr()) return Err(sumResult.unwrapErr());
    final Map<AssetId, Coin> sums = sumResult.unwrap();
    final isAllZeros = sums.values.every((sum) => sum == coinZero);
    //if balanced - nothing to do - return existing list
    if (isAllZeros) return Ok(this.outputs);
    final targetAddress = changeAddress.toBech32();
    //copy all outputs except for the change output
    List<ShelleyTransactionOutput> outputs =
        this.outputs.where((o) => o.address != targetAddress).toList();
    //find change output if it exists
    ShelleyTransactionOutput? changeOutput =
        firstWhere(this.outputs, targetAddress);
    //break-up assetIds into policyId and name and put in nested maps
    final groupByResult = _groupByPolicyIdThenName(sums: sums, cache: cache);
    if (groupByResult.isErr()) return Err(groupByResult.unwrapErr());
    Map<String, Map<String, Coin>> byPolicyIdThenName = groupByResult.unwrap();
    //build new change output
    List<ShelleyMultiAsset> multiAssets = [];
    Coin lovelace = coinZero;
    for (final policyId in byPolicyIdThenName.keys) {
      Map<String, Coin> byName = byPolicyIdThenName[policyId]!;
      List<ShelleyAsset> assets = [];
      for (final name in byName.keys) {
        final Coin value = _existingBalance(
            changeOutput: changeOutput, policyId: policyId, name: name);
        if (policyId == '' && name == lovelaceHex) {
          //special handling for lovelace
          lovelace = value + (byName[name] ?? coinZero);
        } else {
          assets.add(ShelleyAsset(
              name: name, value: value + (byName[name] ?? coinZero)));
        }
      }
      if (assets.isNotEmpty) {
        multiAssets.add(ShelleyMultiAsset(policyId: policyId, assets: assets));
      }
    }
    final value = ShelleyValue(coin: lovelace, multiAssets: multiAssets);
    outputs.add(ShelleyTransactionOutput(address: targetAddress, value: value));
    return Ok(outputs);
  }

  ShelleyTransactionOutput? firstWhere(
      List<ShelleyTransactionOutput> list, String address) {
    for (final out in list) {
      if (out.address == address) return out;
    }
    return null;
  }

  /// fish out the balance for a give policyId+name from an existing change output
  Coin _existingBalance(
      {ShelleyTransactionOutput? changeOutput,
      required String policyId,
      required String name}) {
    if (changeOutput == null) return coinZero;
    if (policyId == '' && name == lovelaceHex) {
      //special handling for lovelace
      return changeOutput.value.coin;
    } else {
      ShelleyMultiAsset? multiAsset =
          changeOutput.value.multiAssets.firstWhereOrNull(
        (m) => m.policyId == policyId,
      );
      if (multiAsset == null) return coinZero;
      ShelleyAsset? asset =
          multiAsset.assets.firstWhereOrNull((a) => a.name == name);
      if (asset == null) return coinZero;
      return asset.value;
    }
  }

  /// Break-up assetId into policyId and name, putting results in nested maps so
  /// the data structure matches the data nesting in the ShelleyMultiAsset class.
  /// All native tokens must have a CurrencyAsset in the cache.
  Result<Map<String, Map<String, Coin>>, String> _groupByPolicyIdThenName({
    required Map<AssetId, Coin> sums,
    required BlockchainCache cache,
  }) {
    Map<String, Map<String, Coin>> byPolicyId = {};
    for (final assetId in sums.keys) {
      final currencyAsset = cache.cachedCurrencyAsset(assetId);
      if (currencyAsset == null) {
        return Err("no CurrencyAsset for assetId: '$assetId' in cache");
      }
      Map<String, Coin> byName = byPolicyId[currencyAsset.policyId] ?? {};
      if (byName.isEmpty) byPolicyId[currencyAsset.policyId] = byName;
      Coin coin = byName[currencyAsset.assetName] ?? coinZero;
      byName[currencyAsset.assetName] = coin + (sums[assetId] ?? coinZero);
    }
    return Ok(byPolicyId);
  }
}
