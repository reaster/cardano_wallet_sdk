// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'blockfrost_test_auth_interceptor.dart';
import 'package:oxidized/oxidized.dart';
import 'package:test/test.dart';

///
/// insure documented tests are actually working code.
///
void main() {
  final interceptor = BlockfrostTestAuthInterceptor();
  final blockfrostKey = interceptor.apiKey;
  final mnemonic =
      "rude stadium move tumble spice vocal undo butter cargo win valid session question walk indoor nothing wagon column artefact monster fold gallery receive just"
          .split(' ');

  group('wallet management -', () {
    test('Create a read-only wallet using a staking address', () async {
      final bechAddr =
          'stake_test1uqevw2xnsc0pvn9t9r9c7qryfqfeerchgrlm3ea2nefr9hqp8n5xl';
      var address = ShelleyAddress.fromBech32(bechAddr);
      final builder = WalletBuilder()
        ..networkId = NetworkId.testnet
        ..testnetAdapterKey = interceptor.apiKey
        ..stakeAddress = address;
      Result<ReadOnlyWallet, String> result = builder.readOnlyBuild();
      result.when(
        ok: (w) => print("${w.walletName}: ${w.balance}"),
        err: (err) => print("Error: ${err}"),
      );
    });
    test('Restore existing wallet using 24 word mnemonic', () async {
      //List<String> mnemonic = 'rude stadium move...gallery receive just'.split(' ');
      final builder = WalletBuilder()
        ..networkId = NetworkId.testnet
        ..testnetAdapterKey = blockfrostKey
        ..mnemonic = mnemonic;
      Result<Wallet, String> result = await builder.buildAndSync();
      if (result.isOk()) {
        var w = result.unwrap();
        print("${w.walletName}: ${w.balance}");
      }
    });
    test('Update existing wallet', () async {
      final builder = WalletBuilder()
        ..networkId = NetworkId.testnet
        ..testnetAdapterKey = blockfrostKey
        ..mnemonic = mnemonic;
      Result<Wallet, String> result = builder.build();
      Wallet wallet = result.unwrap();
      Coin oldBalance = wallet.balance;
      var result2 = await wallet.update();
      result2.when(
        ok: (_) => print("old:$oldBalance ADA, new: ${wallet.balance} ADA"),
        err: (err) => print("Error: ${err}"),
      );
    });
    test('Create a new 24 word mnemonic', () {
      List<String> mnemonic = WalletBuilder().generateNewMnemonic();
      print("mnemonic: ${mnemonic.join(' ')}");
    });
  });
}
