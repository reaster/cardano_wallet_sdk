// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:bip32_ed25519/bip32_ed25519.dart';
import 'package:test/test.dart';

BcScriptAtLeast getMultisigScript() => BcScriptAtLeast(amount: 2, scripts: [
      BcScriptPubkey(
          keyHash: '74cfebcf5e97474d7b89c862d7ee7cff22efbb032d4133a1b84cbdcd'),
      BcScriptPubkey(
          keyHash: '710ee487dbbcdb59b5841a00d1029a56a407c722b3081c02470b516d'),
      BcScriptPubkey(
          keyHash: 'beed26382ec96254a6714928c3c5bb8227abecbbb095cfeab9fb2dd1'),
    ]);

void main() {
  group('ScriptAddresses -', () {
    const testEntropy =
        '4e828f9a67ddcff0e6391ad4f26ddb7579f59ba14b6dd4baf63dcfdb9d2420da';
    final hdWallet = HdWallet.fromHexEntropy(testEntropy);
    final Bip32KeyPair spendPair = hdWallet.deriveAddressKeys(index: 0);
    //final Bip32KeyPair changePair = hdWallet.deriveAddress(role: changeRole, index: 0);
    final Bip32KeyPair stakePair =
        hdWallet.deriveAddressKeys(role: stakingRoleIndex, index: 0);

    List<int> parseInts(String s) =>
        s.split(',').map((i) => int.parse(i)).toList();

    test('scriptSannityCheck', () {
      final scriptBytes =
          '131,3,2,131,130,0,88,28,116,207,235,207,94,151,71,77,123,137,200,98,215,238,124,255,34,239,187,3,45,65,51,161,184,76,189,205,130,0,88,28,113,14,228,135,219,188,219,89,181,132,26,0,209,2,154,86,164,7,199,34,179,8,28,2,71,11,81,109,130,0,88,28,190,237,38,56,46,201,98,84,166,113,73,40,195,197,187,130,39,171,236,187,176,149,207,234,185,251,45,209';
      final sciptHash =
          '177,126,186,172,54,246,23,66,181,74,110,82,228,2,223,209,167,14,48,114,35,160,131,136,57,166,167,145';
      final script = getMultisigScript();
      expect(script.serialize.toList(), equals(parseInts(scriptBytes)));
      expect(script.scriptHash.toList(), equals(parseInts(sciptHash)));
      //Enterprise(header[0]+hash): [112,177,126,186,172,54,246,23,66,181,74,110,82,228,2,223,209,167,14,48,114,35,160,131,136,57,166,167,145]
      //addr_test1wzchaw4vxmmpws44ffh99eqzmlg6wr3swg36pqug8xn20ygxgqher
    });

    test('plutusScriptSannityCheck', () {
      final scriptHash =
          '103,243,49,70,97,122,94,97,147,96,129,219,59,33,23,203,245,155,210,18,55,72,245,138,201,103,134,86';
      final script = BcPlutusScript(cborHex: '4e4d01000033222220051200120011');
      print("plutus hash: ${script.scriptHash.join(',')}");
    });

    test('enterpriseScriptAddress', () {
      final address =
          ShelleyAddress.enterpriseScriptAddress(script: getMultisigScript());
      print(address.toBech32());
      expect(
          address.toBech32(),
          equals(
              "addr_test1wzchaw4vxmmpws44ffh99eqzmlg6wr3swg36pqug8xn20ygxgqher"));
    });

    test('enterprisePlutusScriptAddress', () {
      final address =
          ShelleyAddress.enterpriseScriptAddress(script: getMultisigScript());
      // print(address.bytes.join(','));
      // print(address.toBech32());
      expect(
          address.toBech32(),
          equals(
              "addr_test1wzchaw4vxmmpws44ffh99eqzmlg6wr3swg36pqug8xn20ygxgqher"));
    });
  });
/*
        void getScriptEntAddress_whenNativeScript() throws CborSerializationException {
            ScriptAtLeast scriptAtLeast = getMultisigScript();

            Address address = AddressService.getInstance().getEntAddress(scriptAtLeast, Networks.testnet());
            System.out.println(address.toBech32());

            assertThat(address.toBech32()).isEqualTo("addr_test1wzchaw4vxmmpws44ffh99eqzmlg6wr3swg36pqug8xn20ygxgqher");
        }


        @Test
        void getScriptEntAddress_whenPlutusScript() throws CborSerializationException {
            PlutusScript plutusScript = PlutusScript.builder()
                    .type("PlutusScriptV1")
                    .cborHex("4e4d01000033222220051200120011")
                    .build();

            Address address = AddressService.getInstance().getEntAddress(plutusScript, Networks.testnet());
            System.out.println(address.toBech32());

            assertThat(address.toBech32()).isEqualTo("addr_test1wpnlxv2xv9a9ucvnvzqakwepzl9ltx7jzgm53av2e9ncv4sysemm8");
        }
    }

*/

  group('shelley address test -', () {
    const addr =
        'addr1qyy6nhfyks7wdu3dudslys37v252w2nwhv0fw2nfawemmn8k8ttq8f3gag0h89aepvx3xf69g0l9pf80tqv7cve0l33sdn8p3d';
    const addrTest =
        'addr_test1qqy6nhfyks7wdu3dudslys37v252w2nwhv0fw2nfawemmn8k8ttq8f3gag0h89aepvx3xf69g0l9pf80tqv7cve0l33sw96paj';
    const addrTest2 =
        'addr_test1qrqeavr4pa4vtzuf64m9z3cjke582vk7qvc6pcc6e5m9txa24kyuyck0xp0a7n7rah0gxj5mq3zdrc6xnaqph967c2kqcun0nj';

    const testEntropy =
        '4e828f9a67ddcff0e6391ad4f26ddb7579f59ba14b6dd4baf63dcfdb9d2420da';
    final hdWallet = HdWallet.fromHexEntropy(testEntropy);
    final Bip32KeyPair spendPair = hdWallet.deriveAddressKeys(index: 0);
    //final Bip32KeyPair changePair = hdWallet.deriveAddress(role: changeRole, index: 0);
    final Bip32KeyPair stakePair =
        hdWallet.deriveAddressKeys(role: stakingRoleIndex, index: 0);
    test('network header', () {
      var a = ShelleyAddress.fromBech32(addr);
      expect(a.networkId, NetworkId.mainnet,
          reason: 'set mainnet bit in header');
      a = ShelleyAddress.fromBech32(addrTest);
      expect(a.networkId, NetworkId.testnet,
          reason: 'set testnet bit in header');
      a = ShelleyAddress.toBaseAddress(
          spend: spendPair.verifyKey!, stake: stakePair.verifyKey!);
      expect(a.networkId, NetworkId.testnet,
          reason: 'set testnet bit in header');
      expect(a.toBech32(), startsWith('addr_test1'),
          reason: 'set testnet bit in header');
      a = ShelleyAddress.toBaseAddress(
          spend: spendPair.verifyKey!,
          stake: stakePair.verifyKey!,
          networkId: NetworkId.mainnet);
      expect(a.networkId, NetworkId.mainnet,
          reason: 'set mainnet bit in header');
      expect(a.toBech32(), startsWith('addr1'),
          reason: 'set mainnet bit in header');
    });
    test('credential type header', () {
      var a = ShelleyAddress.toBaseAddress(
          spend: spendPair.verifyKey!, stake: stakePair.verifyKey!);
      expect(a.paymentCredentialType, CredentialType.key,
          reason: 'key is default credential type');
      a = ShelleyAddress.toBaseAddress(
          spend: spendPair.verifyKey!,
          stake: stakePair.verifyKey!,
          paymentType: CredentialType.script);
      expect(a.paymentCredentialType, CredentialType.script,
          reason: 'override credential type');
    });
    test('address type header', () {
      var a = ShelleyAddress.toBaseAddress(
          spend: spendPair.verifyKey!, stake: stakePair.verifyKey!);
      expect(a.addressType, AddressType.base,
          reason: 'toBaseAddress sets address type');
      a = ShelleyAddress.toRewardAddress(spend: spendPair.verifyKey!);
      expect(a.addressType, AddressType.reward,
          reason: 'toRewardAddress sets address type');
    });
    test('address equals', () {
      var a = ShelleyAddress.fromBech32(addrTest);
      var b = ShelleyAddress.fromBech32(addrTest2);
      var c = ShelleyAddress.fromBech32(addrTest);
      expect(a == c, isTrue, reason: 'equals works');
      Set<ShelleyAddress> set = {a, b};
      expect(set.contains(c), isTrue, reason: 'equals works');
    });

    test('pointer from bech32', () {
      var ent =
          'addr1gx2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer5ph3wczvf2w8lunk';
      var e = ShelleyAddress.fromBech32(ent);
      expect(e.networkId, equals(NetworkId.mainnet));
      expect(e.paymentCredentialType, equals(CredentialType.key));
      expect(e.addressType, equals(AddressType.pointer));
      expect(e.hrp, equals('addr'));
      ent =
          'addr_test1gz2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzerspqgpsqe70et';
      e = ShelleyAddress.fromBech32(ent);
      expect(e.networkId, equals(NetworkId.testnet));
      expect(e.paymentCredentialType, equals(CredentialType.key));
      expect(e.addressType, equals(AddressType.pointer));
      expect(e.hrp, equals('addr_test'));
    });

    test('enterprise', () {
      final publicKey = spendPair.verifyKey!;
      var e = ShelleyAddress.enterpriseAddress(
          spend: publicKey as Bip32PublicKey, networkId: NetworkId.testnet);
      expect(e.addressType, equals(AddressType.enterprise));
      expect(e.networkId, equals(NetworkId.testnet));
      expect(e.paymentCredentialType, equals(CredentialType.key));
      expect(
          e.toBech32(),
          equals(
              'addr_test1vqy6nhfyks7wdu3dudslys37v252w2nwhv0fw2nfawemmnqtjtf68'),
          reason: 'TODO chek addr');
      //print(e.toBech32());
    });

    // test('isPublicKeyMatch', () {
    //   var addr = ShelleyAddress.toBaseAddress(
    //       spend: spendPair.verifyKey!, stake: stakePair.verifyKey!);
    //   expect(addr.isPublicKeyMatch(spendPair.verifyKey!), isTrue,
    //       reason: 'matching verify key');
    // });

    // test('bech32', () {
    //   final decoded = bech32.decode(addr, 108);
    //   final hrp = decoded.hrp;
    //   expect('addr', hrp);
    //   final addr2 = Bech32Coder(hrp: hrp).encode(decoded.data);
    //   expect(addr2, addr);
    // });
  });
}
