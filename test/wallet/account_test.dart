// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
// import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32_ed25519/bip32_ed25519.dart';
import 'package:pinenacl/key_derivation.dart';
import 'package:hex/hex.dart';
import 'package:test/test.dart';

void main() {
  /// Extended Public key size in bytes
  // const xpub_size = 64;
  const publicKeySize = 32;
  // const choin_code_size = 32;
  List<int> tolist(String csv) =>
      csv.split(',').map((n) => int.parse(n)).toList();

  group('Account -', () {
    final mnemonic =
        "damp wish scrub sentence vibrant gauge tumble raven game extend winner acid side amused vote edge affair buzz hospital slogan patient drum day vital"
            .split(' ');
    final seed = mnemonicWordsToEntropyBytes(
        mnemonic: mnemonic, loadWordsFunction: loadEnglishMnemonicWords);
    final seedHex = mnemonicToEntropyHex(
        mnemonic: mnemonic, loadWordsFunction: loadEnglishMnemonicWords);
    final acct0Xsk = Bip32SigningKey.decode(
        'acct_xsk1grmww8c9yftkd6nlmuh7wypx46duh8az7sxyg88fr4k3qpc33azk8gc5ntllturxzee5gj2zd5dy48f0ehp6lqudkwvacxjznz8j0mzd2ad0t2fmmaystgms97k7maz3afvy0ywjxwk7jzt96cyt43tnqsr5dmk0',
        coder: Bech32Coder(hrp: 'acct_xsk'));

    test('MultiAccountWallet constructors', () {
      final w1 = MultiAccountWallet.entropyHex(seedHex);
      expect(w1.derivation.root is Bip32SigningKey, isTrue);
      // final Bip32SigningKey key1 = entropyToMasterKey(seed);
      // expect(w1.derivation.root, equals(key1));
      // final w2 = MultiAccountWallet.mnemonic(mnemonic);
      // final Bip32SigningKey key2 = mnemonicToMasterKey(mnemonic);
      // expect(w2.derivation.root, equals(key2));
      // expect(w2.derivation.root, equals(w1.derivation.root));
      // final root_xsk = key.encode(Bech32Coder(hrp: 'root_xsk'));
      // expect(root_xsk, equals(w2.derivation.root));
    });

    test('validate mainnet Account', () {
      final expectedAccount0Xsk = tolist(
          '64,246,231,31,5,34,87,102,234,127,223,47,231,16,38,174,155,203,159,162,244,12,68,28,233,29,109,16,7,17,143,69,99,163,20,154,255,245,240,102,22,115,68,73,66,109,26,74,157,47,205,195,175,131,141,179,153,220,26,66,152,143,39,236,77,87,90,245,169,59,223,73,5,163,112,47,173,237,244,81,234,88,71,145,210,51,173,233,9,101,214,8,186,197,115,4');
      final expectedSpend0Xsk = tolist(
          '16,41,227,180,98,205,86,19,164,21,138,56,61,41,138,149,60,198,210,108,65,244,169,96,247,21,18,90,21,17,143,69,194,70,255,246,50,124,72,102,231,105,50,116,96,25,83,94,245,96,206,37,0,21,11,224,246,1,224,54,119,47,202,15,23,236,32,214,162,3,215,59,218,48,86,59,210,15,41,200,58,115,47,149,36,193,106,147,177,129,121,138,250,247,136,13');
      final expectedStake0Xsk = tolist(
          '40,184,124,185,16,22,113,157,33,204,24,190,209,97,23,160,125,79,145,114,178,38,114,18,12,243,32,248,12,17,143,69,125,104,75,46,40,163,136,6,34,32,65,216,70,97,70,131,241,143,123,118,111,164,172,17,148,250,121,254,98,152,125,49,87,224,30,183,139,184,57,170,146,167,191,86,138,123,240,59,3,81,148,105,27,177,61,94,63,155,51,150,90,200,13,150');
      const expectedSpend0Bech32 =
          'addr1qyy6nhfyks7wdu3dudslys37v252w2nwhv0fw2nfawemmn8k8ttq8f3gag0h89aepvx3xf69g0l9pf80tqv7cve0l33sdn8p3d';
      const expectedTestnetSpend0Bech32 =
          'addr_test1qqy6nhfyks7wdu3dudslys37v252w2nwhv0fw2nfawemmn8k8ttq8f3gag0h89aepvx3xf69g0l9pf80tqv7cve0l33sw96paj';

      final account = Account(accountSigningKey: acct0Xsk);
      expect(account.accountSigningKey, expectedAccount0Xsk);
      final derAcct0 = IcarusKeyDerivation(account.accountSigningKey);
      final addr0Key = derAcct0.forPath("m/0/0") as Bip32SigningKey;
      expect(addr0Key, expectedSpend0Xsk);
      expect(account.basePrivateKey(), expectedSpend0Xsk);
      expect(account.stakePrivateKey, expectedStake0Xsk);
      expect(account.baseAddress().toBech32(), expectedSpend0Bech32);
    });
    test('validate testnet Account', () {
      final xsk = Bip32SigningKey(Uint8List.fromList(tolist(
          '64,246,231,31,5,34,87,102,234,127,223,47,231,16,38,174,155,203,159,162,244,12,68,28,233,29,109,16,7,17,143,69,99,163,20,154,255,245,240,102,22,115,68,73,66,109,26,74,157,47,205,195,175,131,141,179,153,220,26,66,152,143,39,236,77,87,90,245,169,59,223,73,5,163,112,47,173,237,244,81,234,88,71,145,210,51,173,233,9,101,214,8,186,197,115,4')));
      const expectedSpend0 =
          'addr_test1qqy6nhfyks7wdu3dudslys37v252w2nwhv0fw2nfawemmn8k8ttq8f3gag0h89aepvx3xf69g0l9pf80tqv7cve0l33sw96paj';
      final account =
          Account(accountSigningKey: xsk, network: NetworkId.testnet);
      expect(account.baseAddress().toBech32(), expectedSpend0);
    });

    test('validate MultiAccountWallet', () {
      final entropyHex =
          '4e828f9a67ddcff0e6391ad4f26ddb7579f59ba14b6dd4baf63dcfdb9d2420da';
      final expectedSpend0Xsk = tolist(
          '16,41,227,180,98,205,86,19,164,21,138,56,61,41,138,149,60,198,210,108,65,244,169,96,247,21,18,90,21,17,143,69,194,70,255,246,50,124,72,102,231,105,50,116,96,25,83,94,245,96,206,37,0,21,11,224,246,1,224,54,119,47,202,15,23,236,32,214,162,3,215,59,218,48,86,59,210,15,41,200,58,115,47,149,36,193,106,147,177,129,121,138,250,247,136,13');

      final icarus = IcarusKeyDerivation.entropyHex(entropyHex);
      final acct0Xsk = icarus.forPath("m/1852'/1815'/0'") as Bip32SigningKey;
      final wallet = MultiAccountWallet.entropyHex(entropyHex);
      expect(wallet.derivation.root, icarus.root);
      Account acct0 = wallet.account(index: 0);
      expect(acct0.derivation.root, acct0Xsk);
      expect(acct0.basePrivateKey(), expectedSpend0Xsk);
    });

    test('account0 mainnet', () {
      final stakeXskCoder = Bech32Coder(hrp: 'stake_xsk');
      final acctXskCoder = Bech32Coder(hrp: 'acct_xsk');
      final rootXskCoder = Bech32Coder(hrp: 'root_xsk');
      final mnemonicBob =
          'army bid park alter aunt click border awake happy sport addict heavy robot change artist sniff height general dust fiber salon fan snack wheat'
              .split(' ');
      final addr9 =
          'addr_test1qpgtfaalupum9evdwqleqcp5rhac8nty720mahpse4pc35p7v8d0ph6h78xxlkc4e6nxz5xk873akuwfp78nx7tqysas3zacqu';
      final Bip32SigningKey expectedMasterKey =
          mnemonicToMasterKey(mnemonicBob);

      // HdWallet derivation
      final hdWallet = HdWallet.fromMnemonic(mnemonic: mnemonicBob.split(' '));
      //expect(hdWallet.rootSigningKey, equals(expectedMasterKey));
      final Bip32KeyPair spend9 = hdWallet.deriveAddressKeys(index: 9);
      final Bip32KeyPair stake = hdWallet.deriveAddressKeys(role: stakingRole);
      final addr = ShelleyAddress.toBaseAddress(
        spend: spend9.verifyKey!,
        stake: stake.verifyKey!,
        networkId: NetworkId.testnet,
      );
      // print(acctXskCoder.encode(spend.signingKey!));
      // print(stakeXskCoder.encode(stake.signingKey!));
      //expect(addr.toBech32(), addr9);

      // manual master
      final _master = mnemonicWordsToEntropyBytes(
          mnemonic: mnemonicBob, loadWordsFunction: loadEnglishMnemonicWords);
      // final Bip32SigningKey _root = entropyToMasterKey(_master);
      // expect(_root, equals(expectedMasterKey));

      // MultiAccountWallet / Account derivation
      final wallet =
          MultiAccountWallet.mnemonic(mnemonicBob, network: NetworkId.testnet);
      print(rootXskCoder.encode(hdWallet.rootSigningKey));

      expect(wallet.derivation.root, equals(expectedMasterKey));
      print(rootXskCoder.encode(wallet.derivation.root));

      Account account = wallet.account();
      final expectedAcct0PvtKey =
          ShelleyKeyDerivation(expectedMasterKey).fromPath("m/1852'/1815'/0'");
      expect(account.accountSigningKey, equals(expectedAcct0PvtKey));
      final md = ShelleyKeyDerivation(expectedAcct0PvtKey);
      final _key9 = md.fromPath("m/0/9") as Bip32SigningKey;
      //expect(_key9, equals(spend9.signingKey!));

      final _spendPvtKey = account.basePrivateKey(index: 9);
      expect(_spendPvtKey, spend9.signingKey!);

      print(acctXskCoder.encode(_spendPvtKey));

      final _stakePvtKey = account.stakePrivateKey;
      print(stakeXskCoder.encode(_stakePvtKey));
      final _addr9 = account.baseAddress(index: 9);
      //expect(_addr9.toBech32(), equals(addr9));

      // const changeX =
      //     'addr_test1qpxnznd2j892qln9gr7x7yns9xf6uz4k4ldhv96makgscpe7v8d0ph6h78xxlkc4e6nxz5xk873akuwfp78nx7tqysasxy9yrk';
      // final baseAddress = account.baseAddress();
      // expect(
      //     baseAddress.toBech32(),
      //     equals(
      //         'addr_test1qqc5rudyv60ph4mq8c75zquq3mycx759nvvae7pcr4ha2t37v8d0ph6h78xxlkc4e6nxz5xk873akuwfp78nx7tqysas2f3nj9'));

      // final rewardAddress = account.stakeAddress;
      // expect(rewardAddress.networkId, equals(NetworkId.mainnet));
      // expect(rewardAddress.addressType, equals(AddressType.reward));
      // expect(rewardAddress.hrp, equals('stake'));
      // expect(
      //     rewardAddress.toBech32(),
      //     equals(
      //         'stake1u9xeg0r67z4wca682l28ghg69jxaxgswdmpvnher7at697quawequ'));
    });
    // test('account1 mainnet', () {
    //   Account account = wallet.account(index: 1);
    //   final address = account.stakeAddress;
    //   expect(address.networkId, equals(NetworkId.mainnet));
    //   expect(address.addressType, equals(AddressType.reward));
    //   expect(address.hrp, equals('stake'));
    //   expect(
    //       address.toBech32(),
    //       equals(
    //           'stake1u9xcv6e9z75qg8pkkzwfyd6aq2t50hgkymv9jq5q5kpj9lcthljzu'));
    // });

    // @Test
    // public void testRewardAddress_whenMainnet_Account2() {
    //     String mnemonic = "damp wish scrub sentence vibrant gauge tumble raven game extend winner acid side amused vote edge affair buzz hospital slogan patient drum day vital";

    //     DerivationChain derivationPath = DerivationChain.createExternalAddressDerivationChain();
    //     derivationPath.getAccount().setValue(2);

    //     Account account = new Account(Networks.mainnet(), mnemonic, derivationPath);

    //     Address address = new Address(account.stakeAddress());

    //     assertThat(address.getAddressType()).isEqualTo(AddressType.Reward);
    //     assertThat(address.getNetwork()).isEqualTo(Networks.mainnet());
    //     assertThat(address.getPrefix()).isEqualTo("stake");
    //     assertThat(address.getAddress().toString()).isEqualTo("stake1uyzprh5g4anfumuslz52r98g8vx4lrnu6grt9m329y8hwxq9w8v34");
    // }

    // @Test
    // public void testRewardAddress_whenTestnet() {
    //     String mnemonic = "damp wish scrub sentence vibrant gauge tumble raven game extend winner acid side amused vote edge affair buzz hospital slogan patient drum day vital";
    //     Account account = new Account(Networks.testnet(), mnemonic);

    //     Address address = new Address(account.stakeAddress());

    //     assertThat(address.getAddressType()).isEqualTo(AddressType.Reward);
    //     assertThat(address.getNetwork()).isEqualTo(Networks.testnet());
    //     assertThat(address.getPrefix()).isEqualTo("stake_test");
    // }
  });

  group('HdWallet -', () {
    //   test('private/public key and address generation', () {
    //     const testEntropy =
    //         '4e828f9a67ddcff0e6391ad4f26ddb7579f59ba14b6dd4baf63dcfdb9d2420da';
    //     final hdWallet = HdWallet.fromHexEntropy(testEntropy);
    //     expect(hdWallet.rootSigningKey, excpectedXskBip32Bytes,
    //         reason: 'root private/signing key');
    //     expect(hdWallet.rootVerifyKey, expectedXvkBip32Bytes,
    //         reason: 'root public/verify key');
    //     final Bip32KeyPair spendAddress0Pair =
    //         hdWallet.deriveAddressKeys(index: 0);
    //     expect(spendAddress0Pair.signingKey, expectedSpend0Xsk);
    //     expect(spendAddress0Pair.verifyKey, expectedSpend0Xvk);
    //     final Bip32KeyPair stakeAddress0Pair =
    //         hdWallet.deriveAddressKeys(role: stakingRole, index: 0);
    //     expect(stakeAddress0Pair.signingKey, expectedStake0Xsk);
    //     expect(stakeAddress0Pair.verifyKey, expectedStake0Xvk);
    //     final addr0 = hdWallet.toBaseAddress(
    //         networkId: NetworkId.mainnet,
    //         spend: spendAddress0Pair.verifyKey!,
    //         stake: stakeAddress0Pair.verifyKey!);
    //     // print(addr0.join(','));
    //     expect(addr0.toBech32(), expectedSpend0Bech32);
    //     final addrTest0 = hdWallet.toBaseAddress(
    //         spend: spendAddress0Pair.verifyKey!,
    //         stake: stakeAddress0Pair.verifyKey!);
    //     expect(addrTest0.toBech32(), expectedTestnetSpend0Bech32);
    //   });

    // test('bip32_12_reward address', () {
    //   //data taken from rust address.rs code
    //   const mnemonic =
    //       'test walk nut penalty hip pave soap entry language right filter choice';
    //   final hdWallet = HdWallet.fromMnemonic(mnemonic);
    //   final Bip32KeyPair stakeAddress0Pair =
    //       hdWallet.deriveAddressKeys(role: stakingRole);
    //   final stake = hdWallet.toRewardAddress(
    //       networkId: NetworkId.mainnet, spend: stakeAddress0Pair.verifyKey!);
    //   expect(stake.toBech32(),
    //       'stake1uyevw2xnsc0pvn9t9r9c7qryfqfeerchgrlm3ea2nefr9hqxdekzz');
    //   final stakeTest =
    //       hdWallet.toRewardAddress(spend: stakeAddress0Pair.verifyKey!);
    //   expect(stakeTest.toBech32(),
    //       'stake_test1uqevw2xnsc0pvn9t9r9c7qryfqfeerchgrlm3ea2nefr9hqp8n5xl');
    // });
  // }, skip: "TODO");
}
