// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:test/test.dart';
import 'mock_wallet_2.dart';
import 'package:hex/hex.dart';
import 'package:bip32_ed25519/bip32_ed25519.dart';

void main() {
  final formatter = AdaFormattter.compactCurrency();
  final mockAdapter = BlockfrostBlockchainAdapter(
      blockfrost: buildMockBlockfrostWallet2(),
      networkId: NetworkId.testnet,
      projectId: 'mock-id');
  final walletBuilder = WalletBuilder()
    ..networkId = NetworkId.testnet
    ..blockchainAdapter = mockAdapter;
  const wallet1 =
      'stake_test1uqnf58xmqyqvxf93d3d92kav53d0zgyc6zlt927zpqy2v9cyvwl7a';
  const wallet2 =
      'stake_test1uz425a6u2me7xav82g3frk2nmxhdujtfhmf5l275dr4a5jc3urkeg';
  final mnemonic1 =
      'army bid park alter aunt click border awake happy sport addict heavy robot change artist sniff height general dust fiber salon fan snack wheat'
          .split(' ');
  final mnemonic2 =
      'traffic body morning syrup anger deny grace sugar avoid outdoor almost radar luxury tail zone cram unveil pluck door quarter foam where vacant ceiling'
          .split(' ');
  final rootXsk1 =
      'root_xsk1sqvjwjq45uw5djvkyvte3cwgrvdw00k4nfln37uptudfvhspef0wpl3w6js7zs74whftqt9q0d94nhlf8ja7r59p78dz3zkw8a3qj94y8xlnuzssd4r6r0ylgsnvwc2x263k7jphrzr68nlnjfpasjr43y0kt72e';
  final rootXsk2 =
      'root_xsk1dpgkcpr0c9mscnakxxlm0rfsyeyvxn53vyvatj00wkrgrn99v3pw8sghzn8vv7dcrjnj6gp56ueqdp5m9hcx333wwr6eyh869r660lqux9390ep008uahuxp7lz3wft6j8c5g75x9w26xvk6kjmvyc6u650a4vxz';

  group('WalletBuilder -', () {
    test('create testnet read-only wallets', () async {
      final r1 = await walletBuilder.readOnlyBuild();
      expect(r1.isErr(), isTrue, reason: "no stake address");
      walletBuilder.stakeAddress = ShelleyAddress.fromBech32(wallet1);
      final r2 = await walletBuilder.readOnlyBuild();
      expect(r2.isOk(), isTrue, reason: "stake address supplied");
      final r3 = await walletBuilder.readOnlyBuild();
      expect(r3.isErr(), isTrue,
          reason:
              "reset cleared previous wallet properties - no stake address");
      walletBuilder.stakeAddress = ShelleyAddress.fromBech32(wallet2);
      final r4 = await walletBuilder.readOnlyBuild();
      expect(r4.isOk(), isTrue, reason: "new stake address supplied");
      expect(r2.unwrap().walletId, isNot(r4.unwrap().walletId),
          reason: "wallet ids are unique");
      expect(r2.unwrap().stakeAddress, isNot(r4.unwrap().stakeAddress),
          reason: "wallet stakeAddresses are unique");
      expect(r2.unwrap().walletName, isNot(r4.unwrap().walletName),
          reason: "wallet names are unique");
    }); //, skip: ''
    test('create testnet transactional wallets', () async {
      final r1 = await walletBuilder.build();
      expect(r1.isErr(), isTrue, reason: "no private key or mnemonic");
      walletBuilder.mnemonic = mnemonic1;
      final r2 = await walletBuilder.build();
      expect(r2.isOk(), isTrue, reason: "stake mnemonic supplied");
      final r3 = await walletBuilder.build();
      expect(r3.isErr(), isTrue,
          reason:
              "reset cleared previous wallet properties - no private key or mnemonic");
      walletBuilder.mnemonic = mnemonic2;
      final r4 = await walletBuilder.build();
      expect(r4.isOk(), isTrue, reason: "new mnemonic supplied");
      walletBuilder.rootSigningKey =
          Bip32SigningKey.decode(rootXsk1, coder: rootXskCoder);
      final r5 = await walletBuilder.build();
      expect(r5.isOk(), isTrue, reason: "root signing key supplied");
      walletBuilder.rootSigningKey =
          Bip32SigningKey.decode(rootXsk2, coder: rootXskCoder);
      final r6 = await walletBuilder.build();
      expect(r6.isOk(), isTrue, reason: "root signing key supplied");
      expect(r5.unwrap().walletId, isNot(r6.unwrap().walletId),
          reason: "wallet ids are unique");
      expect(r5.unwrap().stakeAddress, isNot(r6.unwrap().stakeAddress),
          reason: "wallet stakeAddresses are unique");
      expect(r5.unwrap().walletName, isNot(r6.unwrap().walletName),
          reason: "wallet names are unique");
      expect(r5.unwrap().rootKeyPair.signingKey,
          isNot(r6.unwrap().rootKeyPair.signingKey),
          reason: "wallet keys are unique");
    }); //, skip: ''
  });
}

final rootXskCoder = Bech32Coder(hrp: 'root_xsk');

String generateRootXskBip32() {
  final rootSigningKey =
      HdWallet.fromMnemonic(WalletBuilder.generateNewMnemonic().join(' '))
          .rootSigningKey;
  final bip32 = rootXskCoder.encode(rootSigningKey);
  return bip32;
}
