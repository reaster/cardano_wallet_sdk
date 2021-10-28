import 'package:cardano_wallet_sdk/src/transaction/spec/shelley_spec.dart';
import 'package:cardano_wallet_sdk/src/util/ada_types.dart';

typedef MinFeeFunction = Coin Function({required ShelleyTransaction transaction, LinearFee linearFee});

///
/// calculate transaction fee based on transaction lnegth and minimum constant
///
Coin simpleMinFee({required ShelleyTransaction transaction, LinearFee linearFee = defaultLinearFee}) {
  final len = transaction.toCborList().getData().length;
  return len * linearFee.coefficient + linearFee.constant;
}

///
/// Used in calculating Cardano transaction fees.
///
class LinearFee {
  final Coin constant;
  final Coin coefficient;

  const LinearFee({required this.constant, required this.coefficient});
}

/// fee calculation factors
/// TODO update this from blockchain
/// TODO verify fee calculation context of this values
const defaultLinearFee = LinearFee(constant: 2, coefficient: 500);

/// default fee for simple ADA transaction
const defaultFee = 200000; // 0.2 ADA
