// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('bech32 validation - ', () {
    test('valid', () {
      final result = validBech32(
          bech32: 'addr_test1234567890acdefghjklmnpqrstuvwxyz',
          hrpPrefixes: ['addr', 'addr_test'],
          dataPartRequiredLength: 32);
      expect(result.unwrap(), 'addr_test1234567890acdefghjklmnpqrstuvwxyz');
    });
    test('fix range bug', () {
      final result = validBech32(
          bech32: 'addr',
          hrpPrefixes: ['addr', 'addr_test'],
          dataPartRequiredLength: 32);
      expect(result.isErr(), isTrue);
      print(result.unwrapErr());
    });
    test('return lower case alphas', () {
      final result = validBech32(
          bech32: 'addr_test1234567890ACDEFGHJKLMNPQRSTUVWXYZ',
          hrpPrefixes: ['addr_test', 'addr'],
          dataPartRequiredLength: 32);
      expect(result.unwrap(), 'addr_test1234567890acdefghjklmnpqrstuvwxyz');
    });
    test('invalid length', () {
      final result = validBech32(
          bech32: 'addr_test1234567890acdefghjklmnpqrstuvwxyz',
          hrpPrefixes: ['addr_test', 'addr'],
          dataPartRequiredLength: 31);
      expect(result.isErr(), isTrue);
      print(result.unwrapErr());
    });
    test('missing', () {
      final result =
          validBech32(bech32: '', hrpPrefixes: ['addr_test', 'addr']);
      expect(result.isErr(), isTrue);
      print(result.unwrapErr());
    });
    test('invalid data char', () {
      final result = validBech32(
          bech32: 'addr1234567890abcdefghjklmnpqrstuvwxyz',
          hrpPrefixes: ['addr_test', 'addr']);
      expect(result.isErr(), isTrue);
      print(result.unwrapErr());
    });
    test('invalid prefix', () {
      final result = validBech32(
          bech32: 'dude_test1234567890acdefghjklmnpqrstuvwxyz',
          hrpPrefixes: ['addr_test', 'addr']);
      expect(result.isErr(), isTrue);
      print(result.unwrapErr());
    });
    test('missing 1 seperator', () {
      final result = validBech32(
          bech32: 'addr234567890acdefghjklmnpqrstuvwxyz',
          hrpPrefixes: ['addr_test', 'addr']);
      expect(result.isErr(), isTrue);
      print(result.unwrapErr());
    });
  });
}
