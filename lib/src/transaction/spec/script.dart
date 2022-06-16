import 'dart:typed_data';
import 'package:cbor/cbor.dart';
import 'package:hex/hex.dart';
// import 'package:quiver/core.dart';
import 'package:typed_data/typed_buffers.dart';
import '../model/bc_exception.dart';
import '../../util/blake2bhash.dart';
import '../../util/codec.dart';

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
@Deprecated('use bc_script.dart')
abstract class Script {
  Uint8Buffer get serialize {
    final Uint8Buffer data = Uint8Buffer()..addAll(cbor.encode(toCborList()));
    return data;
    //Uint8List.view(data.buffer, 0, data.length);
  }

  CborList toCborList({bool forJson = false});
  //   final listBuilder = ListBuilder.builder();
  //   listBuilder.writeInt(type.index);
  //   if (forJson) {
  //     listBuilder.writeString(HEX.encode(blob));
  //   } else {
  //     listBuilder.writeBuff(unit8BufferFromBytes(blob));
  //   }
  //   return listBuilder;
  // }

  String get toHex => HEX.encode(serialize);

  @override
  String toString() => toHex;

  @override
  int get hashCode => toHex.hashCode;

  @override
  bool operator ==(Object other) {
    bool isEq = identical(this, other) ||
        other is NativeScript && runtimeType == other.runtimeType;
    if (!isEq) return false;
    final Uint8Buffer list1 = serialize;
    final Uint8Buffer list2 = (other as NativeScript).serialize;
    return _equalBytes(list1, list2);
  }

  bool _equalBytes(Uint8Buffer a, Uint8Buffer b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  String get policyId => HEX.encode(blake2bHash224([
        ...[0],
        ...serialize
      ]));

  Uint8List get scriptHash => Uint8List.fromList(blake2bHash224([
        ...[0],
        ...serialize
      ]));
}

class PlutusScript extends Script {
  final String type = "PlutusScriptV1";
  final String description;
  final String cborHex;

  PlutusScript(this.description, this.cborHex);

  @override
  CborList toCborList({bool forJson = false}) => CborList(
      [CborBytes(uint8BufferFromHex(cborHex, utf8EncodeOnHexFailure: true))]);

  // @override
  // ListBuilder toCborList({bool forJson = false}) {
  //   final listBuilder = ListBuilder.builder();
  //   listBuilder
  //       .writeBuff(uint8BufferFromHex(cborHex, utf8EncodeOnHexFailure: true));
  //   return listBuilder;
  // }
}

enum NativeScriptType { sig, all, any, atLeast, after, before }

abstract class NativeScript extends Script {
  NativeScriptType get type;

  static NativeScript fromCbor({required CborList list}) {
    final selector = list[0] as CborSmallInt;
    final type = NativeScriptType.values[selector.toInt()];
    switch (type) {
      case NativeScriptType.sig:
        return ScriptPubkey.fromCbor(list: list);
      case NativeScriptType.all:
        return ScriptAll.fromCbor(list: list);
      case NativeScriptType.any:
        return ScriptAny.fromCbor(list: list);
      case NativeScriptType.atLeast:
        return ShelleScriptAtLeast.fromCbor(list: list);
      case NativeScriptType.after:
        return RequireTimeAfter.fromCbor(list: list);
      case NativeScriptType.before:
        return RequireTimeBefore.fromCbor(list: list);
      default:
        throw BcCborDeserializationException(
            "unknown native script selector: $selector");
    }
  }

  CborList toCborSublist(List<NativeScript> scripts, {bool forJson = false}) {
    return CborList(scripts.map((e) => e.toCborList()).toList());
    // final scriptListBuilder = ListBuilder.builder();
    // for (NativeScript script in scripts) {
    //   scriptListBuilder
    //       .addBuilderOutput(script.toCborList(forJson: forJson).getData());
    // }
    // return scriptListBuilder;
  }
}

class ScriptPubkey extends NativeScript {
  final String keyHash;
  @override
  final NativeScriptType type = NativeScriptType.sig;

  ScriptPubkey({required this.keyHash});

  factory ScriptPubkey.fromCbor({required CborList list}) {
    final keyHash = list[1] as CborBytes;
    return ScriptPubkey(keyHash: HEX.encode(keyHash.bytes));
  }

  @override
  CborList toCborList({bool forJson = false}) {
    return CborList([
      CborSmallInt(type.index),
      CborBytes(uint8BufferFromHex(keyHash, utf8EncodeOnHexFailure: true))
    ]);
    // final listBuilder = ListBuilder.builder();
    // listBuilder.writeInt(type.index);
    // listBuilder
    //     .writeBuff(uint8BufferFromHex(keyHash, utf8EncodeOnHexFailure: true));
    // return listBuilder;
  }
}

class ScriptAll extends NativeScript {
  @override
  final NativeScriptType type;
  final List<NativeScript> scripts;

  ScriptAll({this.type = NativeScriptType.all, required this.scripts});

  factory ScriptAll.fromCbor({required CborList list}) =>
      ScriptAll(scripts: deserializeScripts(list[1] as CborList));

  static List<NativeScript> deserializeScripts(CborList scriptList) {
    List<NativeScript> scripts = [];
    for (dynamic blob in scriptList) {
      final script = NativeScript.fromCbor(list: blob as CborList);
      scripts.add(script);
    }
    return scripts;
  }

  @override
  CborList toCborList({bool forJson = false}) {
    return CborList([
      CborSmallInt(type.index),
      toCborSublist(scripts),
    ]);
    // final listBuilder = ListBuilder.builder();
    // listBuilder.writeInt(type.index);
    // listBuilder
    //     .addBuilderOutput(toCborSublist(scripts, forJson: forJson).getData());
    // // for (NativeScript script in scripts) {
    // //   listBuilder
    // //       .addBuilderOutput(script.toCborList(forJson: forJson).getData());
    // // }
    // return listBuilder;
  }
}

class ScriptAny extends ScriptAll {
  ScriptAny({required List<NativeScript> scripts})
      : super(scripts: scripts, type: NativeScriptType.any);
  factory ScriptAny.fromCbor({required CborList list}) =>
      ScriptAny(scripts: ScriptAll.deserializeScripts(list[1] as CborList));
}

class ShelleScriptAtLeast extends ScriptAll {
  final int amount;
  ShelleScriptAtLeast(
      {required this.amount, required List<NativeScript> scripts})
      : super(scripts: scripts, type: NativeScriptType.atLeast);
  factory ShelleScriptAtLeast.fromCbor({required CborList list}) =>
      ShelleScriptAtLeast(
          amount: (list[1] as CborSmallInt).toInt(),
          scripts: ScriptAll.deserializeScripts(list[2] as CborList));
  @override
  CborList toCborList({bool forJson = false}) {
    return CborList([
      CborSmallInt(type.index),
      CborSmallInt(amount),
      toCborSublist(scripts, forJson: forJson)
    ]);
    // final listBuilder = ListBuilder.builder();
    // listBuilder.writeInt(type.index);
    // listBuilder.writeInt(amount);
    // listBuilder
    //     .addBuilderOutput(toCborSublist(scripts, forJson: forJson).getData());
    // return listBuilder;
  }
}

class RequireTimeAfter extends NativeScript {
  @override
  final NativeScriptType type = NativeScriptType.after;
  final int slot;

  RequireTimeAfter({required this.slot});

  factory RequireTimeAfter.fromCbor({required CborList list}) =>
      RequireTimeAfter(slot: (list[1] as CborSmallInt).toInt());

  @override
  CborList toCborList({bool forJson = false}) {
    return CborList([
      CborSmallInt(type.index),
      CborSmallInt(slot),
    ]);
    // final listBuilder = ListBuilder.builder();
    // listBuilder.writeInt(type.index);
    // listBuilder.writeInt(slot);
    // return listBuilder;
  }
}

class RequireTimeBefore extends NativeScript {
  @override
  final NativeScriptType type = NativeScriptType.before;
  final int slot;

  RequireTimeBefore({required this.slot});

  factory RequireTimeBefore.fromCbor({required CborList list}) =>
      RequireTimeBefore(slot: (list[1] as CborSmallInt).toInt());

  @override
  CborList toCborList({bool forJson = false}) {
    return CborList([
      CborSmallInt(type.index),
      CborSmallInt(slot),
    ]);
    // final listBuilder = ListBuilder.builder();
    // listBuilder.writeInt(type.index);
    // listBuilder.writeInt(slot);
    // return listBuilder;
  }
}

// abstract class Script {
//   Uint8List get bytes;

//   String get toHex => HEX.encode(bytes);

//   Uint8List get scriptHash;

//   @override
//   String toString() => toHex;

//   List<int> get calcBlake2bHash224 => blake2bHash224(bytes);

//   @override
//   int get hashCode => hashObjects(bytes);

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is Script &&
//           runtimeType == other.runtimeType &&
//           bytes.length == other.bytes.length &&
//           _equalBytes(bytes, other.bytes);

//   bool _equalBytes(Uint8List a, Uint8List b) {
//     for (var i = 0; i < a.length; i++) {
//       if (a[i] != b[i]) return false;
//     }
//     return true;
//   }

//   String get policyId => HEX.encode(blake2bHash224([
//         ...Uint8List.fromList([0]),
//         ...bytes
//       ]));

//   // String getPolicyId() throws CborSerializationException {
//   //       byte[] first = new byte[]{00};
//   //       byte[] serializedBytes = this.serialize();
//   //       byte[] finalBytes = ByteBuffer.allocate(first.length + serializedBytes.length)
//   //               .put(first)
//   //               .put(serializedBytes)
//   //               .array();

//   //       return Hex.toHexString(blake2bHash224(finalBytes));
//   //   }
// }

// class NativeScript extends Script {
//   @override
//   final Uint8List bytes;
//   NativeScript(this.bytes);
//   NativeScript.fromHex(String hex) : this(Uint8List.fromList(HEX.decode(hex)));
//   @override
//   // TODO: implement scriptHash
//   Uint8List get scriptHash => throw UnimplementedError();
// }

// class ScriptPubkey extends NativeScript {
//   final String keyHash;
//   // final ScriptType type;
//   ScriptPubkey(Uint8List bytes)
//       :
//         keyHash = '',
//         super(bytes);
//   ScriptPubkey.fromHex(String hex) : this(Uint8List.fromList(HEX.decode(hex)));

//   @override
//   // TODO: implement scriptHash
//   Uint8List get scriptHash => throw UnimplementedError();
// }

// /*
// public class ScriptPubkey implements NativeScript {
//     private final static Logger LOG = LoggerFactory.getLogger(ScriptPubkey.class);

//     private String keyHash;
//     private ScriptType type;

//     public ScriptPubkey() {
//         this.type = ScriptType.sig;
//     }

//     public ScriptPubkey(String keyHash) {
//         this();
//         this.keyHash = keyHash;
//     }

//     public byte[] toBytes() {
//         if (keyHash == null || keyHash.length() == 0)
//             return new byte[0];

//         byte[] keyHashBytes = new byte[0];
//         try {
//             keyHashBytes = HexUtil.decodeHexString(keyHash);
//         } catch (Exception e) {
//             LOG.error("Error ", e);
//         }
//         return keyHashBytes;
//     }

//     public DataItem serializeAsDataItem() {
//         Array array = new Array();
//         array.add(new UnsignedInteger(0));
//         array.add(new ByteString(HexUtil.decodeHexString(keyHash)));
//         return array;
//     }

//     public static ScriptPubkey deserialize(Array array) throws CborDeserializationException {
//         ScriptPubkey scriptPubkey = new ScriptPubkey();
//         ByteString keyHashBS = (ByteString)(array.getDataItems().get(1));
//         scriptPubkey.setKeyHash(HexUtil.encodeHexString(keyHashBS.getBytes()));
//         return scriptPubkey;
//     }

//     public static ScriptPubkey deserialize(JsonNode jsonNode) throws CborDeserializationException {
//         ScriptPubkey scriptPubkey = new ScriptPubkey();
//         String keyHash = jsonNode.get("keyHash").asText();
//         scriptPubkey.setKeyHash(keyHash);
//         return scriptPubkey;
//     }

//     public static ScriptPubkey create(VerificationKey vkey) {
//         return new ScriptPubkey(KeyGenUtil.getKeyHash(vkey));
//     }

//     public static Tuple<ScriptPubkey, Keys> createWithNewKey() throws CborSerializationException {
//         Keys keys = KeyGenUtil.generateKey();

//         ScriptPubkey scriptPubkey = ScriptPubkey.create(keys.getVkey());
//         return new Tuple<ScriptPubkey, Keys>(scriptPubkey, keys);
//     }
// }

// public interface NativeScript extends Script {

//     static NativeScript deserialize(Array nativeScriptArray) throws CborDeserializationException {
//         List<DataItem> dataItemList = nativeScriptArray.getDataItems();
//         if(dataItemList == null || dataItemList.size() == 0) {
//             throw new CborDeserializationException("NativeScript deserialization failed. Invalid no of DataItem");
//         }

//         int type = ((UnsignedInteger)dataItemList.get(0)).getValue().intValue();
//         if(type == 0) {
//             return ScriptPubkey.deserialize(nativeScriptArray);
//         } else if(type == 1) {
//             return ScriptAll.deserialize(nativeScriptArray);
//         } else if(type == 2) {
//             return ScriptAny.deserialize(nativeScriptArray);
//         } else if(type == 3) {
//             return ScriptAtLeast.deserialize(nativeScriptArray);
//         } else if(type == 4) {
//             return RequireTimeAfter.deserialize(nativeScriptArray);
//         } else if(type ==5) {
//             return RequireTimeBefore.deserialize(nativeScriptArray);
//         } else {
//             return null;
//         }
//     }

//     @JsonIgnore
//     default String getPolicyId() throws CborSerializationException {
//         byte[] first = new byte[]{00};
//         byte[] serializedBytes = this.serialize();
//         byte[] finalBytes = ByteBuffer.allocate(first.length + serializedBytes.length)
//                 .put(first)
//                 .put(serializedBytes)
//                 .array();

//         return Hex.toHexString(blake2bHash224(finalBytes));
//     }

//     @JsonIgnore
//     default byte[] getScriptHash() throws CborSerializationException {
//         byte[] first = new byte[]{00};
//         byte[] serializedBytes = this.serialize();
//         byte[] finalBytes = ByteBuffer.allocate(first.length + serializedBytes.length)
//                 .put(first)
//                 .put(serializedBytes)
//                 .array();

//         return blake2bHash224(finalBytes);
//     }

//     static NativeScript deserializeJson(String jsonContent) throws CborDeserializationException, JsonProcessingException {
//         return NativeScript.deserialize(JsonUtil.parseJson(jsonContent));
//     }

//     static NativeScript deserialize(JsonNode jsonNode) throws CborDeserializationException {
//         String type = jsonNode.get("type").asText();

//         NativeScript nativeScript = null;
//         switch (ScriptType.valueOf(type)) {
//             case sig:
//                 nativeScript = ScriptPubkey.deserialize(jsonNode);
//                 break;
//             case all:
//                 nativeScript = ScriptAll.deserialize(jsonNode);
//                 break;
//             case any:
//                 nativeScript = ScriptAny.deserialize(jsonNode);
//                 break;
//             case atLeast:
//                 nativeScript = ScriptAtLeast.deserialize(jsonNode);
//                 break;
//             case after:
//                 nativeScript = RequireTimeAfter.deserialize(jsonNode);
//                 break;
//             case before:
//                 nativeScript = RequireTimeBefore.deserialize(jsonNode);
//                 break;
//             default:
//                 throw new RuntimeException("Unknow script type");
//         }

//         return nativeScript;
//     }
// }

// public interface Script {

//     DataItem serializeAsDataItem() throws CborSerializationException;

//     default byte[] serialize() throws CborSerializationException {
//         ByteArrayOutputStream baos = new ByteArrayOutputStream();
//         CborBuilder cborBuilder = new CborBuilder();
//         DataItem di = serializeAsDataItem();
//         cborBuilder.add(di);
//         try {
//             new CborEncoder(baos).encode(cborBuilder.build());
//         } catch (CborException e) {
//             throw new CborSerializationException("Cbor serializaion error", e);
//         }
//         byte[] encodedBytes = baos.toByteArray();
//         return encodedBytes;
//     }

//     byte[] getScriptHash() throws CborSerializationException;
// }

// */
