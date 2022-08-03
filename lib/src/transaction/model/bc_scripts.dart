import 'package:bip32_ed25519/bip32_ed25519.dart';
import 'package:cardano_wallet_sdk/src/crypto/key_util.dart';
import 'package:hex/hex.dart';
import 'package:cbor/cbor.dart';
import '../../util/blake2bhash.dart';
import '../../util/codec.dart';
import './bc_exception.dart';
import './bc_abstract.dart';
import './bc_plutus_data.dart';

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

enum BcScriptType {
  native(0),
  plutusV1(1),
  plutusV2(2);

  final int header;
  const BcScriptType(this.header);
}

abstract class BcAbstractScript extends BcAbstractCbor {
  BcScriptType get type;
  Uint8List get scriptHash => Uint8List.fromList(blake2bHash224([
        ...[type.header],
        ...serialize
      ]));
}

class BcPlutusScript extends BcAbstractScript {
  @override
  final BcScriptType type;
  final String cborHex;
  final String? description;

  BcPlutusScript({
    this.type = BcScriptType.plutusV1,
    required this.cborHex,
    this.description,
  });

  CborBytes toCborBytes() => cbor.decode(serialize) as CborBytes;

  //   CborBytes toCborBytes() =>
  // CborBytes(uint8BufferFromHex(cborHex, utf8EncodeOnHexFailure: true));

  @override
  Uint8List get serialize =>
      uint8ListFromHex(cborHex, utf8EncodeOnHexFailure: true);

  // @override
  // Uint8List get serialize => toUint8List(toCborBytes());

  @override
  String toString() {
    return 'BcPlutusScript(type: $type, description: $description, cborHex: $cborHex)';
  }

  @override
  Uint8List get scriptHash {
    final bytes = [
      ...[type.header],
      ...toCborBytes().bytes
    ];
    //print("scriptHash bytes=[${bytes.join(',')}]");
    return Uint8List.fromList(blake2bHash224(bytes));
  }

  @override
  String get json => toJson(toCborBytes());
}

enum BcNativeScriptType { sig, all, any, atLeast, after, before }

abstract class BcNativeScript extends BcAbstractScript {
  @override
  final BcScriptType type = BcScriptType.native;
  BcNativeScriptType get nativeType;

  CborList toCborList();

  @override
  Uint8List get serialize => toUint8List(toCborList());

  static BcNativeScript fromCbor({required CborList list}) {
    final selector = list[0] as CborSmallInt;
    final nativeType = BcNativeScriptType.values[selector.toInt()];
    switch (nativeType) {
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

  String get policyId => HEX.encode(blake2bHash224([
        ...[type.header],
        ...serialize
      ]));

  static List<BcNativeScript> deserializeScripts(CborList scriptList) {
    return <BcNativeScript>[
      for (dynamic blob in scriptList)
        BcNativeScript.fromCbor(list: blob as CborList),
    ];
  }

  @override
  String get json => toJson(toCborList());
}

class BcScriptPubkey extends BcNativeScript {
  @override
  final BcNativeScriptType nativeType = BcNativeScriptType.sig;
  final String keyHash;

  BcScriptPubkey({
    required this.keyHash,
  });

  factory BcScriptPubkey.fromCbor({required CborList list}) {
    final keyHash = list[1] as CborBytes;
    return BcScriptPubkey(keyHash: HEX.encode(keyHash.bytes));
  }

  factory BcScriptPubkey.fromKey({required VerifyKey verifyKey}) =>
      BcScriptPubkey(keyHash: KeyUtil.keyHash(verifyKey: verifyKey));

  @override
  CborList toCborList() => CborList([
        CborSmallInt(nativeType.index),
        CborBytes(uint8BufferFromHex(keyHash, utf8EncodeOnHexFailure: true))
      ]);

  @override
  String toString() {
    return 'BcScriptPubkey(nativeType: $nativeType, keyHash: $keyHash)';
  }
}

class BcScriptAll extends BcNativeScript {
  @override
  final BcNativeScriptType nativeType = BcNativeScriptType.all;
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
      CborSmallInt(nativeType.index),
      CborList([for (var s in scripts) s.toCborList()]),
    ]);
  }

  @override
  String toString() {
    return 'BcScriptAll(nativeType: $nativeType, scripts: $scripts)';
  }
}

class BcScriptAny extends BcNativeScript {
  @override
  final BcNativeScriptType nativeType = BcNativeScriptType.any;
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
      CborSmallInt(nativeType.index),
      CborList([for (var s in scripts) s.toCborList()]),
    ]);
  }

  @override
  String toString() {
    return 'BcScriptAny(nativeType: $nativeType, scripts: $scripts)';
  }
}

class BcScriptAtLeast extends BcNativeScript {
  @override
  final BcNativeScriptType nativeType = BcNativeScriptType.atLeast;
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
      CborSmallInt(nativeType.index),
      CborSmallInt(amount),
      CborList([for (var s in scripts) s.toCborList()]),
    ]);
  }

  @override
  String toString() {
    return 'BcScriptAtLeast(nativeType: $nativeType, amount: $amount, scripts: $scripts)';
  }
}

class BcRequireTimeAfter extends BcNativeScript {
  @override
  final BcNativeScriptType nativeType = BcNativeScriptType.after;
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
      CborSmallInt(nativeType.index),
      CborSmallInt(slot),
    ]);
  }

  @override
  String toString() {
    return 'BcRequireTimeAfter(nativeType: $nativeType, slot: $slot)';
  }
}

class BcRequireTimeBefore extends BcNativeScript {
  @override
  final BcNativeScriptType nativeType = BcNativeScriptType.before;
  final int slot;
  BcRequireTimeBefore({
    required this.slot,
  });

  factory BcRequireTimeBefore.fromCbor({required CborList list}) {
    return BcRequireTimeBefore(slot: (list[1] as CborSmallInt).toInt());
  }

  @override
  CborList toCborList() {
    return CborList([
      CborSmallInt(nativeType.index),
      CborSmallInt(slot),
    ]);
  }

  @override
  String toString() {
    return 'BcRequireTimeBefore(nativeType: $nativeType, slot: $slot)';
  }
}

enum BcRedeemerTag {
  spend(0),
  mint(1),
  cert(2),
  reward(3);

  final int value;
  const BcRedeemerTag(this.value);

  static BcRedeemerTag fromCbor(CborValue value) {
    if (value is CborInt && value.toInt() >= 0 && value.toInt() < 5) {
      return BcRedeemerTag.values[value.toInt()];
    } else {
      throw CborError(
          "BcRedeemerTag expecting CborInt with value in [0..3], not $value");
    }
  }
}

class BcRedeemer extends BcAbstractCbor {
  final BcRedeemerTag tag;
  final BigInt index;
  final BcPlutusData data;
  final BcExUnits exUnits;

  BcRedeemer(
      {required this.tag,
      required this.index,
      required this.data,
      required this.exUnits});

  static BcRedeemer deserialize(Uint8List bytes) =>
      fromCbor(cbor.decode(bytes));

  static BcRedeemer fromCbor(CborValue item) {
    if (item is CborList) {
      if (item.length == 4) {
        return BcRedeemer(
          tag: BcRedeemerTag.fromCbor(item[0]),
          index: (item[1] as CborInt).toBigInt(),
          data: BcPlutusData.fromCbor(item[2]),
          exUnits: BcExUnits.fromCbor(item[3]),
        );
      } else {
        throw CborError(
            "Redeemer list must contain 4 properties, not ${item.length}");
      }
    } else {
      throw CborError("Redeemer expecting CborList, not $item");
    }
  }

  CborValue get cborValue => CborList([
        CborSmallInt(tag.value),
        CborInt(index),
        data.cborValue,
        exUnits.cborValue,
      ]);

  @override
  String get json => toJson(cborValue);

  @override
  Uint8List get serialize => toUint8List(cborValue);
}

class BcExUnits {
  final BigInt mem;
  final BigInt steps;

  BcExUnits(this.mem, this.steps);

  CborValue get cborValue => CborList([
        CborInt(mem),
        CborInt(steps),
      ]);

  static BcExUnits fromCbor(CborValue value) {
    if (value is CborList &&
        value.length == 2 &&
        value[0] is CborInt &&
        value[1] is CborInt) {
      return BcExUnits(
          (value[0] as CborInt).toBigInt(), (value[0] as CborInt).toBigInt());
    } else {
      throw CborError(
          "BcExUnits.fromCbor expecting CborArray of two CborInt's, not $value");
    }
  }
}
