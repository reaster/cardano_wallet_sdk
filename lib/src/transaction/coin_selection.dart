// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:logger/logger.dart';
import 'package:oxidized/oxidized.dart';
import '../address/shelley_address.dart';
import '../util/ada_types.dart';
import '../asset/asset.dart';
import './spec/shelley_spec.dart';
import './transaction.dart';

///
/// Coin selection is the process of picking UTxO inputs to perticipate in a spending transaction.
/// There is a dedicated Cardano Improvement Proposal that this implementation is attempting to
/// follo in spirit:
///
///   https://cips.cardano.org/cips/cip2
///
/// Implementations details can be found here:
///
///   https://hackage.haskell.org/package/cardano-coin-selection-1.0.1/docs/Cardano-CoinSelection-Algorithm-LargestFirst.html
///   https://hackage.haskell.org/package/cardano-coin-selection-1.0.1/docs/src/Cardano.CoinSelection.Algorithm.LargestFirst.html
///   https://hackage.haskell.org/package/cardano-coin-selection-1.0.1/docs/Cardano-CoinSelection-Algorithm-RandomImprove.html
///   https://hackage.haskell.org/package/cardano-coin-selection-1.0.1/docs/src/Cardano.CoinSelection.Algorithm.RandomImprove.html
///
/// The result of this method will ultimatly be a list of ShelleyTransactionInput
/// which point to an UTXO unspent change entry using a transactionId and index:
///
/// class ShelleyTransactionInput {
///  final String transactionId;
///  final int index;
/// }

/// coin selection function type
typedef CoinSelectionAlgorithm
    = Future<Result<CoinSelection, CoinSelectionError>> Function({
  required List<WalletTransaction> unspentInputsAvailable,
  required List<MultiAssetRequest> outputsRequested,
  required Set<ShelleyAddress> ownedAddresses,
  int coinSelectionLimit,
  bool logSelection,
});

/// an single asset name and value under a MultiAsset policyId
class AssetRequest {
  final String name;
  final Coin value;

  AssetRequest({required this.name, required this.value});
}

/// Native Token multi-asset container.
class MultiAssetRequest {
  final String policyId;
  final List<AssetRequest> assets;
  MultiAssetRequest({required this.policyId, required this.assets});
  factory MultiAssetRequest.lovelace(Coin amount) => MultiAssetRequest(
      policyId: '', assets: [AssetRequest(name: lovelaceHex, value: amount)]);
}

///
/// Special builder for creating ShelleyValue objects containing multi-asset transactions.
///
class MultiAssetRequestBuilder {
  final List<MultiAssetRequest> _multiAssets;

  MultiAssetRequestBuilder({required Coin coin})
      : _multiAssets = [
          MultiAssetRequest(
              policyId: '',
              assets: [AssetRequest(name: lovelaceHex, value: coin)])
        ];

  List<MultiAssetRequest> build() => _multiAssets;

  MultiAssetRequestBuilder multiAssetRequest(
      MultiAssetRequest multiAssetRequest) {
    _multiAssets.add(multiAssetRequest);
    return this;
  }

  MultiAssetRequestBuilder nativeAsset(
      {required String policyId, String? hexName, required Coin value}) {
    final assetRequest = MultiAssetRequest(
        policyId: policyId,
        assets: [AssetRequest(name: hexName ?? '', value: value)]);
    return multiAssetRequest(assetRequest);
  }
}

class CoinSelection {
  final List<ShelleyTransactionInput> inputs;
  CoinSelection({required this.inputs});
}

enum CoinSelectionErrorEnum {
  unsupported,
  inputValueInsufficient,
  inputCountInsufficient,
  inputLimitExceeded,
  inputsExhausted,
}

class CoinSelectionError {
  final CoinSelectionErrorEnum reason;
  final String message;
  CoinSelectionError({required this.reason, required this.message});
}

const defaultCoinSelectionLimit = 20;

Future<Result<CoinSelection, CoinSelectionError>> largestFirst({
  required List<WalletTransaction> unspentInputsAvailable,
  required List<MultiAssetRequest> outputsRequested,
  required Set<ShelleyAddress> ownedAddresses,
  int coinSelectionLimit = defaultCoinSelectionLimit,
  bool logSelection = false,
}) async {
  final logger = Logger();
  if (outputsRequested.isEmpty) {
    return Err(CoinSelectionError(
        reason: CoinSelectionErrorEnum.inputCountInsufficient,
        message: "can't create an empty transaction"));
  }
  const String hardCodedUnit = lovelaceHex;
  Coin amount = 0;
  for (final reqest in outputsRequested) {
    if (reqest.policyId == '') {
      for (final asset in reqest.assets) {
        if (asset.name == lovelaceHex) {
          amount = asset.value;
        } else {
          return Err(CoinSelectionError(
            reason: CoinSelectionErrorEnum.unsupported,
            message: "only support ADA transactions at this time",
          ));
        }
      }
    } else {
      return Err(CoinSelectionError(
        reason: CoinSelectionErrorEnum.unsupported,
        message: "only support ADA transactions at this time",
      ));
    }
  }
  if (amount <= 0) {
    return Err(CoinSelectionError(
      reason: CoinSelectionErrorEnum.inputValueInsufficient,
      message: "transactions must be greater than zero",
    ));
  }
  final List<WalletTransaction> sortedInputs =
      List.from(unspentInputsAvailable);
  sortedInputs.sort((a, b) => b.amount.compareTo(a.amount));
  List<ShelleyTransactionInput> results = [];
  Coin selectedAmount = 0;
  int coinsSelected = 0;
  for (final tx in sortedInputs) {
    if (tx.status != TransactionStatus.unspent) {
      logger.i("SHOULDN'T SEE TransactionStatus.unspent HERE: ${tx.txId}");
    }
    // int index = 0;
    for (int index = 0; index < tx.outputs.length; index++) {
      final output = tx.outputs[index];
      //Coin coinAmount = tx.currencyAmount(assetId: hardCodedUnit);
      final contains = ownedAddresses.contains(output.address);
      logger.i(
          "contains:$contains, tx=${tx.txId.substring(0, 20)} index[$index]=${output.amounts.first.quantity}");
      if (contains) {
        for (final txAmount in output.amounts) {
          if (txAmount.quantity > 0 && txAmount.unit == hardCodedUnit) {
            selectedAmount += txAmount.quantity;
            if (logSelection) {
              logger.i(
                  "selectedAmount += quantity: $selectedAmount += ${txAmount.quantity} -> tx: ${tx.txId} index: $index");
            }
            if (++coinsSelected > coinSelectionLimit) {
              return Err(CoinSelectionError(
                reason: CoinSelectionErrorEnum.inputsExhausted,
                message:
                    "coinsSelected ($coinsSelected) exceeds allowed coinSelectionLimit ($coinSelectionLimit)",
              ));
            }
            results.add(
                ShelleyTransactionInput(index: index, transactionId: tx.txId));
          }
        }
      }
      //index++;
    }
    if (selectedAmount >= amount) {
      break;
    }
  }
  if (selectedAmount < amount) {
    return Err(CoinSelectionError(
      reason: CoinSelectionErrorEnum.inputValueInsufficient,
      message: "insufficient funds",
    ));
  }
  return Ok(CoinSelection(inputs: results));
}
