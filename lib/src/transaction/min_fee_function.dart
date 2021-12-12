// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:logger/logger.dart';
import '../util/ada_types.dart';
import './spec/shelley_spec.dart';

typedef MinFeeFunction = Coin Function(
    {required ShelleyTransaction transaction, LinearFee linearFee});

///
/// calculate transaction fee based on transaction lnegth and minimum constant
///
Coin simpleMinFee(
    {required ShelleyTransaction transaction,
    LinearFee linearFee = defaultLinearFee}) {
  final logger = Logger();
  final len = transaction.toCborList().getData().length;
  final result =
      (len + lenHackAddition) * linearFee.coefficient + linearFee.constant;
  logger.i(
      "simpleMinFee = len($len+$lenHackAddition)*${linearFee.coefficient} + ${linearFee.constant} = $result");
  return result;
}

///
/// Used in calculating Cardano transaction fees.
///
class LinearFee {
  final Coin constant;
  final Coin coefficient;

  const LinearFee({required this.constant, required this.coefficient});
}

const minFeeA = 44;
const minFeeB = 155381;
const lenHackAddition = 5;

/// fee calculation factors
/// TODO update this from blockchain
/// TODO verify fee calculation context of this values
// const defaultLinearFee = LinearFee(constant: 2, coefficient: 500);
const defaultLinearFee = LinearFee(coefficient: minFeeA, constant: minFeeB);
//
/// default fee for simple ADA transaction
const defaultFee = 170000; // 0.2 ADA

/* .getCardanoEpochsApi().epochsNumberParametersGet(number: 168)
EpochParamContent {
  minFeeA=44,
  minFeeB=155381,
  maxBlockSize=65536,
  maxTxSize=16384,
  maxBlockHeaderSize=1100,
  keyDeposit=2000000,
  poolDeposit=500000000,
  eMax=18,
  nOpt=500,
  a0=0.3,
  rho=0.003,
  tau=0.2,
  decentralisationParam=0,
  protocolMajorVer=6,
  protocolMinorVer=0,
  minUtxo=34482,
  minPoolCost=340000000,
  nonce=2badcc95a813d3626830487dead021fb48d2144c547543604e034e954aa1da15,
}
*/
