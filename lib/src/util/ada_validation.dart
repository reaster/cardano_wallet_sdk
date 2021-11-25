// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:oxidized/oxidized.dart';

///
/// If ADA string is all digits, not negative and the correct decimal precision, then the normalized
/// correct form is returned.
/// If it's not legal, then an explanation is returned in the error message.
///
Result<String, String> validAda({
  required String ada,
  int decimalPrecision = 6,
  bool allowNegative = false,
  bool zeroAllowed = false,
}) {
  ada = ada.trim();
  int invalidCharIndex = _firstIllegalDataChar(ada, allowNegative);
  if (invalidCharIndex > -1) {
    return Err(
        "invalid character: ${ada.substring(invalidCharIndex, invalidCharIndex + 1)}");
  }
  final amount = double.tryParse(ada) ?? 0.0;
  if (!zeroAllowed && amount == 0.0) return Err("can't be zero");
  final index = ada.lastIndexOf('.');
  final fraction =
      index >= 0 && index < ada.length ? ada.substring(index + 1) : '';
  if (fraction.length > decimalPrecision) {
    return Err("only $decimalPrecision decimal places allowed");
  }
  return Ok('$amount');
}

int _firstIllegalDataChar(String ada, bool allowNegative) {
  for (int i = 0; i < ada.length; i++) {
    if (!_legalAdaChar(ada.codeUnitAt(i), allowNegative)) return i;
  }
  return -1;
}

bool _legalAdaChar(int ch16, bool allowNegative) =>
    _indexOfCodeUnit(
        ch16, allowNegative ? _adaLegalDataCharsNegative : _adaLegalDataChars) >
    -1;

int _indexOfCodeUnit(int ch16, List<int> codeUnits) {
  for (int i = 0; i < codeUnits.length; i++) {
    if (ch16 == codeUnits[i]) return i;
  }
  return -1;
}

final _adaLegalDataChars = '.0123456789'.codeUnits;
final _adaLegalDataCharsNegative = '-.0123456789'.codeUnits;
