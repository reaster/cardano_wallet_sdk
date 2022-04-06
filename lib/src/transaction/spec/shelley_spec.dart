// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'dart:typed_data';
import 'package:typed_data/typed_data.dart';
import 'package:oxidized/oxidized.dart';
import 'dart:convert' as convertor;
import 'package:cbor/cbor.dart';
import 'package:hex/hex.dart';
import '../../util/blake2bhash.dart';
import '../../util/ada_types.dart';
import '../../util/codec.dart';

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

class CborDeserializationException implements Exception {
} //TODO replace with Result?

/// an single asset name and value under a MultiAsset policyId
class ShelleyAsset {
  final String name;
  final Coin value;

  ShelleyAsset({required this.name, required this.value});
}

/// Native Token multi-asset container.
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
  MapBuilder assetsToCborMap({bool forJson = false}) {
    final mapBuilder = MapBuilder.builder();
    for (var asset in assets) {
      final name = asset.name;
      //final name = forJson && asset.name.isEmpty ? '0' : asset.name; //hack to fix empty keys in toJson
      if (forJson) {
        mapBuilder.writeString(name);
      } else {
        mapBuilder
            .writeBuff(uint8BufferFromHex(name, utf8EncodeOnHexFailure: true));
      }
      mapBuilder.writeInt(asset.value);
    }
    return mapBuilder;
  }
}

/// Points to an UTXO unspent change entry using a transactionId and index.
class ShelleyTransactionInput {
  final String transactionId;
  final int index;

  ShelleyTransactionInput({required this.transactionId, required this.index});

  ListBuilder toCborList({bool forJson = false}) {
    final listBuilder = ListBuilder.builder();
    if (forJson) {
      listBuilder.writeString(transactionId);
    } else {
      listBuilder.writeBuff(uint8BufferFromHex(transactionId));
    }
    listBuilder.writeInt(index);
    return listBuilder;
  }

  factory ShelleyTransactionInput.deserialize({required List cList}) {
    return ShelleyTransactionInput(
        transactionId: HEX.encode(cList[0] as Uint8Buffer),
        index: cList[1] as int);
  }
}

/// Address to send to and amount to send.
class ShelleyTransactionOutput {
  final String address;
  final ShelleyValue value;

  ShelleyTransactionOutput({required this.address, required this.value});

  ListBuilder toCborList({bool forJson = false}) {
    //length should always be 2
    final listBuilder = ListBuilder.builder();
    if (forJson) {
      listBuilder.writeString(address);
    } else {
      listBuilder.writeBuff(unit8BufferFromShelleyAddress(address));
    }
    if (value.multiAssets.isEmpty) {
      //for pure ADA transactions, just write coin value
      listBuilder.writeInt(value.coin);
    } else {
      //for multi-asset, write a list: [coin value, multi-asset map]
      listBuilder.addBuilderOutput(
          value.multiAssetsToCborList(forJson: forJson).getData());
    }
    return listBuilder;
  }

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
      throw CborDeserializationException();
    }
  }
}

/// Can be a simple ADA amount using coin or a combination of ADA and Native Tokens and their amounts.
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

  ListBuilder multiAssetsToCborList({bool forJson = false}) {
    final listBuilder = ListBuilder.builder();
    if (forJson) {
      listBuilder.writeString("$coin");
    } else {
      listBuilder.writeInt(coin);
    }
    final mapBuilder = MapBuilder.builder();
    for (var multiAsset in multiAssets) {
      if (forJson) {
        mapBuilder.writeString(multiAsset.policyId);
      } else {
        mapBuilder.writeBuff(uint8BufferFromHex(multiAsset.policyId));
      }
      mapBuilder.addBuilderOutput(
          multiAsset.assetsToCborMap(forJson: forJson).getData());
    }
    listBuilder.addBuilderOutput(mapBuilder.getData());
    return listBuilder;
  }
}

/// Core of the Shelley transaction that is signed.
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
        .map((i) => ShelleyTransactionInput.deserialize(cList: i as List))
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
  MapBuilder toCborMap({bool forJson = false}) {
    final mapBuilder = MapBuilder.builder();
    //0:inputs
    if (forJson) {
      mapBuilder.writeString('inputs');
    } else {
      mapBuilder.writeInt(0);
    }
    final inListBuilder = ListBuilder.builder();
    for (var input in inputs) {
      inListBuilder
          .addBuilderOutput(input.toCborList(forJson: forJson).getData());
    }
    mapBuilder.addBuilderOutput(inListBuilder.getData());
    //1:outputs
    if (forJson) {
      mapBuilder.writeString('outputs');
    } else {
      mapBuilder.writeInt(1);
    }
    final outListBuilder = ListBuilder.builder();
    for (var output in outputs) {
      outListBuilder
          .addBuilderOutput(output.toCborList(forJson: forJson).getData());
    }
    mapBuilder.addBuilderOutput(outListBuilder.getData());
    //2:fee
    if (forJson) {
      mapBuilder.writeString('fee');
    } else {
      mapBuilder.writeInt(2);
    }
    mapBuilder.writeInt(fee);
    //3:ttl (optional)
    if (ttl != null) {
      if (forJson) {
        mapBuilder.writeString('ttl');
      } else {
        mapBuilder.writeInt(3);
      }
      mapBuilder.writeInt(ttl!);
    }
    //7:metadataHash (optional)
    if (metadataHash != null && metadataHash!.isNotEmpty) {
      if (forJson) {
        mapBuilder.writeString('metadataHash');
        mapBuilder.writeString(HEX.encode(metadataHash!));
      } else {
        mapBuilder.writeInt(7);
        mapBuilder.writeBuff(unit8BufferFromBytes(metadataHash!));
      }
    }
    //8:validityStartInterval (optional)
    if (validityStartInterval != 0) {
      if (forJson) {
        mapBuilder.writeString('validityStartInterval');
      } else {
        mapBuilder.writeInt(8);
      }
      mapBuilder.writeInt(validityStartInterval);
    }
    //9:mint (optional)
    if (mint.isNotEmpty) {
      if (forJson) {
        mapBuilder.writeString('mint');
      } else {
        mapBuilder.writeInt(9);
      }
      final mintMapBuilder = MapBuilder.builder();
      for (var multiAsset in mint) {
        if (forJson) {
          mintMapBuilder.writeString(multiAsset.policyId);
        } else {
          mintMapBuilder.writeBuff(uint8BufferFromHex(multiAsset.policyId));
        }
        mintMapBuilder.addBuilderOutput(
            multiAsset.assetsToCborMap(forJson: forJson).getData());
      }
      mapBuilder.addBuilderOutput(mintMapBuilder.getData());
    }
    return mapBuilder;
  }
}

/// A witness is a public key and a signature (a signed hash of the body) used for on-chain validation.
class ShelleyVkeyWitness {
  final List<int> vkey;
  final List<int> signature;

  ShelleyVkeyWitness({required this.vkey, required this.signature});

  ListBuilder toCborList({bool forJson = false, bool base64 = false}) {
    final listBuilder = ListBuilder.builder();
    if (forJson) {
      if (base64) {
        listBuilder.writeString(convertor.base64.encode(vkey));
        listBuilder.writeString(convertor.base64.encode(signature));
      } else {
        listBuilder.writeString(HEX.encode(vkey));
        listBuilder.writeString(HEX.encode(signature));
      }
    } else {
      listBuilder.writeBuff(unit8BufferFromBytes(vkey));
      listBuilder.writeBuff(unit8BufferFromBytes(signature));
    }
    return listBuilder;
  }

  factory ShelleyVkeyWitness.deserialize({required List cList}) {
    return ShelleyVkeyWitness(vkey: cList[0], signature: cList[1]);
  }
}

/// TODO ShelleyNativeScript is just a place-holder for these concrete classes:
/// ScriptPubkey, ScriptAll, ScriptAny, ScriptAtLeast, RequireTimeAfter, RequireTimeBefore
class ShelleyNativeScript {
  final int selector;
  final List<int> blob;

  ShelleyNativeScript({required this.selector, required this.blob});

  ListBuilder toCborList({bool forJson = false}) {
    final listBuilder = ListBuilder.builder();
    listBuilder.writeInt(selector);
    if (forJson) {
      listBuilder.writeString(HEX.encode(blob));
    } else {
      listBuilder.writeBuff(unit8BufferFromBytes(blob));
    }
    return listBuilder;
  }
}

/// this can be transaction signatures or a full blown smart contract
class ShelleyTransactionWitnessSet {
  final List<ShelleyVkeyWitness> vkeyWitnesses;
  final List<ShelleyNativeScript> nativeScripts;
  ShelleyTransactionWitnessSet(
      {required this.vkeyWitnesses, required this.nativeScripts});
  //    transaction_witness_set =
  //    { ? 0: [* vkeywitness ]
  //  , ? 1: [* native_script ]
  //  , ? 2: [* bootstrap_witness ]
  //        ; In the future, new kinds of witnesses can be added like this:
  //        ; , ? 4: [* foo_script ]
  //        ; , ? 5: [* plutus_script ]
  //    }
  factory ShelleyTransactionWitnessSet.deserialize({required Map cMap}) {
    final witnessSetRawList = cMap[0] != null ? cMap[0] as List : [];
    final List<ShelleyVkeyWitness> vkeyWitnesses = witnessSetRawList
        .map((item) => ShelleyVkeyWitness(vkey: item[0], signature: item[1]))
        .toList();
    final scriptRawList = cMap[1] != null ? cMap[1] as List : [];
    final List<ShelleyNativeScript> nativeScripts = scriptRawList
        .map((item) => ShelleyNativeScript(selector: item[0], blob: item[1]))
        .toList();
    return ShelleyTransactionWitnessSet(
      vkeyWitnesses: vkeyWitnesses,
      nativeScripts: nativeScripts,
    );
  }
  MapBuilder toCborMap({bool forJson = false, bool base64 = false}) {
    final mapBuilder = MapBuilder.builder();
    //0:vkeyWitnesses key
    if (vkeyWitnesses.isNotEmpty) {
      if (forJson) {
        mapBuilder.writeString('vkeyWitnesses');
      } else {
        mapBuilder.writeInt(0);
      }
      final inListBuilder = ListBuilder.builder();
      for (var witness in vkeyWitnesses) {
        inListBuilder.addBuilderOutput(
            witness.toCborList(forJson: forJson, base64: base64).getData());
      }
      mapBuilder.addBuilderOutput(inListBuilder.getData()); //value
    }
    //1:nativeScripts key
    if (nativeScripts.isNotEmpty) {
      if (forJson) {
        mapBuilder.writeString('nativeScripts');
      } else {
        mapBuilder.writeInt(1);
      }
      final outListBuilder = ListBuilder.builder();
      for (var script in nativeScripts) {
        outListBuilder
            .addBuilderOutput(script.toCborList(forJson: forJson).getData());
      }
      mapBuilder.addBuilderOutput(outListBuilder.getData()); //value
    }
    return mapBuilder;
  }
}

/// outer wrapper of a Cardano blockchain transaction.
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
    final codec = Cbor();
    final buff = uint8BufferFromHex(transactionHex);
    codec.decodeFromBuffer(buff);
    final list = codec.getDecodedData()!;
    if (list.length != 1) throw CborDeserializationException();
    final tx = list[0];
    if (tx.length < 3) throw CborDeserializationException();
    final body = tx[0] as Map;
    final witnetssSet = tx[1] as Map;
    final bool? isValid = tx[2] != null || tx[2] is bool ? tx[2] as bool : null;
    final metadata = isValid == null || tx[3] == null ? null : tx[3] as Map;
    return ShelleyTransaction.deserialize(
      cBody: body,
      cWitnessSet: witnetssSet,
      isValid: isValid,
      cMetadata: metadata,
    );
  }
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

  ListBuilder toCborList({bool forJson = false}) {
    final listBuilder = ListBuilder.builder();
    bool base64 = true;
    //body
    listBuilder.addBuilderOutput(body.toCborMap(forJson: forJson).getData());
    //witnessSet
    if (witnessSet == null) {
      listBuilder.writeMap({});
    } else {
      listBuilder.addBuilderOutput(
          witnessSet!.toCborMap(forJson: forJson, base64: base64).getData());
    }
    //isValid
    if (isValid == null) {
      listBuilder.writeNull();
    } else {
      listBuilder.writeBool(isValid ?? true);
    }
    //metadata
    if (metadata == null) {
      listBuilder.writeNull();
    } else {
      listBuilder.addBuilderOutput(metadata!.mapBuilder.getData());
    }
    return listBuilder;
  }

  Uint8List get serialize {
    final Uint8Buffer data = toCborList().getData();
    return Uint8List.view(data.buffer, 0, data.length);
  }
  //List<int> get serialize => toCborList().getData();

  Result<String, String> toJson({bool prettyPrint = false}) {
    try {
      final codec = Cbor()
        ..decodeFromBuffer(toCborList(forJson: true).getData());
      final jsonString = convertor.json.encode(codec.getDecodedData());
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

  String get toCborHex => HEX.encode(serialize);

  @override
  String toString() => HEX.encode(serialize);
}

///
/// Allow arbitrary metadata via raw CBOR type. Use MapBuilder and ListBuilder instances to compose complex nested structures.
///
class CBORMetadata {
  final MapBuilder mapBuilder;

  CBORMetadata(MapBuilder? mapBuilder)
      : mapBuilder = mapBuilder ?? MapBuilder.builder();

  List<int> get serialize {
    final result = Uint8Buffer();
    result.addAll(mapBuilder.getData());
    mapBuilder.clear(); //need to clear to subsequent calls
    return result;
  }

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
