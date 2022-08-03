// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:logging/logging.dart';
import 'package:cbor/cbor.dart';
import 'package:test/test.dart';
import 'package:hex/hex.dart';
import 'dart:typed_data';

void main() {
  //Logger.root.level = Level.WARNING; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  final logger = Logger('BcScriptsTest');
  group('Redeemer -', () {
    final fortyTwo = CborBigInt(BigInt.from(42));
    final hello = CborBytes('hello'.codeUnits);
    final list1 = CborList([fortyTwo, hello]);
    final map1 = CborMap({fortyTwo: hello});

    test('cbor', () {
      final redeemer1 = BcRedeemer(
        tag: BcRedeemerTag.spend,
        index: BigInt.from(99),
        data: BcPlutusData.fromCbor(map1),
        exUnits: BcExUnits(BigInt.from(1024), BigInt.from(6)),
      );
      final cbor = redeemer1.cborValue;
      logger.info(cbor);
      final hex1 = redeemer1.toHex;
      logger.info(hex1);
    });
    test('cbor2', () {
      final redeemer1 = BcRedeemer(
        tag: BcRedeemerTag.spend,
        index: BigInt.from(0),
        data: BcBigIntPlutusData(BigInt.from(2021)),
        exUnits: BcExUnits(BigInt.from(1700), BigInt.from(476468)),
      );
      final cbor = redeemer1.cborValue;
      logger.info(cbor);
      final hex1 = redeemer1.toHex;
      logger.info(hex1);
      expect(hex1, equals('8400001907e5821906a41a00074534'));
    });
    /*
    Expected: '84000019    07e582  1906a41a00074534'
      Actual: '8400c240c24207e582c24206a4c243074534'

    PlutusData plutusData = new BigIntPlutusData(new BigInteger("2021"));
        Redeemer redeemer = Redeemer.builder()
                .tag(RedeemerTag.Spend)
                .data(plutusData)
                .index(BigInteger.valueOf(0))
                .exUnits(ExUnits.builder()
                        .mem(BigInteger.valueOf(1700))
                        .steps(BigInteger.valueOf(476468)).build())
                .build();
                */
  });

  group('Script -', () {
    BcScriptAtLeast multisigScript1() => BcScriptAtLeast(amount: 2, scripts: [
          BcScriptPubkey(
              keyHash:
                  '74cfebcf5e97474d7b89c862d7ee7cff22efbb032d4133a1b84cbdcd'),
          BcScriptPubkey(
              keyHash:
                  '710ee487dbbcdb59b5841a00d1029a56a407c722b3081c02470b516d'),
          BcScriptPubkey(
              keyHash:
                  'beed26382ec96254a6714928c3c5bb8227abecbbb095cfeab9fb2dd1'),
        ]);

    Uint8List parseInts(String s) =>
        Uint8List.fromList(s.split(',').map((i) => int.parse(i)).toList());

    test('plutusScriptHash', () {
      final scriptHash =
          '103,243,49,70,97,122,94,97,147,96,129,219,59,33,23,203,245,155,210,18,55,72,245,138,201,103,134,86';
      final script = BcPlutusScript(cborHex: '4e4d01000033222220051200120011');
      final ser1 = script.serialize;
      logger.info("plutus hex: ${script.toHex}");
      logger.info("plutus ser1: ${ser1.join(',')}");
      expect(script.serialize,
          equals(parseInts('78,77,1,0,0,51,34,34,32,5,18,0,18,0,17')),
          reason: '14 bytes: 4e4d01000033222220051200120011');
      //scriptHash bytes=[1,78,77,1,0,0,51,34,34,32,5,18,0,18,0,17]
      //java hash  bytes=[1,77,1,0,0,51,34,34,32,5,18,0,18,0,17]
      expect(
        script.scriptHash,
        equals(parseInts(
            '103,243,49,70,97,122,94,97,147,96,129,219,59,33,23,203,245,155,210,18,55,72,245,138,201,103,134,86')),
      );

      logger.info("plutus hash: ${script.scriptHash.join(',')}");
    });

    test('nativeScriptHash', () {
      final scriptBytes =
          '131,3,2,131,130,0,88,28,116,207,235,207,94,151,71,77,123,137,200,98,215,238,124,255,34,239,187,3,45,65,51,161,184,76,189,205,130,0,88,28,113,14,228,135,219,188,219,89,181,132,26,0,209,2,154,86,164,7,199,34,179,8,28,2,71,11,81,109,130,0,88,28,190,237,38,56,46,201,98,84,166,113,73,40,195,197,187,130,39,171,236,187,176,149,207,234,185,251,45,209';
      final sciptHash =
          '177,126,186,172,54,246,23,66,181,74,110,82,228,2,223,209,167,14,48,114,35,160,131,136,57,166,167,145';
      final script = multisigScript1();
      expect(script.serialize, equals(parseInts(scriptBytes)));
      expect(script.scriptHash, equals(parseInts(sciptHash)));
    });

    test('nativeScriptSerialize', () {
      final t0 = BcScriptPubkey(
          keyHash: 'ad7a7b87959173fc9eac9a85891cc93892f800dd45c0544128228884');
      final t1 = BcRequireTimeBefore(slot: 12345678);
      final t2 = BcRequireTimeAfter(slot: 87654321);
      final t3 = BcScriptAtLeast(amount: 1, scripts: [t0, t1, t2]);
      final t4 = BcScriptAtLeast(amount: 1, scripts: [t1, t2]);
      final scripts = [
        t0,
        BcScriptAtLeast(amount: 2, scripts: [t0, t1, t2, t3, t4]),
        BcScriptAll(scripts: [t1, t2, t3, t4]),
        BcScriptAny(scripts: [t1, t2, t3, t4])
      ];
      for (BcNativeScript script1 in scripts) {
        final bytes1 = cbor.encode(script1.toCborList());
        CborValue val1 = cbor.decode(bytes1);
        //print(const CborJsonEncoder().convert(val1));
        final script2 = BcNativeScript.fromCbor(list: val1 as CborList);
        expect(script2, equals(script1));
      }
    });
    test('policyId1', () {
      final s = BcScriptPubkey(
          keyHash: 'ad7a7b87959173fc9eac9a85891cc93892f800dd45c0544128228884');
      expect(s.policyId,
          equals('b9bd3fb4511908402fbef848eece773bb44c867c25ac8c08d9ec3313'));
    });
    test('policyId2', () {
      final sp1 = BcScriptPubkey(
          keyHash: 'ad7a7b87959173fc9eac9a85891cc93892f800dd45c0544128228884');
      final sp2 = BcScriptPubkey(
          keyHash: 'ee7a7b87959173fc9eac9a85891cc93892f800dd45c0544128228884');
      final sp3 = BcScriptPubkey(
          keyHash: 'ff7a7b87959173fc9eac9a85891cc93892f800dd45c0544128228884');
      final sp4 = BcScriptPubkey(
          keyHash: 'ef7a7b87959173fc9eac9a85891cc93892f800dd45c0544128228884');
      expect(BcScriptAll(scripts: [sp1, sp2, sp3]).policyId,
          equals('3e2abf6c1a400037d4c6fad14143553df36c2c5e6ec33c10ae411155'));
      expect(BcScriptAny(scripts: [sp1, sp4, sp3]).policyId,
          equals('f63e8acf67374e0aa0482d0055b419b9ce1adf80628a8ee23130782b'));
    });
    test('policyId3', () {
      final sp1 = BcScriptPubkey(
          keyHash: '2f3d4cf10d0471a1db9f2d2907de867968c27bca6272f062cd1c2413');
      final sp2 = BcScriptPubkey(
          keyHash: 'f856c0c5839bab22673747d53f1ae9eed84afafb085f086e8e988614');
      final sp3 = BcScriptPubkey(
          keyHash: 'b275b08c999097247f7c17e77007c7010cd19f20cc086ad99d398538');
      expect(BcScriptAtLeast(amount: 2, scripts: [sp1, sp2, sp3]).policyId,
          equals('1e3e60975af4971f7cc02ed4d90c87abaafd2dd070a42eafa6f5e939'));
    });
    test('policyId4', () {
      final sa = BcRequireTimeAfter(slot: 1000);
      final sp = BcScriptPubkey(
          keyHash: '966e394a544f242081e41d1965137b1bb412ac230d40ed5407821c37');
      expect(BcScriptAll(scripts: [sa, sp]).policyId,
          equals('120125c6dea2049988eb0dc8ddcc4c56dd48628d45206a2d0bc7e55b'));
    });
    test('policyId5', () {
      final sb = BcRequireTimeBefore(slot: 2000);
      final sp = BcScriptPubkey(
          keyHash: '966e394a544f242081e41d1965137b1bb412ac230d40ed5407821c37');
      expect(BcScriptAll(scripts: [sb, sp]).policyId,
          equals('d900e9ec3899d67d70050d1f8f4dd0a3c7bb1439e134509ee5c86b01'));
    });
    test('policyId6', () {
      final sp1 = BcScriptPubkey(
          keyHash: 'b275b08c999097247f7c17e77007c7010cd19f20cc086ad99d398538');
      final sp2 = BcScriptPubkey(
          keyHash: '966e394a544f242081e41d1965137b1bb412ac230d40ed5407821c37');
      final sb = BcRequireTimeBefore(slot: 3000);
      expect(
          BcScriptAny(scripts: [
            sp1,
            BcScriptAll(scripts: [sb, sp2])
          ]).policyId,
          equals('6519f942518b8761f4b02e1403365b7d7befae1eb488b7fffcbab33f'));
    });
  });
}
