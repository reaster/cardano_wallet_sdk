// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'blockfrost_test_auth_interceptor.dart';
import 'package:test/test.dart';
import 'package:oxidized/oxidized.dart';

void main() {
  final wallet1 = 'stake_test1uqnf58xmqyqvxf93d3d92kav53d0zgyc6zlt927zpqy2v9cyvwl7a';
  final wallet2 = 'stake_test1uz425a6u2me7xav82g3frk2nmxhdujtfhmf5l275dr4a5jc3urkeg';
  final wallet3 = 'stake_test1upnk3u6wd65w7na3rkamznyzjspv7kgu7xm9j8w5m00xcls39m99d';
  final wallet4 = 'stake_test1uqhwfumjye2t99ekdq02njm0wsdz84pmd0h2cxrg4napshs0uedxa';
  final interceptor = BlockfrostTestAuthInterceptor();
  final builder = WalletBuilder()
    ..networkId = NetworkId.testnet
    ..testnetAdapterKey = interceptor.apiKey;

  group('PublicWallet -', () {
    test('test create testnet wallet 1', () async {
      await testWalletFromBuilder(builder
        ..walletName = 'Wallet 1'
        ..stakeAddress = ShelleyAddress.fromBech32(wallet1));
    });
    test('create testnet wallet 2', () async {
      await testWalletFromBuilder(builder
        ..walletName = 'Wallet 2'
        ..stakeAddress = ShelleyAddress.fromBech32(wallet2));
    });
    test('create testnet wallet 3', () async {
      await testWalletFromBuilder(builder
        ..walletName = 'Wallet 3'
        ..stakeAddress = ShelleyAddress.fromBech32(wallet3));
    });
    test('create testnet wallet 4', () async {
      await testWalletFromBuilder(builder
        ..walletName = 'Wallet 4'
        ..stakeAddress = ShelleyAddress.fromBech32(wallet4));
    });
    //   test('missing account', () async {
    //     final result = await testWallet(
    //         stakeAddress: 'stake1uy88uenysztnswv6u3cssgpamztc25q5wea703rnp50s4qq0ddctn',
    //         walletFactory: walletFactory,
    //         walletName: 'MIA');
    //     expect(true, result.isErr());
    //     print("ERROR: ${result.unwrapErr()}");
    //   });
    //   test('create mainnet wallet 8', () async {
    //     final wallet8 = 'stake1uy88uenysztnswv6u3cssgpamztc25q5wea703rnp50s4qq0ddctn';
    //     await testWallet(stakeAddress: wallet8, walletFactory: walletFactory, walletName: 'Fat Cat 8');
    //   }, skip: 'mainnet auth not working');
  });
}

final formatter = AdaFormattter.compactCurrency();

Future<Result<ReadOnlyWallet, String>> testWalletFromBuilder(WalletBuilder builder) async {
  final result = await builder.readOnlyBuildAndSync();
  bool error = false;
  result.when(
    ok: (wallet) {
      print("Wallet(name: ${wallet.walletName}, balance: ${formatter.format(wallet.balance)})");
      wallet.addresses.forEach((addr) {
        print(addr.toBech32());
      });
      wallet.transactions.forEach((tx) {
        print("$tx");
      });
      wallet.currencies.forEach((key, value) {
        print("$key: ${key == lovelaceHex ? formatter.format(value) : value}");
      });
      wallet.stakeAccounts.forEach((acct) {
        final ticker = acct.poolMetadata?.ticker ?? acct.poolMetadata?.name ?? acct.poolId!;
        acct.rewards.forEach((reward) {
          print("epoch: ${reward.epoch}, value: ${formatter.format(reward.amount)}, ticker: $ticker");
        });
      });
      final int calculatSum = wallet.calculatedBalance; //TODO figure out the math
      expect(wallet.balance, equals(calculatSum));
    },
    err: (err) {
      print(err);
      error = true;
      expect(error, isFalse, reason: err);
      return Err(err);
    },
  );
  if (error) {
    return Err(result.unwrapErr());
  }
  final update = await result.unwrap().update();
  expect(false, update.unwrap());
  return Ok(result.unwrap());
}
