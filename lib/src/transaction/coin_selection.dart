import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:cardano_wallet_sdk/src/transaction/spec/shelley_spec.dart';
import 'package:cardano_wallet_sdk/src/transaction/transaction.dart';
import 'package:cardano_wallet_sdk/src/util/ada_types.dart';
import 'package:oxidized/oxidized.dart';

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
/// which point to an UTXO unspent change entry using a transactionId and index.
///
/// class ShelleyTransactionInput {
///  final String transactionId;
///  final int index;
/// }

typedef CoinSelectionAlgorithm = Future<Result<CoinSelection, CoinSelectionError>> Function({
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
  factory MultiAssetRequest.lovelace(Coin amount) =>
      MultiAssetRequest(policyId: '', assets: [AssetRequest(name: lovelaceHex, value: amount)]);
}

///
/// Special builder for creating ShelleyValue objects containing multi-asset transactions.
///
class MultiAssetRequestBuilder {
  List<MultiAssetRequest> _multiAssets = [];

  MultiAssetRequestBuilder({required Coin coin})
      : _multiAssets = [
          MultiAssetRequest(policyId: '', assets: [AssetRequest(name: lovelaceHex, value: coin)])
        ];

  List<MultiAssetRequest> build() => _multiAssets;

  MultiAssetRequestBuilder multiAssetRequest(MultiAssetRequest multiAssetRequest) {
    _multiAssets.add(multiAssetRequest);
    return this;
  }

  MultiAssetRequestBuilder nativeAsset({required String policyId, String? hexName, required Coin value}) {
    final assetRequest =
        MultiAssetRequest(policyId: policyId, assets: [AssetRequest(name: hexName ?? '', value: value)]);
    return multiAssetRequest(assetRequest);
  }
}

class CoinSelection {
  final List<ShelleyTransactionInput> inputs;
  CoinSelection({required this.inputs});
}

class CardanoInput {}

enum CoinSelectionErrorEnum {
  Unsupported,
  InputValueInsufficient,
  InputCountInsufficient,
  InputLimitExceeded,
  InputsExhausted,
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
  if (outputsRequested.isEmpty) {
    return Err(CoinSelectionError(
        reason: CoinSelectionErrorEnum.InputCountInsufficient, message: "can't create an empty transaction"));
  }
  final String hardCodedUnit = lovelaceHex;
  Coin amount = 0;
  for (final reqest in outputsRequested) {
    if (reqest.policyId == '') {
      for (final asset in reqest.assets) {
        if (asset.name == lovelaceHex) {
          amount = asset.value;
        } else {
          return Err(CoinSelectionError(
            reason: CoinSelectionErrorEnum.Unsupported,
            message: "only support ADA transactions at this time",
          ));
        }
      }
    } else {
      return Err(CoinSelectionError(
        reason: CoinSelectionErrorEnum.Unsupported,
        message: "only support ADA transactions at this time",
      ));
    }
  }
  if (amount <= 0) {
    return Err(CoinSelectionError(
      reason: CoinSelectionErrorEnum.InputValueInsufficient,
      message: "transactions must be greater than zero",
    ));
  }
  final List<WalletTransaction> sortedInputs = List.from(unspentInputsAvailable);
  sortedInputs.sort((a, b) => b.amount.compareTo(a.amount));
  List<ShelleyTransactionInput> results = [];
  Coin selectedAmount = 0;
  int coinsSelected = 0;
  for (final tx in sortedInputs) {
    int index = 0;
    for (final output in tx.outputs) {
      //Coin coinAmount = tx.currencyAmount(assetId: hardCodedUnit);
      if (ownedAddresses.contains(output.address)) {
        for (final txAmount in output.amounts) {
          if (txAmount.quantity > 0 && txAmount.unit == hardCodedUnit) {
            selectedAmount += txAmount.quantity;
            if (logSelection) {
              print(
                  "selectedAmount += quantity: $selectedAmount += ${txAmount.quantity} -> tx: ${tx.txId} index: $index");
            }
            if (++coinsSelected > coinSelectionLimit) {
              return Err(CoinSelectionError(
                reason: CoinSelectionErrorEnum.InputsExhausted,
                message: "coinsSelected ($coinsSelected) exceeds allowed coinSelectionLimit ($coinSelectionLimit)",
              ));
            }
            results.add(ShelleyTransactionInput(index: index, transactionId: tx.txId));
          }
        }
      }
      index++;
    }
    if (selectedAmount >= amount) {
      break;
    }
  }
  if (selectedAmount < amount) {
    return Err(CoinSelectionError(
      reason: CoinSelectionErrorEnum.InputValueInsufficient,
      message: "insufficient funds",
    ));
  }
  return Ok(CoinSelection(inputs: results));
}
