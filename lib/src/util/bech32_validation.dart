// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:logger/logger.dart';
import 'package:oxidized/oxidized.dart';
import 'package:quiver/strings.dart';

final _logger = Logger();

///
/// if bech32 string has the correct prefix, '1' seperator, legal data characters and optionaly correct length,
/// the normalized correct form is returned. If it's not legal, then an explanation is returned in the error message.
///
Result<String, String> validBech32(
    {required String bech32,
    required List<String> hrpPrefixes,
    int? dataPartRequiredLength}) {
  if (hrpPrefixes.isEmpty) {
    throw Exception("validBech32 hrpPrefixes array must not be empty");
  }
  if (isBlank(bech32)) return Err("address missing");
  final lowerCase = bech32.toLowerCase();
  if (hrpPrefixes.length > 1) {
    hrpPrefixes.sort((a, b) => b.compareTo(a));
  } //avoid matching 'addr' for 'addr_test'
  _logger.i(hrpPrefixes);
  final prefix = hrpPrefixes
      .firstWhere((prefix) => lowerCase.startsWith(prefix), orElse: () => '');
  if (isBlank(prefix)) {
    return Err("must start with ${hrpPrefixes.join(' or ')}");
  }
  if (lowerCase.length > prefix.length &&
      lowerCase.codeUnitAt(prefix.length) != '1'.codeUnitAt(0)) {
    return Err("missing '1' after prefix");
  }
  final data = lowerCase.length > prefix.length
      ? lowerCase.substring(prefix.length + 1)
      : '';
  int invalidCharIndex = _firstIllegalDataChar(data);
  if (invalidCharIndex > -1) {
    return Err(
        "invalid character: ${data.substring(invalidCharIndex, invalidCharIndex + 1)}");
  }
  if (dataPartRequiredLength != null && data.length != dataPartRequiredLength) {
    return Err(
        "data length is ${data.length}, requires $dataPartRequiredLength");
  }
  return Ok(lowerCase);
}

int _firstIllegalDataChar(String bech32Data) {
  for (int i = 0; i < bech32Data.length; i++) {
    if (!_legalBech32Char(bech32Data.codeUnitAt(i))) return i;
  }
  return -1;
}

bool _legalBech32Char(int ch16) =>
    _indexOfCodeUnit(ch16, _bech32LegalDataChars) > -1;

int _indexOfCodeUnit(int ch16, List<int> codeUnits) {
  for (int i = 0; i < codeUnits.length; i++) {
    if (ch16 == codeUnits[i]) return i;
  }
  return -1;
}

final _bech32LegalDataChars =
    '023456789acdefghjklmnpqrstuvwxyz'.codeUnits; //exlucdes '1bio'
