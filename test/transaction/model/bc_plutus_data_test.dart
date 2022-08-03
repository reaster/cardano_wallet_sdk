// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:logging/logging.dart';
import 'package:cbor/cbor.dart';
// import 'dart:convert' as convertor;
import 'package:test/test.dart';
import 'package:hex/hex.dart';
// import 'dart:typed_data';

void main() {
  Logger.root.level = Level.WARNING; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  final logger = Logger('BcPlutusDataTest');
  group('PlutusData -', () {
    final fortyTwo = CborInt(BigInt.from(42));
    final hello = CborBytes('hello'.codeUnits);
    final list1 = CborList([fortyTwo, hello]);
    final map1 = CborMap({fortyTwo: hello});

    test('fromCbor', () {
      final cbor1 = BcPlutusData.fromCbor(fortyTwo);
      expect(cbor1 is BcBigIntPlutusData, isTrue);
      expect(cbor1.cborValue, fortyTwo);
      final cbor2 = BcPlutusData.fromCbor(hello);
      expect(cbor2 is BcBytesPlutusData, isTrue);
      expect(cbor2.cborValue, hello);
      final cbor3 = BcPlutusData.fromCbor(list1);
      expect(cbor3 is BcListPlutusData, isTrue);
      expect(cbor3.cborValue, list1);
      final cbor4 = BcPlutusData.fromCbor(map1);
      expect(cbor4 is BcMapPlutusData, isTrue);
      expect(cbor4.cborValue, map1);
    });

    test('cbor', () {
      final list1 = BcListPlutusData([
        BcBigIntPlutusData(BigInt.from(42)),
        BcBigIntPlutusData(BigInt.from(42 * 2)),
        // BcBytesPlutusData.fromString('hello'),
      ]);
      logger.info("type: ${list1.cborValue}");

      expect(list1.cborValue is CborList, isTrue);
      final bytes1 = list1.serialize;
      final list2 = BcPlutusData.deserialize(bytes1);
      expect(list2, equals(list1));
    });
  });
}

/*

    @Test
    void serializeDeserialize() throws CborSerializationException, CborException, CborDeserializationException {
        ListPlutusData listPlutusData = ListPlutusData.builder()
                .plutusDataList(Arrays.asList(
                        new BigIntPlutusData(BigInteger.valueOf(1001)),
                        new BigIntPlutusData(BigInteger.valueOf(200)),
                        new BytesPlutusData("hello".getBytes(StandardCharsets.UTF_8))
                )).build();


        byte[] serialize = CborSerializationUtil.serialize(listPlutusData.serialize());

        //deserialize
        List<DataItem> dis = CborDecoder.decode(serialize);
        ListPlutusData deListPlutusData = (ListPlutusData) PlutusData.deserialize(dis.get(0));
        byte[] serialize1 = CborSerializationUtil.serialize(deListPlutusData.serialize());

        assertThat(serialize1).isEqualTo(serialize);
    }

    @Test
    void serializeDeserialize_whenIsChunked_False() throws CborSerializationException, CborException, CborDeserializationException {
        ListPlutusData listPlutusData = ListPlutusData.builder()
                .plutusDataList(Arrays.asList(
                        new BigIntPlutusData(BigInteger.valueOf(1001)),
                        new BigIntPlutusData(BigInteger.valueOf(200)),
                        new BytesPlutusData("hello".getBytes(StandardCharsets.UTF_8))
                ))
                .isChunked(false)
                .build();


        byte[] serialize = CborSerializationUtil.serialize(listPlutusData.serialize());

        //deserialize
        List<DataItem> dis = CborDecoder.decode(serialize);
        ListPlutusData deListPlutusData = (ListPlutusData) PlutusData.deserialize(dis.get(0));
        byte[] serialize1 = CborSerializationUtil.serialize(deListPlutusData.serialize());

        assertThat(serialize1).isEqualTo(serialize);
    }
*/
