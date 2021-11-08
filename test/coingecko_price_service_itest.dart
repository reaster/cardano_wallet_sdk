// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

@Tags(['coingecko'])

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:test/test.dart';

void main() {
  PriceService service = CoingeckoPriceService();
  group('test CoingeckoPriceService', () {
    // Future<Result<double, String>> currentPrice({String from, String to});
    test(
        'test currentPrice - calls https://api.coingecko.com/api/v3/simple/price?ids=cardano&vs_currencies=USD',
        () async {
      final result1 = await service.currentPrice(from: 'ada', to: 'usd');
      result1.when(
          ok: (price) {
            print(price);
            expect(price.value, isNotNull);
          },
          err: (err) => print(err));
      final result2 = await service.currentPrice(from: 'nexo', to: 'usd');
      result2.when(
          ok: (price) {
            print(price);
            expect(price.value, isNotNull);
          },
          err: (err) => print(err));
    });

    test('test currentPrice with Tron witch is not in the _defaultSymbolToId',
        () async {
      final result1 = await service.currentPrice(from: 'trx', to: 'usd');
      result1.when(
          ok: (price) {
            print(price);
            expect(price.value, isNotNull);
          },
          err: (err) => print(err));
    }, skip: 'reduce network usage');

    // Future<Result<bool, String>> ping();
    test('test ping - calls https://api.coingecko.com/api/v3/ping', () async {
      final result = await service.ping();
      result.when(
          ok: (success) => expect(success, isTrue), err: (err) => print(err));
    }, skip: 'api is broken');

    // Future<Result<Map<String, String>, String>> list();
    test(
        'test supported coins list - calls https://api.coingecko.com/api/v3/coins/list',
        () async {
      final result = await service.list();
      result.when(
          ok: (map) {
            print("cardano: ${map['ada']}");
            print("bitcoin: ${map['btc']}");
            expect(map['ada'], isNotNull);
          },
          err: (err) => print(err));
    });
  });
}
