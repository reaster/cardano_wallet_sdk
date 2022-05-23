// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'dart:typed_data';
// import '../crypto/mnemonic.dart' as bip39;
// import 'package:bip39/dart' as bip39;
import 'package:hex/hex.dart';
import 'package:test/test.dart';

void main() {
  const entropyPlusCs24Words = 256;
  const testMnemonic1 =
      "elder lottery unlock common assume beauty grant curtain various horn spot youth exclude rude boost fence used two spawn toddler soup awake across use";
  const testEntropy1 =
      "475083b81730de275969b1f18db34b7fb4ef79c66aa8efdd7742f1bcfe204097";
  const testHexSeed1 =
      '3e545a8c7aed6e4e0a152a4884ab53b6f1f0d7916f22793c7618949d891a1a80772b7a2e27dbf9b1a8027c4c481a1f423b7da3f4bf6ee70d4a3a2e940c87d74f';

  Uint8List randomBytes(int size) =>
      Uint8List.fromList(HEX.decode(testEntropy1));

  test('validateMnemonic', () {
    expect(
        validateMnemonic(
            mnemonic: 'sleep kitten'.split(' '),
            loadWordsFunction: loadEnglishMnemonicWords),
        isFalse,
        reason: 'fails for a mnemonic that is too short');

    expect(
        validateMnemonic(
            mnemonic: 'sleep kitten sleep kitten sleep kitten'.split(' '),
            loadWordsFunction: loadEnglishMnemonicWords),
        isFalse,
        reason: 'fails for a mnemonic that is too short');

    expect(
        validateMnemonic(
            mnemonic:
                'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about end grace oxygen maze bright face loan ticket trial leg cruel lizard bread worry reject journey perfect chef section caught neither install industry'
                    .split(' '),
            loadWordsFunction: loadEnglishMnemonicWords),
        isFalse,
        reason: 'fails for a mnemonic that is too long');

    expect(
        validateMnemonic(
            mnemonic:
                'turtle front uncle idea crush write shrug there lottery flower risky shell'
                    .split(' '),
            loadWordsFunction: loadEnglishMnemonicWords),
        isFalse,
        reason: 'fails if mnemonic words are not in the word list');

    expect(
        validateMnemonic(
            mnemonic:
                'sleep kitten sleep kitten sleep kitten sleep kitten sleep kitten sleep kitten'
                    .split(' '),
            loadWordsFunction: loadEnglishMnemonicWords),
        isFalse,
        reason: 'fails for invalid checksum');

    expect(
        validateMnemonic(
            mnemonic: testMnemonic1.split(' '),
            loadWordsFunction: loadEnglishMnemonicWords),
        isTrue,
        reason: "testMnemonic1 valid");
  });

  group('generateNewMnemonic', () {
    test('can vary entropy length', () {
      final words = (generateNewMnemonic(
          strength: 160, loadWordsFunction: loadEnglishMnemonicWords));
      expect(words.length, equals(15),
          reason: 'can vary generated entropy bit length');
    });
    test('Cardano Shelley entropy length 24', () {
      final words = (generateNewMnemonic(
          strength: entropyPlusCs24Words,
          loadWordsFunction: loadEnglishMnemonicWords));
      print(words.join(','));
      expect(words.length, equals(24),
          reason: 'can vary generated entropy bit length');
    });

    test('requests the exact amount of data from an RNG', () {
      generateNewMnemonic(
          strength: 160,
          loadWordsFunction: loadEnglishMnemonicWords,
          randomBytes: (int size) {
            expect(size, 160 / 8);
            return Uint8List(size);
          });
    });
  });

  group('for English mnemonic words and entropy+check sum = 256 bits', () {
    setUp(() {});
    test('mnemoic to entropy', () {
      final String entropy = mnemonicToEntropyHex(
          mnemonic: testMnemonic1.split(' '),
          loadWordsFunction: loadEnglishMnemonicWords);
      expect(entropy, equals(testEntropy1));
    });
    // test('mnemonic with passphrase to seed hex', () {
    //   final seedHex =
    //       mnemonicToMasterHex(testMnemonic1.split(' '), passphrase: "TREZOR");
    //   print("seedHex: $seedHex");
    //   expect(seedHex, equals(testHexSeed1));
    // });
    // test('mnemonic to seed hex', () {
    //   final mnemonic1 =
    //       "elder lottery unlock common assume beauty grant curtain various horn spot youth exclude rude boost fence used two spawn toddler soup awake across use";
    //   final entropy1 =
    //       "475083b81730de275969b1f18db34b7fb4ef79c66aa8efdd7742f1bcfe204097";
    //   final seedHexExpected =
    //       "59ca0ddcf4ece58539aab7fe22f8087a7a8e7443e44d7f9a133fd95553dce27ced711286cbb261bbb2af92803e02b6a136c058ed3b696956347d3704e73b5d60";

    //   final seedHex = mnemonicToMasterHex(mnemonic1.split(' '), passphrase: "");
    //   print("seedHex: $seedHex");
    //   expect(seedHex, equals(seedHexExpected));
    // });

    test('entropy to mnemonic', () {
      final code = entropyHexToMnemonic(
          entropyHex: testEntropy1,
          loadWordsFunction: loadEnglishMnemonicWords);
      expect(code, equals(testMnemonic1.split(' ')));
    });

    test('generate mnemonic', () {
      final code = generateNewMnemonic(
          randomBytes: randomBytes,
          loadWordsFunction: loadEnglishMnemonicWords);
      expect(code, equals(testMnemonic1.split(' ')),
          reason: 'generateMnemonic returns randomBytes entropy unmodified');
    });
    test('validate mnemonic', () {
      expect(
          validateMnemonic(
              mnemonic: testMnemonic1.split(' '),
              loadWordsFunction: loadEnglishMnemonicWords),
          isTrue,
          reason: 'validateMnemonic returns true');
    });
  });

  group('cardano-serialization-lib', () {
    test('entropy to mnemonic', () {
      //[0x4e, 0x82, 0x8f, 0x9a, 0x67, 0xdd, 0xcf, 0xf0, 0xe6, 0x39, 0x1a, 0xd4, 0xf2, 0x6d, 0xdb, 0x75, 0x79, 0xf5, 0x9b, 0xa1, 0x4b, 0x6d, 0xd4, 0xba, 0xf6, 0x3d, 0xcf, 0xdb, 0x9d, 0x24, 0x20, 0xda];
      const testEntropy0 =
          '4e828f9a67ddcff0e6391ad4f26ddb7579f59ba14b6dd4baf63dcfdb9d2420da';
      final mnemonic = entropyHexToMnemonic(
          entropyHex: testEntropy0,
          loadWordsFunction: loadEnglishMnemonicWords);
      //final bytes = mnemonicToSeed(mnemonic);
      //print(bytes.join(','));
      //print(mnemonic);
      expect(
          mnemonic,
          equals(
              'excess behave track soul table wear ocean cash stay nature item turtle palm soccer lunch horror start stumble month panic right must lock dress'
                  .split(' ')));
    });
  });
}
