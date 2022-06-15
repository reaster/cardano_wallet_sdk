import 'dart:typed_data';
import 'package:hex/hex.dart';
import 'package:cbor/cbor.dart';
import '../../util/codec.dart';
import 'bc_exception.dart';
import 'bc_abstract.dart';

///
/// From the Shelley era onwards, Cardano has supported scripts and script addresses.
///
/// Cardano is designed to support multiple script languages, and most features that
/// are related to scripts work the same irrespective of the script language (or
/// version of a script language).
///
/// The Shelley era supports a single, simple script language, which can be used for
/// multi-signature addresses. The Allegra era (token locking) extends the simple
/// script language with a feature to make scripts conditional on time. This can be
/// used to make address with so-called "time locks", where the funds cannot be
/// withdrawn until after a certain point in time.
///
/// see https://github.com/input-output-hk/cardano-node/blob/master/doc/reference/simple-scripts.md
///

class BcPlutusScript extends BcAbstractScript {
  static const type = 'PlutusScriptV1';
  final String? description;
  final String cborHex;

  BcPlutusScript({
    this.description,
    required this.cborHex,
  });

  CborList toCborList() => CborList(
      [CborBytes(uint8BufferFromHex(cborHex, utf8EncodeOnHexFailure: true))]);

  @override
  Uint8List get serialize => toUint8List(toCborList());

  @override
  String toString() {
    return 'BcPlutusScript(type: $type, description: $description, cborHex: $cborHex)';
  }
}

enum BcNativeScriptType { sig, all, any, atLeast, after, before }

abstract class BcNativeScript extends BcAbstractScript {
  BcNativeScriptType get type;

  CborList toCborList();

  @override
  Uint8List get serialize => toUint8List(toCborList());

  static BcNativeScript fromCbor({required CborList list}) {
    final selector = list[0] as CborSmallInt;
    final type = BcNativeScriptType.values[selector.toInt()];
    switch (type) {
      case BcNativeScriptType.sig:
        return BcScriptPubkey.fromCbor(list: list);
      case BcNativeScriptType.all:
        return BcScriptAll.fromCbor(list: list);
      case BcNativeScriptType.any:
        return BcScriptAny.fromCbor(list: list);
      case BcNativeScriptType.atLeast:
        return BcScriptAtLeast.fromCbor(list: list);
      case BcNativeScriptType.after:
        return BcRequireTimeAfter.fromCbor(list: list);
      case BcNativeScriptType.before:
        return BcRequireTimeBefore.fromCbor(list: list);
      default:
        throw BcCborDeserializationException(
            "unknown native script selector: $selector");
    }
  }

  static List<BcNativeScript> deserializeScripts(CborList scriptList) {
    return <BcNativeScript>[
      for (dynamic blob in scriptList)
        BcNativeScript.fromCbor(list: blob as CborList),
    ];
  }
}

class BcScriptPubkey extends BcNativeScript {
  @override
  final BcNativeScriptType type = BcNativeScriptType.sig;
  final String keyHash;

  BcScriptPubkey({
    required this.keyHash,
  });

  factory BcScriptPubkey.fromCbor({required CborList list}) {
    final keyHash = list[1] as CborBytes;
    return BcScriptPubkey(keyHash: HEX.encode(keyHash.bytes));
  }

  CborList toCborList() {
    return CborList([
      CborSmallInt(type.index),
      CborBytes(uint8BufferFromHex(keyHash, utf8EncodeOnHexFailure: true))
    ]);
  }

  @override
  String toString() {
    return 'BcScriptPubkey(type: $type, keyHash: $keyHash)';
  }
}

class BcScriptAll extends BcNativeScript {
  @override
  final BcNativeScriptType type = BcNativeScriptType.all;
  final List<BcNativeScript> scripts;

  BcScriptAll({
    required this.scripts,
  });

  factory BcScriptAll.fromCbor({required CborList list}) {
    final scripts = BcNativeScript.deserializeScripts(list[1] as CborList);
    return BcScriptAll(scripts: scripts);
  }

  @override
  CborList toCborList() {
    return CborList([
      CborSmallInt(type.index),
      CborList([for (var s in scripts) s.toCborList()]),
    ]);
  }

  @override
  String toString() {
    return 'BcScriptAll(type: $type, scripts: $scripts)';
  }
}

class BcScriptAny extends BcNativeScript {
  @override
  final BcNativeScriptType type = BcNativeScriptType.any;
  final List<BcNativeScript> scripts;
  BcScriptAny({
    required this.scripts,
  });

  factory BcScriptAny.fromCbor({required CborList list}) {
    final scripts = BcNativeScript.deserializeScripts(list[1] as CborList);
    return BcScriptAny(scripts: scripts);
  }

  @override
  CborList toCborList() {
    return CborList([
      CborSmallInt(type.index),
      CborList([for (var s in scripts) s.toCborList()]),
    ]);
  }

  @override
  String toString() {
    return 'BcScriptAny(type: $type, scripts: $scripts)';
  }
}

class BcScriptAtLeast extends BcNativeScript {
  @override
  final BcNativeScriptType type = BcNativeScriptType.atLeast;
  final int amount;
  final List<BcNativeScript> scripts;
  BcScriptAtLeast({
    required this.amount,
    required this.scripts,
  });

  factory BcScriptAtLeast.fromCbor({required CborList list}) {
    final scripts = BcNativeScript.deserializeScripts(list[2] as CborList);
    return BcScriptAtLeast(
        amount: (list[1] as CborSmallInt).toInt(), scripts: scripts);
  }

  @override
  CborList toCborList() {
    return CborList([
      CborSmallInt(type.index),
      CborSmallInt(amount),
      CborList([for (var s in scripts) s.toCborList()]),
    ]);
  }

  @override
  String toString() {
    return 'BcScriptAtLeast(type: $type, amount: $amount, scripts: $scripts)';
  }
}

class BcRequireTimeAfter extends BcNativeScript {
  @override
  final BcNativeScriptType type = BcNativeScriptType.after;
  final int slot;
  BcRequireTimeAfter({
    required this.slot,
  });

  factory BcRequireTimeAfter.fromCbor({required CborList list}) {
    return BcRequireTimeAfter(slot: (list[1] as CborSmallInt).toInt());
  }

  @override
  CborList toCborList() {
    return CborList([
      CborSmallInt(type.index),
      CborSmallInt(slot),
    ]);
  }

  @override
  String toString() {
    return 'BcRequireTimeAfter(type: $type, slot: $slot)';
  }
}

class BcRequireTimeBefore extends BcNativeScript {
  @override
  final BcNativeScriptType type = BcNativeScriptType.before;
  final int slot;
  BcRequireTimeBefore({
    required this.slot,
  });

  factory BcRequireTimeBefore.fromCbor({required CborList list}) {
    return BcRequireTimeBefore(slot: (list[1] as CborSmallInt).toInt());
  }

  CborList toCborList() {
    return CborList([
      CborSmallInt(type.index),
      CborSmallInt(slot),
    ]);
  }

  @override
  String toString() {
    return 'BcRequireTimeBefore(type: $type, slot: $slot)';
  }
}
