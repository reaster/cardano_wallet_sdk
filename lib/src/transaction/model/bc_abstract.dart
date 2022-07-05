import 'dart:typed_data';
import 'package:hex/hex.dart';
import 'package:cbor/cbor.dart';
import 'package:typed_data/typed_buffers.dart';
import '../../util/blake2bhash.dart';

abstract class BcAbstractCbor {
  Uint8List get serialize;

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

abstract class BcAbstractScript extends BcAbstractCbor {
  Uint8List get scriptHash => Uint8List.fromList(blake2bHash224([
        ...[0],
        ...serialize
      ]));
}
