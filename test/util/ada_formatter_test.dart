// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('ADAFormattter - ', () {
    test('currency', () {
      final formatter = AdaFormattter.currency();
      print(formatter.format(120));
      print(formatter.format(120000));
      print(formatter.format(120000000));
      print(formatter.format(120000000000));
      print(formatter.format(120000000000000));
      print(formatter.format(120000000000000000));
      print(formatter.format(9000000000000000000));
      expect(formatter.format(120), equals('₳0.000120'));
      expect(formatter.format(120000), equals('₳0.120000'));
      expect(formatter.format(120000000), equals('₳120.000000'));
      expect(formatter.format(120000000000), equals('₳120,000.000000'));
      expect(formatter.format(120000000000000), equals('₳120,000,000.000000'));
      expect(formatter.format(120000000000000000),
          equals('₳120,000,000,000.000000'));
      expect(formatter.format(9000000000000000000),
          equals('₳9,000,000,000,000.000000'));
    });
    test('compactCurrency', () {
      final formatter = AdaFormattter.compactCurrency();
      print(formatter.format(120));
      print(formatter.format(120000));
      print(formatter.format(120000000));
      print(formatter.format(120000000000));
      print(formatter.format(120000000000000));
      print(formatter.format(120000000000000000));
      print(formatter.format(9000000000000000000));
      expect(formatter.format(120), equals('₳0.000120'));
      expect(formatter.format(120000), equals('₳0.120000'));
      expect(formatter.format(120000000), equals('₳120'));
      expect(formatter.format(120000000000), equals('₳120K'));
      expect(formatter.format(120000000000000), equals('₳120M'));
      expect(formatter.format(120000000000000000), equals('₳120B'));
      expect(formatter.format(9000000000000000000), equals('₳9T'));
    });
    test('simpleCurrency', () {
      final formatter = AdaFormattter.simpleCurrency();
      print(formatter.format(120));
      print(formatter.format(120000));
      print(formatter.format(120000000));
      print(formatter.format(120000000000));
      print(formatter.format(120000000000000));
      print(formatter.format(120000000000000000));
      print(formatter.format(9000000000000000000));
      expect(formatter.format(120), equals('ADA 0.000120'));
      expect(formatter.format(120000), equals('ADA 0.120000'));
      expect(formatter.format(120000000), equals('ADA 120.000000'));
      expect(formatter.format(120000000000), equals('ADA 120,000.000000'));
      expect(
          formatter.format(120000000000000), equals('ADA 120,000,000.000000'));
      expect(formatter.format(120000000000000000),
          equals('ADA 120,000,000,000.000000'));
      expect(formatter.format(9000000000000000000),
          equals('ADA 9,000,000,000,000.000000'));
    });
    test('simpleCurrencyEU', () {
      final formatter = AdaFormattter.simpleCurrency(locale: 'eu', name: 'ADA');
      //final f = formatter.format(120);
      //print("index8: ${f.codeUnitAt(8)}");
      //final suffix = utf8.decode([0xA0, 65, 68, 65]);
      print(formatter.format(120));
      print(formatter.format(120000));
      print(formatter.format(120000000));
      print(formatter.format(120000000000));
      print(formatter.format(120000000000000));
      print(formatter.format(120000000000000000));
      print(formatter.format(9000000000000000000));
      //expect(formatter.format(120), equals('0,000120\u{00A0}ADA'));
      // expect(formatter.format(120000), equals('0,120000 ADA'));
      // expect(formatter.format(120000000), equals('120,000000 ADA'));
      // expect(formatter.format(120000000000), equals('120.000,000000 ADA'));
      // expect(formatter.format(120000000000000), equals('120.000.000,000000 ADA'));
      // expect(formatter.format(120000000000000000), equals('120.000.000.000,000000 ADA'));
      // expect(formatter.format(9000000000000000000), equals('9.000.000.000.000,000000 ADA'));
    });
    test('compactSimpleCurrency', () {
      final formatter = AdaFormattter.compactSimpleCurrency();
      print(formatter.format(120));
      print(formatter.format(120000));
      print(formatter.format(120000000));
      print(formatter.format(120000000000));
      print(formatter.format(120000000000000));
      print(formatter.format(120000000000000000));
      print(formatter.format(9000000000000000000));
      expect(formatter.format(120), equals('ADA 0.000120'));
      expect(formatter.format(120000), equals('ADA 0.120000'));
      expect(formatter.format(120000000), equals('ADA 120'));
      expect(formatter.format(120000000000), equals('ADA 120K'));
      expect(formatter.format(120000000000000), equals('ADA 120M'));
      expect(formatter.format(120000000000000000), equals('ADA 120B'));
      expect(formatter.format(9000000000000000000), equals('ADA 9T'));
    });
  });
}
