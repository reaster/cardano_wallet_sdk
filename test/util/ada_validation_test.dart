// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('ada validation - ', () {
    test('valid', () {
      final result = validAda(ada: '1');
      print(result.unwrap());
      expect(result.unwrap(), '1.0');
      expect(validAda(ada: '01').isOk(), isTrue);
      expect(validAda(ada: '0123456789000').isOk(), isTrue);
      expect(validAda(ada: '.777777').isOk(), isTrue);
      expect(validAda(ada: '0.123456').isOk(), isTrue);
      expect(validAda(ada: '12345.678900').isOk(), isTrue);
      expect(validAda(ada: '12345.').isOk(), isTrue);
      expect(validAda(ada: '00000.000', zeroAllowed: true).isOk(), isTrue);
      expect(
          validAda(ada: '-00000.000', zeroAllowed: true, allowNegative: true)
              .isOk(),
          isTrue);
      expect(validAda(ada: '-1', allowNegative: true).isOk(), isTrue);
      expect(validAda(ada: '.', zeroAllowed: true).isOk(), isTrue);
    });
    test('normalization', () {
      final result = validAda(ada: '1');
      print(result.unwrap());
      expect(result.unwrap(), '1.0');
      expect(validAda(ada: '01').unwrap(), '1.0');
      expect(validAda(ada: '0123456789000').unwrap(), '123456789000.0');
      expect(validAda(ada: '.777777').unwrap(), '0.777777');
      expect(validAda(ada: '0.123456').unwrap(), '0.123456');
      expect(validAda(ada: '12345.678900').unwrap(), '12345.6789');
      expect(validAda(ada: '12345.').unwrap(), '12345.0');
      expect(validAda(ada: '00000.000', zeroAllowed: true).unwrap(), '0.0');
      expect(
          validAda(ada: '-00000.000', zeroAllowed: true, allowNegative: true)
              .unwrap(),
          '-0.0');
      expect(validAda(ada: '-1', allowNegative: true).unwrap(), '-1.0');
      expect(validAda(ada: '.', zeroAllowed: true).unwrap(), '0.0');
    });
    test('invalid precision length', () {
      final result = validAda(ada: '.1234567');
      expect(result.isErr(), isTrue);
      print(result.unwrapErr());
    });
    test('zero', () {
      expect(validAda(ada: '.').isErr(), isTrue);
      expect(validAda(ada: '0', zeroAllowed: false).isErr(), isTrue);
      expect(validAda(ada: '0', zeroAllowed: true).isOk(), isTrue);
    });
    test('invalid data char', () {
      final result = validAda(ada: 'a');
      expect(result.isErr(), isTrue);
      print(result.unwrapErr());
      expect(validAda(ada: '-.1').isErr(), isTrue);
    });
  });
}
