// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'dart:convert';
import 'dart:typed_data';
import 'package:cbor/cbor.dart';
import 'package:hex/hex.dart';
import './bc_abstract.dart';

abstract class BcPlutusData extends BcAbstractCbor {
  CborValue get cborValue;

  @override
  String get json => toJson(cborValue);

  @override
  Uint8List get serialize => toUint8List(cborValue);

  static BcPlutusData fromCborList(CborList cbotList) {
    final item = cbotList[0];
    return fromCbor(item);
  }

  static BcPlutusData deserialize(Uint8List bytes) =>
      fromCbor(cbor.decode(bytes));

  static BcPlutusData fromCbor(CborValue item) {
    if (item is CborInt) {
      return BcBigIntPlutusData(item.toBigInt());
    } else if (item is CborBytes) {
      return BcBytesPlutusData(Uint8List.fromList(item.bytes));
    } else if (item is CborList) {
      return BcListPlutusData(item.map((c) => fromCbor(c)).toList());
    } else if (item is CborMap) {
      return BcMapPlutusData({
        for (MapEntry<CborValue, CborValue> entry in item.entries)
          fromCbor(entry.key): fromCbor(entry.value),
      });
    } else {
      throw CborError(
          "Only support BigInt, ByteString, List and Map CBOR types, not: $item");
    }
    // final Type type = item.runtimeType;
    // switch (type) {
    //   case CborBigInt:
    //     return BcBigIntPlutusData((item as CborBigInt).toBigInt());
    //   case CborBytes:
    //     return BcBytesPlutusData.fromBytes((item as CborBytes).bytes);
    //   case CborList:
    //     return BcListPlutusData(
    //         (item as CborList).map((c) => fromCbor(c)).toList());
    //   case CborMap:
    //     return BcMapPlutusData({
    //       for (MapEntry<CborValue, CborValue> entry
    //           in (item as CborMap).entries)
    //         fromCbor(entry.key): fromCbor(entry.value),
    //     });
    //   default:
    //     throw CborError(
    //         "Only support BigInt, ByteString, List and Map CBOR types, not: $item");
    // }
  }
}

class BcBytesPlutusData extends BcPlutusData {
  // final String cborHex;
  final Uint8List bytes;

  BcBytesPlutusData(this.bytes);

  BcBytesPlutusData.fromHex(String hex)
      : this(Uint8List.fromList(HEX.decode(hex)));
  BcBytesPlutusData.fromString(String string)
      : this(Uint8List.fromList(utf8.encode(string)));

  @override
  CborValue get cborValue => CborBytes(bytes);

  @override
  Uint8List get serialize => bytes;
}

class BcBigIntPlutusData extends BcPlutusData {
  final BigInt bigInt;
  BcBigIntPlutusData(this.bigInt);
  BcBigIntPlutusData.fromInt(int i) : this(BigInt.from(i));

  @override
  CborValue get cborValue => CborInt(bigInt);
}

class BcListPlutusData extends BcPlutusData {
  final List<BcPlutusData> list;

  BcListPlutusData(this.list);

  @override
  CborValue get cborValue => CborList(list.map((c) => c.cborValue).toList());
}

class BcMapPlutusData extends BcPlutusData {
  final Map<BcPlutusData, BcPlutusData> map;

  BcMapPlutusData(this.map);
  @override
  CborValue get cborValue => CborMap({
        for (MapEntry<BcPlutusData, BcPlutusData> entry in map.entries)
          entry.key.cborValue: entry.value.cborValue,
      });
}

// public interface PlutusData {

//    plutus_data = ; New
//    constr<plutus_data>
//  / { * plutus_data => plutus_data }
//  / [ * plutus_data ]
//            / big_int
//  / bounded_bytes

//    big_int = int / big_uint / big_nint ; New
//    big_uint = #6.2(bounded_bytes) ; New
//    big_nint = #6.3(bounded_bytes) ; New

//     DataItem serialize() throws CborSerializationException;

//     static PlutusData deserialize(DataItem dataItem) throws CborDeserializationException {
//         if (dataItem == null)
//             return null;

//         if (dataItem instanceof Number) {
//             return BigIntPlutusData.deserialize((Number) dataItem);
//         } else if (dataItem instanceof ByteString) {
//             return BytesPlutusData.deserialize((ByteString) dataItem);
//         } else if (dataItem instanceof Array) {
//             if (dataItem.getTag() == null) {
//                 return ListPlutusData.deserialize((Array) dataItem);
//             } else { //Tag found .. try Constr
//                 return ConstrPlutusData.deserialize(dataItem);
//             }
//         } else if (dataItem instanceof Map) {
//             return MapPlutusData.deserialize((Map) dataItem);
//         } else
//             throw new CborDeserializationException("Cbor deserialization failed. Invalid type. " + dataItem);
//     }

//     static PlutusData deserialize(@NonNull byte[] serializedBytes) throws CborDeserializationException {
//         try {
//             DataItem dataItem = CborDecoder.decode(serializedBytes).get(0);
//             return deserialize(dataItem);
//         } catch (CborException | CborDeserializationException e) {
//             throw new CborDeserializationException("Cbor de-serialization error", e);
//         }
//     }

//     default String getDatumHash() throws CborSerializationException, CborException {
//         return HexUtil.encodeHexString(getDatumHashAsBytes());
//     }

//     default byte[] getDatumHashAsBytes() throws CborSerializationException, CborException {
//         return KeyGenUtil.blake2bHash256(CborSerializationUtil.serialize(serialize()));
//     }

//     default String serializeToHex()  {
//         try {
//             return HexUtil.encodeHexString(CborSerializationUtil.serialize(serialize()));
//         } catch (Exception e) {
//             throw new CborRuntimeException("Cbor serialization error", e);
//         }
//     }
// }
