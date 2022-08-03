import 'dart:typed_data';
import 'package:hex/hex.dart';
import 'package:cbor/cbor.dart';

abstract class BcAbstractCbor {
  Uint8List get serialize;
  String get json;

  Uint8List toUint8List(CborValue value) =>
      Uint8List.fromList(cbor.encode(value));

  String toJson(CborValue value) => const CborJsonEncoder().convert(value);

  String get toHex => HEX.encode(serialize);

  @override
  String toString() => toHex;

  @override
  int get hashCode => toHex.hashCode;

  @override
  bool operator ==(Object other) {
    bool isEq = identical(this, other) ||
        other is BcAbstractCbor && runtimeType == other.runtimeType;
    if (!isEq) return false;
    final Uint8List list1 = serialize;
    final Uint8List list2 = (other as BcAbstractCbor).serialize;
    return _equalBytes(list1, list2);
  }

  bool _equalBytes(Uint8List a, Uint8List b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class CborError extends Error {
  final String message;
  CborError(this.message);
  @override
  String toString() => message;
}
