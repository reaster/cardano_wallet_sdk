// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:oxidized/oxidized.dart';
import 'mnemonic.dart';

///
/// If the mnemonic or recovery phrase has all legal characters and the
/// requiredNumberOfWords, then the normalized correct form is returned.
/// If it's not legal, then an explanation is returned in the error message.
///
Result<ValidMnemonicPhrase, String> validMnemonic({
  required String phrase,
  int requiredNumberOfWords = 24,
  required LoadMnemonicWordsFunction loadWordsFunction,
  MnemonicLang lang = MnemonicLang.english,
}) {
  if (phrase.isEmpty) {
    return Err("mnemonic required");
  }
  final ValidMnemonicPhrase mnemonic = phrase.toLowerCase().trim().split(' ');
  if (mnemonic.length < 3) {
    return Err("at least 3 mnemonic words required");
  }
  final wordList = loadWordsFunction(lang: lang);
  try {
    mnemonicWordsToEntropy(mnemonic: mnemonic, wordList: wordList);
  } on ArgumentError catch (e) {
    //might be a bad word, see if we can find it
    for (String word in mnemonic) {
      final index = wordList.indexOf(word);
      if (index == -1) {
        return Err("invalid mnemonic word: '$word'");
      }
    }
    // final validity = validMnemonicWords(words);
    // if (validity.isErr()) return Err(validity.unwrapErr());
    //otherwise check length
    if (mnemonic.length != requiredNumberOfWords) {
      return Err("$requiredNumberOfWords words required");
    }
    return Err(e.message);
  } on StateError catch (e) {
    if (mnemonic.length != requiredNumberOfWords) {
      return Err("$requiredNumberOfWords words required");
    }
    return Err(e.message);
  } catch (e) {
    return Err(e.toString());
  }
  if (mnemonic.length != requiredNumberOfWords) {
    return Err("$requiredNumberOfWords words required");
  }
  return Ok(mnemonic);
}

// /// Return true if a all the provided mnemonic words are valid.
// Result<bool, String> validMnemonicWords(List<String> words) {
//   for (final word in words) {
//     if (!validMnemonicWord(word)) {
//       return Err("invalid mnemonic word: '$word'");
//     }
//   }
//   return Ok(true);
// }

// /// Return true if a valid mnemonic word
// bool validMnemonicWord(String word) {
//   // not a great implementation because it depends on the inner details of bip39
//   try {
//     // just need 3 words to avoid length error - append 2 valid words
//     mnemonicToEntropyHex(
//         '${word.toLowerCase().trim()} ability able'.split(' '));
//   } on ArgumentError {
//     return false;
//   } on StateError {
//     return true; //StateError is not valid to this test
//   }
//   return true;
// }

// int _firstIllegalDataChar(String bech32Data) {
//   for (int i = 0; i < bech32Data.length; i++) {
//     if (!_legalBech32Char(bech32Data.codeUnitAt(i))) return i;
//   }
//   return -1;
// }

// bool _legalBech32Char(int ch16) =>
//     _indexOfCodeUnit(ch16, _mnemonicLegalDataChars) > -1;

// int _indexOfCodeUnit(int ch16, List<int> codeUnits) {
//   for (int i = 0; i < codeUnits.length; i++) {
//     if (ch16 == codeUnits[i]) return i;
//   }
//   return -1;
// }

// final _mnemonicLegalDataChars = ' abcdefghijklmnopqrstuvwxyz'
//     .codeUnits; //call toLowerCase() on target string
