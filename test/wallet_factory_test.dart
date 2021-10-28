// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/src/address/shelley_address.dart';
import 'package:cardano_wallet_sdk/src/network/network_id.dart';
import 'package:cardano_wallet_sdk/src/wallet/impl/wallet_factory_impl.dart';
import 'package:cardano_wallet_sdk/src/wallet/read_only_wallet.dart';
import 'package:cardano_wallet_sdk/src/wallet/wallet.dart';
import 'package:cardano_wallet_sdk/src/util/ada_types.dart';
import 'package:oxidized/oxidized.dart';
import 'package:test/test.dart';

import 'my_api_key_auth.dart';

///
/// insure documented tests are actually working code.
///
void main() {
  final testnet = NetworkId.testnet;
  final interceptor = MyApiKeyAuthInterceptor();
  final walletFactory = ShelleyWalletFactory(authInterceptor: interceptor, networkId: testnet);
  final mnemonic =
      "rude stadium move tumble spice vocal undo butter cargo win valid session question walk indoor nothing wagon column artefact monster fold gallery receive just"
          .split(' ');

  group('wallet management -', () {
    test('walletFactory from policy-id', () {
      String myPolicyId = interceptor.apiKey;
      final walletFactory = ShelleyWalletFactory.fromKey(key: myPolicyId, networkId: testnet);
      expect(walletFactory, isNotNull);
    });
    test('Create a read-only wallet using a staking address', () async {
      final bechAddr = 'stake_test1uqnf58xmqyqvxf93d3d92kav53d0zgyc6zlt927zpqy2v9cyvwl7a';
      var address = ShelleyAddress.fromBech32(bechAddr);
      Result<ReadOnlyWallet, String> result = await walletFactory.createReadOnlyWallet(stakeAddress: address);
      expect(result.isOk(), isTrue);
    });
    test('Restore existing wallet using 24 word mnemonic', () async {
      Result<Wallet, String> result = await walletFactory.createWalletFromMnemonic(mnemonic: mnemonic);
      if (result.isErr()) {
        print(result.unwrapErr());
      } else {
        expect(result.isOk(), isTrue);
      }
    });
    test('Update existing wallet', () async {
      var stakeAddress = ShelleyAddress.fromBech32('stake_test1uqnf58xmqyqvxf93d3d92kav53d0zgyc6zlt927zpqy2v9cyvwl7a');
      var result = await walletFactory.createReadOnlyWallet(stakeAddress: stakeAddress, load: false);
      ReadOnlyWallet wallet = result.unwrap();
      Coin old = wallet.balance;
      expect(old, 0, reason: 'wallet not synced with blockchain');
      var result2 = await walletFactory.updateWallet(wallet: wallet);
      expect(result2.isOk(), isTrue);
      expect(wallet.balance, greaterThan(0));
    });
    test('Create a new 24 word mnemonic', () {
      List<String> mnemonic = walletFactory.generateNewMnemonic();
      expect(mnemonic.length, 24);
    });
  });
}
