// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:oxidized/oxidized.dart';
import 'package:bip39/bip39.dart' as bip39;

///
/// if mnemonic string has the legal characters and correct length,
/// the normalized correct form is returned. If it's not legal, then an explanation is returned in the error message.
///
Result<String, String> validMnemonic({
  required String phrase,
  int requiredNumberOfWords = 24,
}) {
  if (phrase.isEmpty) {
    return Err("mnemonic required");
  }
  final lowerCase = phrase.toLowerCase();
  int invalidCharIndex = _firstIllegalDataChar(lowerCase);
  if (invalidCharIndex > -1)
    return Err(
        "invalid character: ${lowerCase.substring(invalidCharIndex, invalidCharIndex + 1)}");
  final words = lowerCase.split(' ');
  if (words.length != requiredNumberOfWords)
    return Err("$requiredNumberOfWords words required");
  try {
    bip39.mnemonicToEntropy(lowerCase);
  } on ArgumentError catch (e) {
    final badWord = _findBadMnemonicWord(words);
    if (badWord.isErr()) return Err(badWord.unwrapErr());
    return Err(e.message);
  } on StateError catch (e) {
    return Err(e.message);
  } catch (e) {
    return Err(e.toString());
  }
  return Ok(lowerCase);
}

Result<bool, String> _findBadMnemonicWord(List<String> words) {
  for (final word in words) {
    if (!validMnemonicWord(word)) {
      return Err("invalid mnemonic word: '$word'");
    }
  }
  return Ok(true);
}

/// return true if a valid mnemonic word
bool validMnemonicWord(String word) {
  // not a great implementation because it depends on the inner details of bip39
  try {
    bip39.mnemonicToEntropy(word.toLowerCase().trim() + ' ability able');
  } on ArgumentError {
    return false;
  } on StateError {
    return true;
  }
  return true;
}

int _firstIllegalDataChar(String bech32Data) {
  for (int i = 0; i < bech32Data.length; i++) {
    if (!_legalBech32Char(bech32Data.codeUnitAt(i))) return i;
  }
  return -1;
}

bool _legalBech32Char(int ch16) =>
    _indexOfCodeUnit(ch16, _mnemonicLegalDataChars) > -1;

int _indexOfCodeUnit(int ch16, List<int> codeUnits) {
  for (int i = 0; i < codeUnits.length; i++) {
    if (ch16 == codeUnits[i]) return i;
  }
  return -1;
}

final _mnemonicLegalDataChars = ' abcdefghijklmnopqrstuvwxyz'
    .codeUnits; //call toLowerCase() on target string 
