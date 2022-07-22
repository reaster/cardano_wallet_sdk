// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:bip32_ed25519/bip32_ed25519.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

BcScriptAtLeast getMultisigScript() => BcScriptAtLeast(amount: 2, scripts: [
      BcScriptPubkey(
          keyHash: '74cfebcf5e97474d7b89c862d7ee7cff22efbb032d4133a1b84cbdcd'),
      BcScriptPubkey(
          keyHash: '710ee487dbbcdb59b5841a00d1029a56a407c722b3081c02470b516d'),
      BcScriptPubkey(
          keyHash: 'beed26382ec96254a6714928c3c5bb8227abecbbb095cfeab9fb2dd1'),
    ]);

class MockPlutusScript extends BcPlutusScript {
  final String scriptBip32Hash;
  MockPlutusScript(this.scriptBip32Hash)
      : super(cborHex: '4e4d01000033222220051200120011');
  @override
  Uint8List get scriptHash => scriptCoder.decode(scriptBip32Hash);
}

void main() {
  Logger.root.level = Level.WARNING; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  final logger = Logger('ShelleyAddressTest');
  group('CIP19 Test Vectors -', () {
    final dummyChainCode = csvToUint8List(
        '0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0');
    final addrXvk = Bip32VerifyKey.fromKeyBytes(
        addrVkCoder.decode(
            'addr_vk1w0l2sr2zgfm26ztc6nl9xy8ghsk5sh6ldwemlpmp9xylzy4dtf7st80zhd'),
        dummyChainCode);
    final addrVk = VerifyKey(Uint8List.fromList(addrXvk.prefix));
    final stakeXvk = Bip32VerifyKey.fromKeyBytes(
        stakeVkCoder.decode(
            'stake_vk1px4j0r2fk7ux5p23shz8f3y5y2qam7s954rgf3lg5merqcj6aetsft99wu'),
        dummyChainCode);
    final stakeVk = VerifyKey(Uint8List.fromList(stakeXvk.prefix));
    final script = MockPlutusScript(
        'script1cda3khwqv60360rp5m7akt50m6ttapacs8rqhn5w342z7r35m37');
    final pointer = BcPointer(slot: 2498243, txIndex: 27, certIndex: 3);
    test('mainnet - type-00', () {
      expect(
          ShelleyAddress.baseAddress(spend: addrXvk, stake: stakeXvk)
              .toBech32(),
          equals(
              'addr1qx2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3n0d3vllmyqwsx5wktcd8cc3sq835lu7drv2xwl2wywfgse35a3x'));
      expect(
          ShelleyAddress.baseAddress(spend: addrVk, stake: stakeVk).toBech32(),
          equals(
              'addr1qx2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3n0d3vllmyqwsx5wktcd8cc3sq835lu7drv2xwl2wywfgse35a3x'));
    });
    test('mainnet - type-01', () {
      expect(
          ShelleyAddress.baseScriptStakeAddress(script: script, stake: stakeXvk)
              .toBech32(),
          equals(
              'addr1z8phkx6acpnf78fuvxn0mkew3l0fd058hzquvz7w36x4gten0d3vllmyqwsx5wktcd8cc3sq835lu7drv2xwl2wywfgs9yc0hh'));
      expect(
          ShelleyAddress.baseScriptStakeAddress(script: script, stake: stakeVk)
              .toBech32(),
          equals(
              'addr1z8phkx6acpnf78fuvxn0mkew3l0fd058hzquvz7w36x4gten0d3vllmyqwsx5wktcd8cc3sq835lu7drv2xwl2wywfgs9yc0hh'));
    });
    test('mainnet - type-02', () {
      expect(
          ShelleyAddress.baseKeyScriptAddress(spend: addrXvk, script: script)
              .toBech32(),
          equals(
              'addr1yx2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzerkr0vd4msrxnuwnccdxlhdjar77j6lg0wypcc9uar5d2shs2z78ve'));
      expect(
          ShelleyAddress.baseKeyScriptAddress(spend: addrVk, script: script)
              .toBech32(),
          equals(
              'addr1yx2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzerkr0vd4msrxnuwnccdxlhdjar77j6lg0wypcc9uar5d2shs2z78ve'));
    });
    test('mainnet - type-03', () {
      expect(
          ShelleyAddress.baseScriptScriptAddress(
                  script1: script, script2: script)
              .toBech32(),
          equals(
              'addr1x8phkx6acpnf78fuvxn0mkew3l0fd058hzquvz7w36x4gt7r0vd4msrxnuwnccdxlhdjar77j6lg0wypcc9uar5d2shskhj42g'));
    });
    test('mainnet - type-04', () {
      expect(
          ShelleyAddress.pointerAddress(verifyKey: addrVk, pointer: pointer)
              .toBech32(),
          equals(
              'addr1gx2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer5pnz75xxcrzqf96k'));
      expect(
          ShelleyAddress.pointerAddress(verifyKey: addrXvk, pointer: pointer)
              .toBech32(),
          equals(
              'addr1gx2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer5pnz75xxcrzqf96k'));
    });
    test('mainnet - type-05', () {
      expect(
          ShelleyAddress.pointerScriptAddress(script: script, pointer: pointer)
              .toBech32(),
          equals(
              'addr128phkx6acpnf78fuvxn0mkew3l0fd058hzquvz7w36x4gtupnz75xxcrtw79hu'));
    });
    test('mainnet - type-06', () {
      expect(ShelleyAddress.enterpriseAddress(spend: addrXvk).toBech32(),
          equals('addr1vx2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzers66hrl8'));
      expect(ShelleyAddress.enterpriseAddress(spend: addrVk).toBech32(),
          equals('addr1vx2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzers66hrl8'));
    });
    test('mainnet - type-07', () {
      expect(ShelleyAddress.enterpriseScriptAddress(script: script).toBech32(),
          equals('addr1w8phkx6acpnf78fuvxn0mkew3l0fd058hzquvz7w36x4gtcyjy7wx'));
    });
    test('mainnet - type-14', () {
      expect(
          ShelleyAddress.rewardAddress(stakeKey: stakeVk).toBech32(),
          equals(
              'stake1uyehkck0lajq8gr28t9uxnuvgcqrc6070x3k9r8048z8y5gh6ffgw'));
      expect(
          ShelleyAddress.rewardAddress(stakeKey: stakeXvk).toBech32(),
          equals(
              'stake1uyehkck0lajq8gr28t9uxnuvgcqrc6070x3k9r8048z8y5gh6ffgw'));
    });
    test('mainnet - type-15', () {
      expect(
          ShelleyAddress.rewardScriptAddress(script: script).toBech32(),
          equals(
              'stake178phkx6acpnf78fuvxn0mkew3l0fd058hzquvz7w36x4gtcccycj5'));
    });
    test('testnet - type-00', () {
      expect(
          ShelleyAddress.baseAddress(
                  spend: addrXvk, stake: stakeXvk, network: Networks.testnet)
              .toBech32(),
          equals(
              'addr_test1qz2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3n0d3vllmyqwsx5wktcd8cc3sq835lu7drv2xwl2wywfgs68faae'));
      expect(
          ShelleyAddress.baseAddress(
                  spend: addrVk, stake: stakeVk, network: Networks.testnet)
              .toBech32(),
          equals(
              'addr_test1qz2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3n0d3vllmyqwsx5wktcd8cc3sq835lu7drv2xwl2wywfgs68faae'));
    });
    test('testnet - type-01', () {
      expect(
          ShelleyAddress.baseScriptStakeAddress(
                  script: script, stake: stakeXvk, network: Networks.testnet)
              .toBech32(),
          equals(
              'addr_test1zrphkx6acpnf78fuvxn0mkew3l0fd058hzquvz7w36x4gten0d3vllmyqwsx5wktcd8cc3sq835lu7drv2xwl2wywfgsxj90mg'));
      expect(
          ShelleyAddress.baseScriptStakeAddress(
                  script: script, stake: stakeVk, network: Networks.testnet)
              .toBech32(),
          equals(
              'addr_test1zrphkx6acpnf78fuvxn0mkew3l0fd058hzquvz7w36x4gten0d3vllmyqwsx5wktcd8cc3sq835lu7drv2xwl2wywfgsxj90mg'));
    });
    test('testnet - type-02', () {
      expect(
          ShelleyAddress.baseKeyScriptAddress(
                  spend: addrXvk, script: script, network: Networks.testnet)
              .toBech32(),
          equals(
              'addr_test1yz2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzerkr0vd4msrxnuwnccdxlhdjar77j6lg0wypcc9uar5d2shsf5r8qx'));
      expect(
          ShelleyAddress.baseKeyScriptAddress(
                  spend: addrVk, script: script, network: Networks.testnet)
              .toBech32(),
          equals(
              'addr_test1yz2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzerkr0vd4msrxnuwnccdxlhdjar77j6lg0wypcc9uar5d2shsf5r8qx'));
    });
    test('testnet - type-03', () {
      expect(
          ShelleyAddress.baseScriptScriptAddress(
                  script1: script, script2: script, network: Networks.testnet)
              .toBech32(),
          equals(
              'addr_test1xrphkx6acpnf78fuvxn0mkew3l0fd058hzquvz7w36x4gt7r0vd4msrxnuwnccdxlhdjar77j6lg0wypcc9uar5d2shs4p04xh'));
    });
    test('testnet - type-04', () {
      expect(
          ShelleyAddress.pointerAddress(
                  verifyKey: addrVk,
                  pointer: pointer,
                  network: Networks.testnet)
              .toBech32(),
          equals(
              'addr_test1gz2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer5pnz75xxcrdw5vky'));
      expect(
          ShelleyAddress.pointerAddress(
                  verifyKey: addrXvk,
                  pointer: pointer,
                  network: Networks.testnet)
              .toBech32(),
          equals(
              'addr_test1gz2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer5pnz75xxcrdw5vky'));
    });
    test('testnet - type-05', () {
      expect(
          ShelleyAddress.pointerScriptAddress(
                  script: script, pointer: pointer, network: Networks.testnet)
              .toBech32(),
          equals(
              'addr_test12rphkx6acpnf78fuvxn0mkew3l0fd058hzquvz7w36x4gtupnz75xxcryqrvmw'));
    });
    test('testnet - type-06', () {
      expect(
          ShelleyAddress.enterpriseAddress(
                  spend: addrXvk, network: Networks.testnet)
              .toBech32(),
          equals(
              'addr_test1vz2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzerspjrlsz'));
      expect(
          ShelleyAddress.enterpriseAddress(
                  spend: addrVk, network: Networks.testnet)
              .toBech32(),
          equals(
              'addr_test1vz2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzerspjrlsz'));
    });
    test('testnet - type-07', () {
      expect(
          ShelleyAddress.enterpriseScriptAddress(
                  script: script, network: Networks.testnet)
              .toBech32(),
          equals(
              'addr_test1wrphkx6acpnf78fuvxn0mkew3l0fd058hzquvz7w36x4gtcl6szpr'));
    });
    test('testnet - type-14', () {
      expect(
          ShelleyAddress.rewardAddress(
                  stakeKey: stakeVk, network: Networks.testnet)
              .toBech32(),
          equals(
              'stake_test1uqehkck0lajq8gr28t9uxnuvgcqrc6070x3k9r8048z8y5gssrtvn'));
      expect(
          ShelleyAddress.rewardAddress(
                  stakeKey: stakeXvk, network: Networks.testnet)
              .toBech32(),
          equals(
              'stake_test1uqehkck0lajq8gr28t9uxnuvgcqrc6070x3k9r8048z8y5gssrtvn'));
    });
    test('testnet - type-15', () {
      expect(
          ShelleyAddress.rewardScriptAddress(
                  script: script, network: Networks.testnet)
              .toBech32(),
          equals(
              'stake_test17rphkx6acpnf78fuvxn0mkew3l0fd058hzquvz7w36x4gtcljw6kf'));
    });
  });

  group('ByronAddresses -', () {
    test('Daedalus-style - DdzFF', () {
      //Daedalus-style: Starting with  DdzFF
      final addr =
          "DdzFFzCqrhszg6cqZvDhEwUX7cZyNzdycAVpm4Uo2vjKMgTLrVqiVKi3MBt2tFAtDe7NkptK6TAhVkiYzhavmKV5hE79CWwJnPCJTREK";
      final byronAddr = parseAddress(addr);
      expect(byronAddr, isInstanceOf<ByronAddress>());
      expect((byronAddr as ByronAddress).toBase58, equals(addr));
    });
    test('Icarus-style - Ae2', () {
      //Icarus-style: Starting with Ae2
      final addr =
          "Ae2tdPwUPEZ3MHKkpT5Bpj549vrRH7nBqYjNXnCV8G2Bc2YxNcGHEa8ykDp";
      final byronAddr = parseAddress(addr);
      expect(byronAddr, isInstanceOf<ByronAddress>());
      expect((byronAddr as ByronAddress).toBase58, equals(addr));
    });
    test('issue13', () {
      final addr =
          'DdzFFzCqrht64pcFbyLyDbVd87ApfbPKumaXiNjPf1kn9LUtGraWdkmWYMNbEG8e7MoA5Y8GASDFG34F13BBeJjvF8tt9oLCkYcicWse';
      final byronAddr = parseAddress(addr);
      expect(byronAddr, isInstanceOf<ByronAddress>());
      expect((byronAddr as ByronAddress).toBase58, equals(addr));
    });
    test('InvalidAddressError', () {
      expect(() => parseAddress('junk'),
          throwsA(TypeMatcher<InvalidAddressError>()));
      expect(
          () => parseAddress(
              'Ae2t#PwUPEZ3MHKkpT5Bpj549vrRH7nBqYjNXnCV8G2Bc2YxNcGHEa8ykDp'),
          throwsA(TypeMatcher<InvalidAddressError>()));
    });
  });

  group('ScriptAddresses -', () {
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
      logger.info("plutus hash: ${script.scriptHash.join(',')}");
    });

    test('enterpriseScriptAddress', () {
      final address = ShelleyAddress.enterpriseScriptAddress(
        script: getMultisigScript(),
        network: Networks.testnet,
      );
      logger.info(address.toBech32());
      expect(
          address.toBech32(),
          equals(
              "addr_test1wzchaw4vxmmpws44ffh99eqzmlg6wr3swg36pqug8xn20ygxgqher"));
    });

    test('enterprisePlutusScriptAddress', () {
      final address = ShelleyAddress.enterpriseScriptAddress(
        script: getMultisigScript(),
        network: Networks.testnet,
      );
      // logger.info(address.bytes.join(','));
      // logger.info(address.toBech32());
      expect(
          address.toBech32(),
          equals(
              "addr_test1wzchaw4vxmmpws44ffh99eqzmlg6wr3swg36pqug8xn20ygxgqher"));
    });
  });

  group('shelley address test -', () {
    const addr =
        'addr1qyy6nhfyks7wdu3dudslys37v252w2nwhv0fw2nfawemmn8k8ttq8f3gag0h89aepvx3xf69g0l9pf80tqv7cve0l33sdn8p3d';
    const addrTest =
        'addr_test1qqy6nhfyks7wdu3dudslys37v252w2nwhv0fw2nfawemmn8k8ttq8f3gag0h89aepvx3xf69g0l9pf80tqv7cve0l33sw96paj';
    const addrTest2 =
        'addr_test1qrqeavr4pa4vtzuf64m9z3cjke582vk7qvc6pcc6e5m9txa24kyuyck0xp0a7n7rah0gxj5mq3zdrc6xnaqph967c2kqcun0nj';

    const testEntropy =
        '4e828f9a67ddcff0e6391ad4f26ddb7579f59ba14b6dd4baf63dcfdb9d2420da';
    final account0 = HdMaster.entropyHex(testEntropy).account();
    final spendKey = account0.basePrivateKey().publicKey;
    final stakeKey = account0.stakePrivateKey.publicKey;
    final pointer = BcPointer(slot: 2498243, txIndex: 27, certIndex: 3);
    test('network header', () {
      var a = parseAddress(addr);
      expect(a.network, Networks.mainnet, reason: 'set mainnet bit in header');
      expect(a.addressType, AddressType.base);
      a = parseAddress(addrTest);
      expect(a.network, Networks.testnet, reason: 'set testnet bit in header');
      expect(a.addressType, AddressType.base);
      expect(a.header & 0x30, isZero); //0b0011_0000 & header == 0
      a = ShelleyAddress.baseAddress(
        spend: spendKey,
        stake: stakeKey,
        network: Networks.testnet,
      );
      expect(a.network, Networks.testnet, reason: 'set testnet bit in header');
      expect(a.toString(), startsWith('addr_test1'),
          reason: 'set testnet bit in header');
      a = ShelleyAddress.baseAddress(
          spend: spendKey, stake: stakeKey, network: Networks.mainnet);
      expect(a.network, Networks.mainnet, reason: 'set mainnet bit in header');
      expect(a.toString(), startsWith('addr1'),
          reason: 'set mainnet bit in header');
    });
    test('credential type header', () {
      var a = ShelleyAddress.baseAddress(spend: spendKey, stake: stakeKey);
      expect(a.paymentCredentialType, CredentialType.key,
          reason: 'key is default credential type');
      a = ShelleyAddress.baseScriptStakeAddress(
          script: getMultisigScript(), stake: stakeKey);
      expect(a.paymentCredentialType, CredentialType.script,
          reason: 'override credential type');
    });
    test('address type header', () {
      var a = ShelleyAddress.baseAddress(
        spend: spendKey,
        stake: stakeKey,
        network: Networks.testnet,
      );
      expect(a.addressType, AddressType.base,
          reason: 'toBaseAddress sets address type');
      a = ShelleyAddress.rewardScriptAddress(
        script: getMultisigScript(),
        network: Networks.testnet,
      );
      expect(a.addressType, AddressType.reward,
          reason: 'toRewardAddress sets address type');
    });
    test('address equals', () {
      var a = parseAddress(addrTest);
      var b = parseAddress(addrTest2);
      var c = parseAddress(addrTest);
      expect(a == c, isTrue, reason: 'equals works');
      Set<AbstractAddress> set = {a, b};
      expect(set.contains(c), isTrue, reason: 'equals works');
    });

    test('pointer from bech32', () {
      var ent =
          'addr1gx2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer5ph3wczvf2w8lunk';
      var e = ShelleyAddress.fromBech32(ent);
      expect(e.network, equals(Networks.mainnet));
      expect(e.paymentCredentialType, equals(CredentialType.key));
      expect(e.addressType, equals(AddressType.pointer));
      expect(e.hrp, equals('addr'));
      ent =
          'addr_test1gz2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzerspqgpsqe70et';
      e = ShelleyAddress.fromBech32(ent);
      expect(e.network, equals(Networks.testnet));
      expect(e.paymentCredentialType, equals(CredentialType.key));
      expect(e.addressType, equals(AddressType.pointer));
      expect(e.hrp, equals('addr_test'));
    });

    test('enterprise', () {
      var e = ShelleyAddress.enterpriseAddress(
          spend: spendKey, network: Networks.testnet);
      expect(e.addressType, equals(AddressType.enterprise));
      expect(e.network, equals(Networks.testnet));
      expect(e.paymentCredentialType, equals(CredentialType.key));
      expect(
          e.toBech32(),
          equals(
              'addr_test1vqy6nhfyks7wdu3dudslys37v252w2nwhv0fw2nfawemmnqtjtf68'),
          reason: 'TODO chek addr');
      //logger.info(e.toBech32());
    });

    test('enterpriseFromBech32VerifyKey', () {
      final verifycKey = Bip32VerifyKey.decode(
          'addr_xvk1r30n0pv6d40kzzl4e6xje2y7c446gw2x9sgnms3vv62tx264tf5n9lxnuxqc5xpqlg30dtlq0tf0fav4kafsge6u24x296vg85l399cx2uv4k',
          coder: Bech32Coder(hrp: 'addr_xvk'));
      var addr = ShelleyAddress.enterpriseAddress(
          spend: verifycKey, network: Networks.testnet);
      expect(
          addr.toBech32(),
          equals(
              'addr_test1vp8w93j8pappvvu8tcajysvr65ph8wt5yg5u4s5u2j4e80ggxcu4e'));
    });
  });
}
