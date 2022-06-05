// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
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

  group('Daedalus -', () {
    test('Account - validate testnet walley wallet', () {
      //walley
      final mnemonic =
          'alpha desert more credit sad balance receive sand someone correct used castle present bar shop borrow inmate estate year flip theory recycle measure silk'
              .split(' ');
      final account = MultiAccountWallet.mnemonic(
              mnemonic: mnemonic, network: NetworkId.testnet)
          .account();
      const acct0xvk =
          'acct_xvk1xfehjaqtvn0vdjqrrfwlgvfk8qedv4fus04thny96lj6rhc2tphsx0wlcdaehpjzjfyj7uref4uqlacrtft55u9ll6eal4h4ac75yzqdnqwtf';
      final acctVerifyKey =
          acctXvkCoder.encode(account.accountSigningKey.publicKey);
      expect(acctVerifyKey, equals(acct0xvk),
          reason: 'is default account (#0) verification key');
      const spendAddr0 =
          'addr_test1qr94pw040yeq5x75g38jnsjg95rv6xy4jyttedukatlpd2424kyuyck0xp0a7n7rah0gxj5mq3zdrc6xnaqph967c2kqja24jq';
      final _spendAddr0 = account.baseAddress(index: 0).toBech32();
      expect(_spendAddr0, equals(spendAddr0),
          reason: 'acct 0, spend address 0');
      const changeAddr0 =
          'addr_test1qz52gz9hwr8wxuy5t5sz7jww9eqdnejuh30wqufkemmd20924kyuyck0xp0a7n7rah0gxj5mq3zdrc6xnaqph967c2kqurare7';
      final _changeAddr0 = account.changeAddress(index: 0).toBech32();
      expect(_changeAddr0, equals(changeAddr0),
          reason: 'acct 0, change address 0');
    });
    test('Account - validate testnet wallet 2', () {
      final mnemonic =
          'chest task gorilla dog maximum forget shove tag project language head try romance memory actress raven resist aisle grunt check immense wrap enlist napkin'
              .split(' ');
      const stakeAddr =
          'stake_test1uz425a6u2me7xav82g3frk2nmxhdujtfhmf5l275dr4a5jc3urkeg';
      const addr0 =
          'addr_test1qputeu63ld6c0cd526w90ry2r9upc5ac8y3zetcg85xs5l924fm4c4hnud6cw53zj8v48kdwmeykn0knf74ag68tmf9sutu8kq';
      const addr1 =
          'addr_test1qrektsyevyxxqpytjwnwxvmvrj8xgzv4qsuzf57qkp432ma24fm4c4hnud6cw53zj8v48kdwmeykn0knf74ag68tmf9sk7kesv';
      const addrChange1 =
          'addr_test1qpcdsfzewqkl3w5kxk553hts5lvw9tdjda9nzt069gqmyud24fm4c4hnud6cw53zj8v48kdwmeykn0knf74ag68tmf9s89kyst';
      final account = MultiAccountWallet.mnemonic(
              mnemonic: mnemonic, network: NetworkId.testnet)
          .account();
      final _addr0 = account.baseAddress(index: 0).toBech32();
      expect(_addr0, equals(addr0), reason: 'acct 0, address 0');
      final _addr1 = account.baseAddress(index: 1).toBech32();
      expect(_addr1, equals(addr1), reason: 'acct 0, address 1');
      final _addrChange1 = account.changeAddress(index: 1).toBech32();
      expect(_addrChange1, equals(addrChange1),
          reason: 'acct 0, change address 1');
      final _stakeAddr = account.stakeAddress.toBech32();
      expect(stakeAddr, equals(_stakeAddr), reason: 'stake address');
    });
  });
  group('Account -', () {
    final mnemonic =
        "damp wish scrub sentence vibrant gauge tumble raven game extend winner acid side amused vote edge affair buzz hospital slogan patient drum day vital"
            .split(' ');
    final seed = mnemonicToEntropy(
        mnemonic: mnemonic, loadWordsFunction: loadEnglishMnemonicWords);
    final seedHex = mnemonicToEntropyHex(
        mnemonic: mnemonic, loadWordsFunction: loadEnglishMnemonicWords);
    final acct0Xsk = Bip32SigningKey.decode(
        'acct_xsk1grmww8c9yftkd6nlmuh7wypx46duh8az7sxyg88fr4k3qpc33azk8gc5ntllturxzee5gj2zd5dy48f0ehp6lqudkwvacxjznz8j0mzd2ad0t2fmmaystgms97k7maz3afvy0ywjxwk7jzt96cyt43tnqsr5dmk0',
        coder: acctXskCoder);

    test('MultiAccountWallet constructors', () {
      final w1 = MultiAccountWallet.entropyHex(seedHex);
      expect(w1.derivation.root is Bip32SigningKey, isTrue);
      final Bip32SigningKey key1 = icarusGenerateMasterKey(seed);
      expect(w1.derivation.root, equals(key1));
      final w2 = MultiAccountWallet.mnemonic(
          mnemonic: mnemonic, loadWordsFunction: loadEnglishMnemonicWords);
      final entropy = mnemonicToEntropy(
          mnemonic: mnemonic, loadWordsFunction: loadEnglishMnemonicWords);
      final Bip32SigningKey key2 = icarusGenerateMasterKey(entropy);
      expect(w2.derivation.root, equals(key2));
      expect(w2.derivation.root, equals(w1.derivation.root));
      final root_xsk = key1.encode(rootXskCoder);
      expect(key1, equals(w2.derivation.root));
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
      final mnemonicBob =
          'army bid park alter aunt click border awake happy sport addict heavy robot change artist sniff height general dust fiber salon fan snack wheat'
              .split(' ');
      final addr9 =
          'addr_test1qpgtfaalupum9evdwqleqcp5rhac8nty720mahpse4pc35p7v8d0ph6h78xxlkc4e6nxz5xk873akuwfp78nx7tqysas3zacqu';
      final entropy = mnemonicToEntropy(
          mnemonic: mnemonicBob, loadWordsFunction: loadEnglishMnemonicWords);
      final Bip32SigningKey expectedMasterKey =
          icarusGenerateMasterKey(entropy);

      // manual master
      final _master = mnemonicToEntropy(
          mnemonic: mnemonicBob, loadWordsFunction: loadEnglishMnemonicWords);
      final Bip32SigningKey _root = icarusGenerateMasterKey(_master);
      expect(_root, equals(expectedMasterKey));

      // MultiAccountWallet / Account derivation
      final wallet = MultiAccountWallet.mnemonic(
          mnemonic: mnemonicBob,
          loadWordsFunction: loadEnglishMnemonicWords,
          network: NetworkId.testnet);
      // print(rootXskCoder.encode(hdWallet.rootSigningKey));

      expect(wallet.derivation.root, equals(expectedMasterKey));
      // print(rootXskCoder.encode(wallet.derivation.root));

      Account account = wallet.account();
      final expectedAcct0PvtKey =
          ShelleyKeyDerivation(expectedMasterKey).fromPath("m/1852'/1815'/0'");
      expect(account.accountSigningKey, equals(expectedAcct0PvtKey));
      final md = ShelleyKeyDerivation(expectedAcct0PvtKey);
      final _key9 = md.fromPath("m/0/9") as Bip32SigningKey;
      //expect(_key9, equals(spend9.signingKey!));
      final _spendPvtKey = account.basePrivateKey(index: 9);
      expect(_spendPvtKey, _key9);
      //print(acctXskCoder.encode(_spendPvtKey));
      final _stakePvtKey = account.stakePrivateKey;
      // print(stakeXskCoder.encode(_stakePvtKey));
      final _addr9 = account.baseAddress(index: 9);
      expect(_addr9.toBech32(), equals(addr9));
      final __addr9 = ShelleyAddress.toBaseAddress(
        spend: _key9.verifyKey!,
        stake: _stakePvtKey.verifyKey!,
        networkId: NetworkId.testnet,
      );
      expect(__addr9.toBech32(), equals(addr9));
    });
  });
}
