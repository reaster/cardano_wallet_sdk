// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'dart:typed_data';
import 'package:cardano_wallet_sdk/src/transaction/spec/script.dart';
// import 'package:quiver/core.dart';
import 'package:typed_data/typed_data.dart';
import 'package:oxidized/oxidized.dart';
import 'dart:convert' as convertor;
import 'package:cbor/cbor.dart';
import 'package:hex/hex.dart';
import '../../util/blake2bhash.dart';
import '../../util/ada_types.dart';
import '../../util/codec.dart';
import '../model/bc_exception.dart';

///
/// These classes define the data stored on the Cardano blockchain as defined by the shelley.cddl specification.
///
/// Currently this is a hand-coded subset without full plutus core or plutus smart contract coverage.
///
/// translation from java: https://github.com/bloxbean/cardano-client-lib/tree/master/src/main/java/com/bloxbean/cardano/client/transaction/spec
///
/// TODO write a cddl parser based on the ABNF grammar (https://datatracker.ietf.org/doc/html/rfc8610#appendix-B) and combine
/// with Dart generators or https://github.com/reaster/schema-gen to generate these classes.
///

/// an single asset name and value under a MultiAsset policyId
@Deprecated('use bc_tx.dart')
class ShelleyAsset {
  final String name;
  final Coin value;

  ShelleyAsset({required this.name, required this.value});
}

/// Native Token multi-asset container.
@Deprecated('use bc_tx.dart')
class ShelleyMultiAsset {
  final String policyId;
  final List<ShelleyAsset> assets;

  ShelleyMultiAsset({required this.policyId, required this.assets});

  factory ShelleyMultiAsset.deserialize({required MapEntry cMapEntry}) {
    final policyId = hexFromUnit8Buffer(cMapEntry.key as Uint8Buffer);
    final List<ShelleyAsset> assets = [];
    (cMapEntry.value as Map).forEach((key, value) => assets.add(ShelleyAsset(
        name: hexFromUnit8Buffer(key as Uint8Buffer), value: value as int)));
    return ShelleyMultiAsset(policyId: policyId, assets: assets);
  }
  //
  //    h'329728F73683FE04364631C27A7912538C116D802416CA1EAF2D7A96': {h'736174636F696E': 4000},
  //
  CborMap assetsToCborMap({bool forJson = false}) {
    final entries = {
      for (var a in assets)
        CborBytes(uint8BufferFromHex(a.name, utf8EncodeOnHexFailure: true)):
            CborSmallInt(a.value)
    };
    return CborMap({CborBytes(uint8BufferFromHex(policyId)): CborMap(entries)});
  }
  // final entries = <MapEntry<CborValue, CborInt>>[];
  // for (var asset in assets) {
  //   entries.add(MapEntry(
  //     CborBytes(uint8BufferFromHex(asset.name, utf8EncodeOnHexFailure: true)),
  //     CborSmallInt(asset.value),
  // ));
  //final name = asset.name;
  //final name = forJson && asset.name.isEmpty ? '0' : asset.name; //hack to fix empty keys in toJson
  // if (forJson) {
  //   mapBuilder.writeString(name);
  // } else {
  //   mapBuilder
  //       .writeBuff(uint8BufferFromHex(name, utf8EncodeOnHexFailure: true));
  // }
  // mapBuilder.writeInt(asset.value);
  // }
  // return CborMap.fromEntries(entries.iterator);
  // }
}

/// Points to an UTXO unspent change entry using a transactionId and index.
@Deprecated('use bc_tx.dart')
class ShelleyTransactionInput {
  final String transactionId;
  final int index;

  ShelleyTransactionInput({required this.transactionId, required this.index});

  CborValue toCborList({bool forJson = false}) {
    return CborList(
        [CborBytes(uint8ListFromHex(transactionId)), CborSmallInt(index)]);
    // final listBuilder = ListBuilder.builder();
    // if (forJson) {
    //   listBuilder.writeString(transactionId);
    // } else {
    //   listBuilder.writeBuff(uint8BufferFromHex(transactionId));
    // }
    // listBuilder.writeInt(index);
    // return listBuilder;
  }

  factory ShelleyTransactionInput.fromCbor({required CborList list}) {
    return ShelleyTransactionInput(
        transactionId: HEX.encode((list[0] as CborBytes).bytes),
        index: (list[1] as CborSmallInt).toInt());
  }
}

/// Address to send to and amount to send.
@Deprecated('use bc_tx.dart')
@Deprecated('use bc_tx.dart')
class ShelleyTransactionOutput {
  final String address;
  final ShelleyValue value;

  ShelleyTransactionOutput({required this.address, required this.value});

  CborValue toCborList({bool forJson = false}) {
    //length should always be 2
    final addr = CborBytes(unit8BufferFromShelleyAddress(address));
    return CborList([
      addr,
      value.multiAssets.isEmpty
          ? CborSmallInt(value.coin)
          : value.multiAssetsToCborList(forJson: forJson)
    ]);
  }

  // ListBuilder toCborList({bool forJson = false}) {
  //   //length should always be 2
  //   final listBuilder = ListBuilder.builder();
  //   if (forJson) {
  //     listBuilder.writeString(address);
  //   } else {
  //     listBuilder.writeBuff(unit8BufferFromShelleyAddress(address));
  //   }
  //   if (value.multiAssets.isEmpty) {
  //     //for pure ADA transactions, just write coin value
  //     listBuilder.writeInt(value.coin);
  //   } else {
  //     //for multi-asset, write a list: [coin value, multi-asset map]
  //     listBuilder.addBuilderOutput(
  //         value.multiAssetsToCborList(forJson: forJson).getData());
  //   }
  //   return listBuilder;
  // }

  factory ShelleyTransactionOutput.deserialize({required List cList}) {
    final address = bech32ShelleyAddressFromBytes(cList[0] as Uint8Buffer);
    if (cList[1] is int) {
      return ShelleyTransactionOutput(
          address: address,
          value: ShelleyValue(coin: cList[1] as int, multiAssets: []));
    } else if (cList[1] is List) {
      final ShelleyValue value =
          ShelleyValue.deserialize(cList: cList[1] as List);
      return ShelleyTransactionOutput(address: address, value: value);
    } else {
      throw BcCborDeserializationException();
    }
  }
}

/// Can be a simple ADA amount using coin or a combination of ADA and Native Tokens and their amounts.
@Deprecated('use bc_tx.dart')
class ShelleyValue {
  final int coin;
  final List<ShelleyMultiAsset> multiAssets;

  ShelleyValue({required this.coin, required this.multiAssets});

  factory ShelleyValue.deserialize({required List cList}) {
    final List<ShelleyMultiAsset> multiAssets = (cList[1] as Map)
        .entries
        .map((entry) => ShelleyMultiAsset.deserialize(cMapEntry: entry))
        .toList();
    return ShelleyValue(coin: cList[0] as int, multiAssets: multiAssets);
  }
  //
  // [
  //  340000,
  //  {
  //    h'329728F73683FE04364631C27A7912538C116D802416CA1EAF2D7A96': {h'736174636F696E': 4000},
  //    h'6B8D07D69639E9413DD637A1A815A7323C69C86ABBAFB66DBFDB1AA7': {h'': 9000}
  //  }
  // ]
  //

  CborList multiAssetsToCborList({bool forJson = false}) {
    final ma = multiAssets
        .map((m) => m.assetsToCborMap(forJson: forJson))
        .reduce((m1, m2) => m1..addAll(m2));
    return CborList([CborSmallInt(coin), ma]);
  }
  // ListBuilder multiAssetsToCborList({bool forJson = false}) {
  //   final listBuilder = ListBuilder.builder();
  //   if (forJson) {
  //     listBuilder.writeString("$coin");
  //   } else {
  //     listBuilder.writeInt(coin);
  //   }
  //   final mapBuilder = CborValue.builder();
  //   for (var multiAsset in multiAssets) {
  //     if (forJson) {
  //       mapBuilder.writeString(multiAsset.policyId);
  //     } else {
  //       mapBuilder.writeBuff(uint8BufferFromHex(multiAsset.policyId));
  //     }
  //     mapBuilder.addBuilderOutput(
  //         multiAsset.assetsToCborMap(forJson: forJson).getData());
  //   }
  //   listBuilder.addBuilderOutput(mapBuilder.getData());
  //   return listBuilder;
  // }
}

/// Core of the Shelley transaction that is signed.
@Deprecated('use bc_tx.dart')
class ShelleyTransactionBody {
  final List<ShelleyTransactionInput> inputs;
  final List<ShelleyTransactionOutput> outputs;
  final int fee;
  final int? ttl; //Optional
  final List<int>? metadataHash;
  final int validityStartInterval;
  final List<ShelleyMultiAsset> mint;

  ShelleyTransactionBody({
    required this.inputs,
    required this.outputs,
    required this.fee,
    this.ttl,
    this.metadataHash,
    this.validityStartInterval = 0,
    this.mint = const [],
  });

  ShelleyTransactionBody update({
    List<ShelleyTransactionInput>? inputs,
    List<ShelleyTransactionOutput>? outputs,
    int? fee,
    int? ttl,
    List<int>? metadataHash,
    int? validityStartInterval,
    List<ShelleyMultiAsset>? mint,
  }) =>
      ShelleyTransactionBody(
        inputs: inputs ?? this.inputs,
        outputs: outputs ?? this.outputs,
        fee: fee ?? this.fee,
        ttl: ttl ?? this.ttl,
        metadataHash: metadataHash ?? this.metadataHash,
        validityStartInterval:
            validityStartInterval ?? this.validityStartInterval,
        mint: mint ?? this.mint,
      );

  // factory ShelleyTransactionBody.deserialize2(
  //     {required List<ShelleyTransactionInput> inputs,
  //     required List<ShelleyTransactionOutput> outputs,
  //     required int fee,
  //     int? ttl,
  //     List<int>? metadataHash,
  //     int? validityStartInterval,
  //     List<ShelleyMultiAsset>? mint}) {
  //   return ShelleyTransactionBody(
  //     inputs: inputs,
  //     outputs: outputs,
  //     fee: fee,
  //     ttl: ttl,
  //     metadataHash: metadataHash,
  //     validityStartInterval: validityStartInterval ?? 0,
  //     mint: mint ?? [],
  //   );
  // }

  factory ShelleyTransactionBody.deserialize({required Map cMap}) {
    final inputs = (cMap[0] as List)
        .map((i) => ShelleyTransactionInput.fromCbor(list: i as CborList))
        .toList();
    final outputs = (cMap[1] as List)
        .map((i) => ShelleyTransactionOutput.deserialize(cList: i as List))
        .toList();
    final mint = (cMap[9] == null)
        ? null
        : (cMap[9] as Map)
            .entries
            .map((entry) => ShelleyMultiAsset.deserialize(cMapEntry: entry))
            .toList();
    return ShelleyTransactionBody(
      inputs: inputs,
      outputs: outputs,
      fee: cMap[2] as int,
      ttl: cMap[3] == null ? null : cMap[3] as int,
      metadataHash: cMap[7] == null ? null : cMap[7] as List<int>,
      validityStartInterval: cMap[8] == null ? 0 : cMap[8] as int,
      mint: mint ?? [],
    );
  }
  CborValue toCborMap({bool forJson = false}) {
    return CborMap({
      //0:inputs
      const CborSmallInt(0): CborList(
          [for (final input in inputs) input.toCborList(forJson: forJson)]),
      //1:outputs
      const CborSmallInt(1): CborList(
          [for (final output in outputs) output.toCborList(forJson: forJson)]),
      //2:fee
      const CborSmallInt(2): CborSmallInt(fee),
      //3:ttl (optional)
      if (ttl != null) const CborSmallInt(3): CborSmallInt(ttl!),
      //7:metadataHash (optional)
      if (metadataHash != null && metadataHash!.isNotEmpty)
        const CborSmallInt(7): CborBytes(metadataHash!),
      //8:validityStartInterval (optional)
      if (validityStartInterval != 0)
        const CborSmallInt(8): CborSmallInt(validityStartInterval),
      //9:mint (optional)
      if (mint.isNotEmpty)
        const CborSmallInt(9): CborMap(mint
            .map((m) => m.assetsToCborMap(forJson: forJson))
            .reduce((m1, m2) => m1..addAll(m2))),
    });
  }

  // CborValue toCborMap({bool forJson = false}) {
  //   final mapBuilder = CborValue.builder();
  //   //0:inputs
  //   if (forJson) {
  //     mapBuilder.writeString('inputs');
  //   } else {
  //     mapBuilder.writeInt(0);
  //   }
  //   final inListBuilder = ListBuilder.builder();
  //   for (var input in inputs) {
  //     inListBuilder
  //         .addBuilderOutput(input.toCborList(forJson: forJson).getData());
  //   }
  //   mapBuilder.addBuilderOutput(inListBuilder.getData());
  //   //1:outputs
  //   if (forJson) {
  //     mapBuilder.writeString('outputs');
  //   } else {
  //     mapBuilder.writeInt(1);
  //   }
  //   final outListBuilder = ListBuilder.builder();
  //   for (var output in outputs) {
  //     outListBuilder
  //         .addBuilderOutput(output.toCborList(forJson: forJson).getData());
  //   }
  //   mapBuilder.addBuilderOutput(outListBuilder.getData());
  //   //2:fee
  //   if (forJson) {
  //     mapBuilder.writeString('fee');
  //   } else {
  //     mapBuilder.writeInt(2);
  //   }
  //   mapBuilder.writeInt(fee);
  //   //3:ttl (optional)
  //   if (ttl != null) {
  //     if (forJson) {
  //       mapBuilder.writeString('ttl');
  //     } else {
  //       mapBuilder.writeInt(3);
  //     }
  //     mapBuilder.writeInt(ttl!);
  //   }
  //   //7:metadataHash (optional)
  //   if (metadataHash != null && metadataHash!.isNotEmpty) {
  //     if (forJson) {
  //       mapBuilder.writeString('metadataHash');
  //       mapBuilder.writeString(HEX.encode(metadataHash!));
  //     } else {
  //       mapBuilder.writeInt(7);
  //       mapBuilder.writeBuff(unit8BufferFromBytes(metadataHash!));
  //     }
  //   }
  //   //8:validityStartInterval (optional)
  //   if (validityStartInterval != 0) {
  //     if (forJson) {
  //       mapBuilder.writeString('validityStartInterval');
  //     } else {
  //       mapBuilder.writeInt(8);
  //     }
  //     mapBuilder.writeInt(validityStartInterval);
  //   }
  //   //9:mint (optional)
  //   if (mint.isNotEmpty) {
  //     if (forJson) {
  //       mapBuilder.writeString('mint');
  //     } else {
  //       mapBuilder.writeInt(9);
  //     }
  //     final mintMapBuilder = CborValue.builder();
  //     for (var multiAsset in mint) {
  //       if (forJson) {
  //         mintMapBuilder.writeString(multiAsset.policyId);
  //       } else {
  //         mintMapBuilder.writeBuff(uint8BufferFromHex(multiAsset.policyId));
  //       }
  //       mintMapBuilder.addBuilderOutput(
  //           multiAsset.assetsToCborMap(forJson: forJson).getData());
  //     }
  //     mapBuilder.addBuilderOutput(mintMapBuilder.getData());
  //   }
  //   return mapBuilder;
  // }
}

/// A witness is a public key and a signature (a signed hash of the body) used for on-chain validation.
@Deprecated('use bc_tx.dart')
class ShelleyVkeyWitness {
  final List<int> vkey;
  final List<int> signature;

  ShelleyVkeyWitness({required this.vkey, required this.signature});

  CborList toCborList({bool forJson = false, bool base64 = false}) {
    return CborList([CborBytes(vkey), CborBytes(signature)]);
  }

  // ListBuilder toCborList({bool forJson = false, bool base64 = false}) {
  //   final listBuilder = ListBuilder.builder();
  //   if (forJson) {
  //     if (base64) {
  //       listBuilder.writeString(convertor.base64.encode(vkey));
  //       listBuilder.writeString(convertor.base64.encode(signature));
  //     } else {
  //       listBuilder.writeString(HEX.encode(vkey));
  //       listBuilder.writeString(HEX.encode(signature));
  //     }
  //   } else {
  //     listBuilder.writeBuff(unit8BufferFromBytes(vkey));
  //     listBuilder.writeBuff(unit8BufferFromBytes(signature));
  //   }
  //   return listBuilder;
  // }

  factory ShelleyVkeyWitness.deserialize({required List cList}) {
    return ShelleyVkeyWitness(vkey: cList[0], signature: cList[1]);
  }
}

// enum ScriptType { sig, all, any, atLeast, after, before }

// /// TODO ShelleyNativeScript and friends - test serializaton:

// abstract class ShelleyNativeScript {
//   //final List blob;

//   ScriptType get type;

//   Uint8List get serialize {
//     final Uint8Buffer data = toCborList().getData();
//     return Uint8List.view(data.buffer, 0, data.length);
//   }

//   ShelleyNativeScript();

//   static ShelleyNativeScript deserialize(List list) {
//     final type = ScriptType.values[list[0] as int];
//     switch (type) {
//       case ScriptType.sig:
//         return ShelleyScriptPubkey(keyHash: list[1] as String);
//       case ScriptType.all:
//         return ShelleyScriptAll(blob: list[1] as List);
//       case ScriptType.any:
//         return ShelleScriptAny(blob: list[1] as List);
//       case ScriptType.atLeast:
//         return ShelleScriptAtLeast(blob: list[1] as List);
//       case ScriptType.after:
//         return ShelleRequireTimeAfter(blob: list[1] as List);
//       case ScriptType.before:
//         return ShelleRequireTimeBefore(blob: list[1] as List);
//       default:
//         throw CborDeserializationException();
//     }
//   }

// /*
//       static NativeScript deserialize(Array nativeScriptArray) throws CborDeserializationException {
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
// */

//   ListBuilder toCborList({bool forJson = false}) {
//     final listBuilder = ListBuilder.builder();
//     listBuilder.writeInt(type.index);
//     if (forJson) {
//       listBuilder.writeString(HEX.encode(blob));
//     } else {
//       listBuilder.writeBuff(unit8BufferFromBytes(blob));
//     }
//     return listBuilder;
//   }

//   String get toHex => HEX.encode(serialize);

//   @override
//   String toString() => toHex;

//   @override
//   int get hashCode => hashObjects(blob);

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is ShelleyNativeScript &&
//           runtimeType == other.runtimeType &&
//           blob.length == other.blob.length &&
//           _equalBlobs(blob, other.blob);

//   bool _equalBlobs(List<int> a, List<int> b) {
//     for (var i = 0; i < a.length; i++) {
//       if (a[i] != b[i]) return false;
//     }
//     return true;
//   }

//   // bool _equalBytes(Uint8List a, Uint8List b) {
//   //   for (var i = 0; i < a.length; i++) {
//   //     if (a[i] != b[i]) return false;
//   //   }
//   //   return true;
//   // }

//   String get policyId => HEX.encode(blake2bHash224([
//         ...[0],
//         ...serialize
//       ]));

//   Uint8List get scriptHash => Uint8List.fromList(blake2bHash224([
//         ...[0],
//         ...serialize
//       ]));

//   /*
//           default byte[] getScriptHash() throws CborSerializationException {
//         byte[] first = new byte[]{00};
//         byte[] serializedBytes = this.serialize();
//         byte[] finalBytes = ByteBuffer.allocate(first.length + serializedBytes.length)
//                 .put(first)
//                 .put(serializedBytes)
//                 .array();

//         return blake2bHash224(finalBytes);
//     }
//       */
// }

// class ShelleyScriptPubkey extends ShelleyNativeScript {
//   final String keyHash;
//   @override
//   final ScriptType type = ScriptType.sig;

//   ShelleyScriptPubkey({required this.keyHash});

//   factory ShelleyScriptPubkey.deserialize(List list) {
//     final keyHash = list[1] as String;
//     return ShelleyScriptPubkey(keyHash: keyHash);
//   }

//   ListBuilder toCborList({bool forJson = false}) {
//     final listBuilder = ListBuilder.builder();
//     listBuilder.writeInt(type.index);
//     listBuilder
//       .writeBuff(uint8BufferFromHex(keyHash, utf8EncodeOnHexFailure: true));
//     return listBuilder;
//   }
//   // public static ScriptPubkey deserialize(Array array) throws CborDeserializationException {
//   //     ScriptPubkey scriptPubkey = new ScriptPubkey();
//   //     ByteString keyHashBS = (ByteString)(array.getDataItems().get(1));
//   //     scriptPubkey.setKeyHash(HexUtil.encodeHexString(keyHashBS.getBytes()));
//   //     return scriptPubkey;
//   // }

// }

// class ShelleyScriptAll extends ShelleyNativeScript {
//   @override
//   final ScriptType type = ScriptType.all;

//   ShelleyScriptAll({required super.blob});
// }

// class ShelleScriptAny extends ShelleyNativeScript {
//   @override
//   final ScriptType type = ScriptType.any;

//   ShelleScriptAny({required super.blob});
// }

// class ShelleScriptAtLeast extends ShelleyNativeScript {
//   @override
//   final ScriptType type = ScriptType.atLeast;

//   ShelleScriptAtLeast({required super.blob});
// }

// class ShelleRequireTimeAfter extends ShelleyNativeScript {
//   @override
//   final ScriptType type = ScriptType.after;

//   ShelleRequireTimeAfter({required super.blob});
// }

// class ShelleRequireTimeBefore extends ShelleyNativeScript {
//   @override
//   final ScriptType type = ScriptType.before;

//   ShelleRequireTimeBefore({required super.blob});
// }

// DataItem vkWitnessesArray = witnessMap.get(new UnsignedInteger(0));
// DataItem nativeScriptArray = witnessMap.get(new UnsignedInteger(1));
// DataItem bootstrapWitnessArray = witnessMap.get(new UnsignedInteger(2));
// DataItem plutusScriptArray = witnessMap.get(new UnsignedInteger(3));
// DataItem plutusDataArray = witnessMap.get(new UnsignedInteger(4));
// DataItem redeemerArray = witnessMap.get(new UnsignedInteger(5));

enum WitnessSetType {
  verificationKey,
  nativeScript,
  bootstrap,
  plutusScript,
  plutusData,
  redeemer
}

/// this can be transaction signatures or a full blown smart contract
@Deprecated('use bc_tx.dart')
class ShelleyTransactionWitnessSet {
  final List<ShelleyVkeyWitness> vkeyWitnesses;
  final List<NativeScript> nativeScripts;
  ShelleyTransactionWitnessSet(
      {required this.vkeyWitnesses, required this.nativeScripts});
  // transaction_witness_set =
  //  { ? 0: [* vkeywitness ]
  //  , ? 1: [* native_script ]
  //  , ? 2: [* bootstrap_witness ]
  //  In the future, new kinds of witnesses can be added like this:
  //  , ? 4: [* foo_script ]
  //  , ? 5: [* plutus_script ]
  //    }
  factory ShelleyTransactionWitnessSet.deserialize({required Map cMap}) {
    final witnessSetRawList = cMap[0] == null ? [] : cMap[0] as List;
    final List<ShelleyVkeyWitness> vkeyWitnesses = witnessSetRawList
        .map((item) => ShelleyVkeyWitness(vkey: item[0], signature: item[1]))
        .toList();
    final scriptRawList = cMap[1] == null ? [] : cMap[1] as List;
    final List<NativeScript> nativeScripts =
        scriptRawList.map((list) => NativeScript.fromCbor(list: list)).toList();
    return ShelleyTransactionWitnessSet(
      vkeyWitnesses: vkeyWitnesses,
      nativeScripts: nativeScripts,
    );
  }
  CborValue toCborMap({bool forJson = false, bool base64 = false}) {
    return CborMap({
      //0:verificationKey key
      if (vkeyWitnesses.isNotEmpty)
        CborSmallInt(WitnessSetType.verificationKey.index): CborList.of(
            vkeyWitnesses.map((w) => w.toCborList(forJson: forJson))),
      //1:nativeScript key
      if (nativeScripts.isNotEmpty)
        CborSmallInt(WitnessSetType.nativeScript.index): CborList.of(
            nativeScripts.map((w) => w.toCborList(forJson: forJson))),
    });
  }
}

/// outer wrapper of a Cardano blockchain transaction.
@Deprecated('use bc_tx.dart')
class ShelleyTransaction {
  late final ShelleyTransactionBody body;
  final ShelleyTransactionWitnessSet? witnessSet;
  final bool? isValid;
  final CBORMetadata? metadata;

  ShelleyTransaction(
      {required ShelleyTransactionBody body,
      this.witnessSet,
      this.isValid = true,
      this.metadata})
      : body = ShelleyTransactionBody(
          //rebuild body to include metadataHash
          inputs: body.inputs,
          outputs: body.outputs,
          fee: body.fee,
          ttl: body.ttl,
          metadataHash:
              metadata?.hash, //optionally add hash if metadata present
          validityStartInterval: body.validityStartInterval,
          mint: body.mint,
        );
  factory ShelleyTransaction.deserializeFromHex(String transactionHex) {
    // final codec = Cbor();
    // final buff = uint8BufferFromHex(transactionHex);
    // codec.decodeFromBuffer(buff);
    // final list = codec.getDecodedData()!;
    // if (list.length != 1) throw CborDeserializationException();
    // final tx = list[0];
    // if (tx.length < 3) throw CborDeserializationException();
    final body = Map(); //tx[0] as Map;
    final witnetssSet = Map(); //= tx[1] as Map;
    final bool? isValid = true;
    //tx[2] != null || tx[2] is bool ? tx[2] as bool : null;
    final metadata = null;
    //isValid == null || tx[3] == null ? null : tx[3] as Map;
    return ShelleyTransaction.deserialize(
      cBody: body,
      cWitnessSet: witnetssSet,
      isValid: isValid,
      cMetadata: metadata,
    );
  }
  // factory ShelleyTransaction.deserializeFromHex(String transactionHex) {
  //   final codec = Cbor();
  //   final buff = uint8BufferFromHex(transactionHex);
  //   codec.decodeFromBuffer(buff);
  //   final list = codec.getDecodedData()!;
  //   if (list.length != 1) throw CborDeserializationException();
  //   final tx = list[0];
  //   if (tx.length < 3) throw CborDeserializationException();
  //   final body = tx[0] as Map;
  //   final witnetssSet = tx[1] as Map;
  //   final bool? isValid = tx[2] != null || tx[2] is bool ? tx[2] as bool : null;
  //   final metadata = isValid == null || tx[3] == null ? null : tx[3] as Map;
  //   return ShelleyTransaction.deserialize(
  //     cBody: body,
  //     cWitnessSet: witnetssSet,
  //     isValid: isValid,
  //     cMetadata: metadata,
  //   );
  // }
  factory ShelleyTransaction.deserialize(
      {required Map cBody,
      required Map cWitnessSet,
      required bool? isValid,
      Map? cMetadata}) {
    final body = ShelleyTransactionBody.deserialize(cMap: cBody);
    final ShelleyTransactionWitnessSet witnessSet =
        ShelleyTransactionWitnessSet.deserialize(cMap: cWitnessSet);
    //if (MajorType.MAP.equals(metadata.getMajorType())) { //Metadata available
    final CBORMetadata? metadata = cMetadata == null ? null : null; //TODO
    return ShelleyTransaction(
      body: body,
      witnessSet: witnessSet,
      isValid: isValid,
      metadata: metadata,
    );
  }

  CborList toCborList({bool forJson = false}) {
    return CborList([
      //body
      body.toCborMap(),
      //witnessSet
      witnessSet != null ? witnessSet!.toCborMap() : CborMap({}),
      //isValid
      if (isValid != null) CborBool(isValid ?? true),
      //metadata
      (metadata != null && metadata!.cborValue != null)
          ? metadata!.cborValue!
          : const CborNull(),
    ]);
  }

  // ListBuilder toCborList({bool forJson = false}) {
  //   final listBuilder = ListBuilder.builder();
  //   bool base64 = true;
  //   //body
  //   listBuilder.addBuilderOutput(body.toCborMap(forJson: forJson).getData());
  //   //witnessSet
  //   if (witnessSet == null) {
  //     listBuilder.writeMap({});
  //   } else {
  //     listBuilder.addBuilderOutput(
  //         witnessSet!.toCborMap(forJson: forJson, base64: base64).getData());
  //   }
  //   //isValid
  //   if (isValid == null) {
  //     listBuilder.writeNull();
  //   } else {
  //     listBuilder.writeBool(isValid ?? true);
  //   }
  //   //metadata
  //   if (metadata == null) {
  //     listBuilder.writeNull();
  //   } else {
  //     listBuilder.addBuilderOutput(metadata!.mapBuilder.getData());
  //   }
  //   return listBuilder;
  // }

  Uint8List get serialize {
    final Uint8Buffer data = Uint8Buffer()..addAll(cbor.encode(toCborList()));
    return Uint8List.view(data.buffer, 0, data.length);
  }
  //List<int> get serialize => toCborList().getData();

  Result<String, String> toJson({bool prettyPrint = false}) {
    try {
      final jsonString =
          const CborJsonEncoder().convert(toCborList(forJson: true));
      // Remove the [] from the JSON string
      final result = jsonString.substring(1, jsonString.length - 1);
      if (prettyPrint) {
        const toJsonFromString = convertor.JsonDecoder();
        final json = toJsonFromString.convert(jsonString);
        const encoder = convertor.JsonEncoder.withIndent('  ');
        final formattedJson = encoder.convert(json);
        return Ok(formattedJson);
      } else {
        return Ok(result);
      }
    } on Exception catch (e) {
      return Err(e.toString());
    }
  }
  // Result<String, String> toJson({bool prettyPrint = false}) {
  //   try {
  //     final codec = Cbor()
  //       ..decodeFromBuffer(toCborList(forJson: true).getData());
  //     final jsonString = convertor.json.encode(codec.getDecodedData());
  //     // Remove the [] from the JSON string
  //     final result = jsonString.substring(1, jsonString.length - 1);
  //     if (prettyPrint) {
  //       const toJsonFromString = convertor.JsonDecoder();
  //       final json = toJsonFromString.convert(jsonString);
  //       const encoder = convertor.JsonEncoder.withIndent('  ');
  //       final formattedJson = encoder.convert(json);
  //       return Ok(formattedJson);
  //     } else {
  //       return Ok(result);
  //     }
  //   } on Exception catch (e) {
  //     return Err(e.toString());
  //   }
  // }

  String get toCborHex => HEX.encode(serialize);

  @override
  String toString() => HEX.encode(serialize);
}

///
/// Allow arbitrary metadata via raw CBOR type. Use CborValue and ListBuilder instances to compose complex nested structures.
///
@Deprecated('use bc_tx.dart')
class CBORMetadata {
  final CborValue? cborValue;

  CBORMetadata(this.cborValue);

  List<int> get serialize {
    final result = Uint8Buffer();
    if (cborValue != null) {
      result.addAll(cbor.encode(cborValue!));
    }
    //mapBuilder.clear(); //need to clear to subsequent calls
    return result;
  }

  // final CborValue mapBuilder;

  // CBORMetadata(CborValue? mapBuilder)
  //     : mapBuilder = mapBuilder ?? CborValue.builder();

  // List<int> get serialize {
  //   final result = Uint8Buffer();
  //   result.addAll(mapBuilder.getData());
  //   mapBuilder.clear(); //need to clear to subsequent calls
  //   return result;
  // }

  String get toCborHex => HEX.encode(serialize);

  List<int> get hash => blake2bHash256(serialize);
}

// reference shelley.cddl type from:
// https://github.com/bloxbean/cardano-serialization-lib/blob/8c0f517ec39c333369462659b6c350223619973b/specs/shelley.cddl
//
// ; Shelley Types

// block =
//   [ header
//   , transaction_bodies         : [* transaction_body]
//   , transaction_witness_sets   : [* transaction_witness_set]
//   , transaction_metadata_set   : { * uint => transaction_metadata }
//   ]

// header =
//   ( header_body
//   , body_signature : $kes_signature
//   )

// header_body =
//   ( prev_hash        : $hash
//   , issuer_vkey      : $vkey
//   , vrf_vkey         : $vrf_vkey
//   , slot             : uint
//   , nonce            : uint
//   , nonce_proof      : $vrf_proof
//   , leader_value     : unit_interval
//   , leader_proof     : $vrf_proof
//   , size             : uint
//   , block_number     : uint
//   , block_body_hash  : $hash            ; merkle pair root
//   , operational_cert
//   , protocol_version
//   )

// operational_cert =
//   ( hot_vkey        : $kes_vkey
//   , cold_vkey       : $vkey
//   , sequence_number : uint
//   , kes_period      : uint
//   , sigma           : $signature
//   )

// protocol_version = (uint, uint, uint)

// ; Do we want to use a Map here? Is it actually cheaper?
// ; Do we want to add extension points here?
// transaction_body =
//   { 0 : #6.258([* transaction_input])
//   , 1 : [* transaction_output]
//   , ? 2 : [* delegation_certificate]
//   , ? 3 : withdrawals
//   , 4 : coin ; fee
//   , 5 : uint ; ttl
//   , ? 6 : full_update
//   , ? 7 : metadata_hash
//   }

// ; Is it okay to have this as a group? Is it valid CBOR?! Does it need to be?
// transaction_input = [transaction_id : $hash, index : uint]

// transaction_output = [address, amount : uint]

// address =
//  (  0, keyhash, keyhash       ; base address
//  // 1, keyhash, scripthash    ; base address
//  // 2, scripthash, keyhash    ; base address
//  // 3, scripthash, scripthash ; base address
//  // 4, keyhash, pointer       ; pointer address
//  // 5, scripthash, pointer    ; pointer address
//  // 6, keyhash                ; enterprise address (null staking reference)
//  // 7, scripthash             ; enterprise address (null staking reference)
//  // 8, keyhash                ; bootstrap address
//  )

// delegation_certificate =
//   [( 0, keyhash                       ; stake key registration
//   // 1, scripthash                    ; stake script registration
//   // 2, keyhash                       ; stake key de-registration
//   // 3, scripthash                    ; stake script de-registration
//   // 4                                ; stake key delegation
//       , keyhash                       ; delegating key
//       , keyhash                       ; key delegated to
//   // 5                                ; stake script delegation
//       , scripthash                    ; delegating script
//       , keyhash                       ; key delegated to
//   // 6, keyhash, pool_params          ; stake pool registration
//   // 7, keyhash, epoch                ; stake pool retirement
//   // 8                                ; genesis key delegation
//       , genesishash                   ; delegating key
//       , keyhash                       ; key delegated to
//   // 9, move_instantaneous_reward ; move instantaneous rewards
//  ) ]

// move_instantaneous_reward = { * keyhash => coin }
// pointer = (uint, uint, uint)

// credential =
//   (  0, keyhash
//   // 1, scripthash
//   // 2, genesishash
//   )

// pool_params = ( #6.258([* keyhash]) ; pool owners
//               , coin                ; cost
//               , unit_interval       ; margin
//               , coin                ; pledge
//               , keyhash             ; operator
//               , $vrf_keyhash        ; vrf keyhash
//               , [credential]        ; reward account
//               )

// withdrawals = { * [credential] => coin }

// full_update = [ protocol_param_update_votes, application_version_update_votes ]

// protocol_param_update_votes =
//   { * genesishash => protocol_param_update }

// protocol_param_update =
//   { ? 0:  uint               ; minfee A
//   , ? 1:  uint               ; minfee B
//   , ? 2:  uint               ; max block body size
//   , ? 3:  uint               ; max transaction size
//   , ? 4:  uint               ; max block header size
//   , ? 5:  coin               ; key deposit
//   , ? 6:  unit_interval      ; key deposit min refund
//   , ? 7:  rational           ; key deposit decay rate
//   , ? 8:  coin               ; pool deposit
//   , ? 9:  unit_interval      ; pool deposit min refund
//   , ? 10: rational           ; pool deposit decay rate
//   , ? 11: epoch              ; maximum epoch
//   , ? 12: uint               ; n_optimal. desired number of stake pools
//   , ? 13: rational           ; pool pledge influence
//   , ? 14: unit_interval      ; expansion rate
//   , ? 15: unit_interval      ; treasury growth rate
//   , ? 16: unit_interval      ; active slot coefficient
//   , ? 17: unit_interval      ; d. decentralization constant
//   , ? 18: uint               ; extra entropy
//   , ? 19: [protocol_version] ; protocol version
//   }

// application_version_update_votes = { * genesishash => application_version_update }

// application_version_update = { * application_name =>  [uint, application_metadata] }

// application_metadata = { * system_tag => installerhash }

// application_name = tstr .size 12
// system_tag = tstr .size 10

// transaction_witness_set =
//   (  0, vkeywitness
//   // 1, $script
//   // 2, [* vkeywitness]
//   // 3, [* $script]
//   // 4, [* vkeywitness],[* $script]
//   )

// transaction_metadata =
//     { * transaction_metadata => transaction_metadata }
//   / [ * transaction_metadata ]
//   / int
//   / bytes
//   / text

// vkeywitness = [$vkey, $signature]

// unit_interval = rational

// rational =  #6.30(
//    [ numerator   : uint
//    , denominator : uint
//    ])

// coin = uint
// epoch = uint

// keyhash = $hash

// scripthash = $hash

// genesishash = $hash

// installerhash = $hash

// metadata_hash = $hash

// $hash /= bytes

// $vkey /= bytes

// $signature /= bytes

// $vrf_keyhash /= bytes

// $vrf_vkey /= bytes
// $vrf_proof /= bytes

// $kes_vkey /= bytes

// $kes_signature /= bytes

// import 'dart:typed_data';
