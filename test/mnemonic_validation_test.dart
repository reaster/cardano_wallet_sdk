// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:test/test.dart';

void main() {
  const mnemonicBadChecksum =
      'ability able about above absent absorb abstract absurd abuse access accident account accuse achieve acid acoustic acquire across act action actor actress actual adapt';
  const mnemonicBadWord =
      'abbey green ocean blanket aim coin beyond oven happy never april gold way pluck over cave sick affair coach author credit bullet honey donor';
  const mnemonicBadWord2 =
      'ability able about above absent absorb abstract absurd abuse access accident account accuse achieve acid acoustic acquire across act action actor actress actual zoey';
  group('mnemonic validation - ', () {
    test('valid', () {
      final mnemonic = bip39.generateMnemonic(strength: 256);
      final result = validMnemonic(phrase: mnemonic);
      print(result.unwrap());
      expect(result.isOk(), isTrue);
      //uppercase handling
      final result2 = validMnemonic(phrase: mnemonic.toUpperCase());
      print(result2.unwrap());
      expect(result2.isOk(), isTrue);
    });
    test('mnemonic required', () {
      final result = validMnemonic(phrase: '');
      print(result.unwrapErr());
      expect(result.isErr(), isTrue);
    });
    test('requiredNumberOfWords', () {
      final result = validMnemonic(phrase: 'ability able about above');
      print(result.unwrapErr());
      expect(result.isErr(), isTrue);
      expect(result.unwrapErr().contains('24'), isTrue);
    });
    test('invalid character', () {
      final result = validMnemonic(phrase: 'ability,able');
      print(result.unwrapErr());
      expect(result.isErr(), isTrue);
      expect(result.unwrapErr().contains(','), isTrue);
    });
    test('bad mnemonic word', () {
      final result = validMnemonic(phrase: mnemonicBadWord);
      print(result.unwrapErr());
      expect(result.isErr(), isTrue);
      expect(result.unwrapErr().contains('abbey'), isTrue);
      expect(
          validMnemonic(phrase: mnemonicBadWord2).unwrapErr().contains('zoey'),
          isTrue);
    });

    test('checksum', () {
      final result = validMnemonic(phrase: mnemonicBadChecksum);
      print(result.unwrapErr());
      expect(result.isErr(), isTrue);
      expect(result.unwrapErr().contains('checksum'), isTrue);
    });
    test('validMnemonicWord', () {
      expect(validMnemonicWord('ability'), isTrue);
      expect(validMnemonicWord('abbey'), isFalse);
      expect(validMnemonicWord('zoey'), isFalse);
    });
  });
}
