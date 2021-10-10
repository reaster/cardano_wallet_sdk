import 'package:cardano_wallet_sdk/src/transaction/spec/shelley_spec.dart';
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
/// TODO the CIP-2 spec doesn't appear to handle MultiCurrency transactions. Verify.
///

typedef CoinSelectionLimit = int;

typedef CoinMap = Map<Coin, ShelleyTransactionInput>;

typedef CoinSelectionAlgorithm = Future<Result<CoinSelection, CoinSelectionError>> Function({
  CoinMap inputsAvailable,
  CoinMap outputsRequested,
  CoinSelectionLimit limit,
});

class CoinSelection {
  final Map<Coin, ShelleyTransactionInput> inputs;
  CoinSelection(this.inputs);
}

class CardanoInput {}

enum CoinSelectionErrorEnum {
  Unknown,
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
