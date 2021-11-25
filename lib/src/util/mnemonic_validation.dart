// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:oxidized/oxidized.dart';
import 'package:bip39/bip39.dart' as bip39;

///
/// If the mnemonic or recovery phrase has all legal characters and the
/// requiredNumberOfWords, then the normalized correct form is returned.
/// If it's not legal, then an explanation is returned in the error message.
///
Result<String, String> validMnemonic({
  required String phrase,
  int requiredNumberOfWords = 24,
}) {
  if (phrase.isEmpty) {
    return Err("mnemonic required");
  }
  final lowerCase = phrase.toLowerCase().trim(); //TODO normalize white space
  int invalidCharIndex = _firstIllegalDataChar(lowerCase);
  if (invalidCharIndex > -1) {
    return Err(
        "invalid character: ${lowerCase.substring(invalidCharIndex, invalidCharIndex + 1)}");
  }
  final words = lowerCase.split(' ');
  try {
    bip39.mnemonicToEntropy(lowerCase);
  } on ArgumentError catch (e) {
    //might be a bad word, see if we can find it
    final validity = validMnemonicWords(words);
    if (validity.isErr()) return Err(validity.unwrapErr());
    //otherwise check length
    if (words.length != requiredNumberOfWords) {
      return Err("$requiredNumberOfWords words required");
    }
    return Err(e.message);
  } on StateError catch (e) {
    if (words.length != requiredNumberOfWords) {
      return Err("$requiredNumberOfWords words required");
    }
    return Err(e.message);
  } catch (e) {
    return Err(e.toString());
  }
  if (words.length != requiredNumberOfWords) {
    return Err("$requiredNumberOfWords words required");
  }
  return Ok(lowerCase);
}

/// Return true if a all the provided mnemonic words are valid.
Result<bool, String> validMnemonicWords(List<String> words) {
  for (final word in words) {
    if (!validMnemonicWord(word)) {
      return Err("invalid mnemonic word: '$word'");
    }
  }
  return Ok(true);
}

/// Return true if a valid mnemonic word
bool validMnemonicWord(String word) {
  // not a great implementation because it depends on the inner details of bip39
  try {
    // just need 3 words to avoid length error - append 2 valid words
    bip39.mnemonicToEntropy('${word.toLowerCase().trim()} ability able');
  } on ArgumentError {
    return false;
  } on StateError {
    return true; //StateError is not valid to this test
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
