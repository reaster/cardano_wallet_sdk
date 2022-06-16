import 'dart:typed_data';
import 'package:cbor/cbor.dart';
import 'package:hex/hex.dart';
// import 'package:typed_data/typed_buffers.dart';
import '../../util/ada_types.dart';
import '../../util/blake2bhash.dart';
import '../../util/codec.dart';
import 'bc_exception.dart';
import 'bc_abstract.dart';
import 'bc_scripts.dart';

class BcAsset {
  final String name;
  final int value;

  BcAsset({required this.name, required this.value});

  @override
  String toString() {
    return 'BcAsset(name: $name, value: $value)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BcAsset &&
            other.name == name &&
            other.value == value);
  }

  @override
  int get hashCode => Object.hash(runtimeType, name, value);
}

class BcMultiAsset extends BcAbstractCbor {
  final String policyId;
  final List<BcAsset> assets;

  BcMultiAsset({
    required this.policyId,
    required this.assets,
  });

  factory BcMultiAsset.fromCbor({required MapEntry mapEntry}) {
    final policyId = HEX.encode((mapEntry.key as CborBytes).bytes);
    final List<BcAsset> assets = [];
    (mapEntry.value as Map).forEach((key, value) => assets.add(BcAsset(
        name: HEX.encode((key as CborBytes).bytes),
        value: (value as CborInt).toInt())));
    return BcMultiAsset(policyId: policyId, assets: assets);
  }

  //
  //    h'329728F73683FE04364631C27A7912538C116D802416CA1EAF2D7A96': {h'736174636F696E': 4000},
  //
  CborMap toCborMap() {
    final entries = {
      for (var a in assets)
        CborBytes(uint8BufferFromHex(a.name, utf8EncodeOnHexFailure: true)):
            CborSmallInt(a.value)
    };
    return CborMap({CborBytes(uint8BufferFromHex(policyId)): CborMap(entries)});
  }

  @override
  Uint8List get serialize => toUint8List(toCborMap());

  @override
  String toString() {
    return 'BcMultiAsset(policyId: $policyId, assets: $assets)';
  }
}

/// Points to an UTXO unspent change entry using a transactionId and index.
class BcTransactionInput extends BcAbstractCbor {
  final String transactionId;
  final int index;
  BcTransactionInput({
    required this.transactionId,
    required this.index,
  });

  factory BcTransactionInput.fromCbor({required CborList list}) {
    return BcTransactionInput(
        transactionId: HEX.encode((list[0] as CborBytes).bytes),
        index: (list[1] as CborSmallInt).toInt());
  }

  CborList toCborList() {
    return CborList(
        [CborBytes(HEX.decode(transactionId)), CborSmallInt(index)]);
  }

  @override
  Uint8List get serialize => toUint8List(toCborList());

  @override
  String toString() {
    return 'BcTransactionInput(transactionId: $transactionId, index: $index)';
  }
}

/// Can be a simple ADA amount using coin or a combination of ADA and Native Tokens and their amounts.
class BcValue extends BcAbstractCbor {
  final Coin coin;
  final List<BcMultiAsset> multiAssets;
  BcValue({
    required this.coin,
    required this.multiAssets,
  });

  factory BcValue.fromCbor({required CborList list}) {
    final List<BcMultiAsset> multiAssets = (list[1] as CborMap)
        .entries
        .map((entry) => BcMultiAsset.fromCbor(mapEntry: entry))
        .toList();
    return BcValue(
        coin: (list[0] as CborInt).toInt(), multiAssets: multiAssets);
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
  CborList toCborList() {
    final ma = multiAssets
        .map((m) => m.toCborMap())
        .reduce((m1, m2) => m1..addAll(m2));
    return CborList([CborSmallInt(coin), ma]);
  }

  @override
  Uint8List get serialize => toUint8List(toCborList());

  @override
  String toString() {
    return 'BcValue(coin: $coin, multiAssets: $multiAssets)';
  }
}

/// Address to send to and amount to send.
class BcTransactionOutput extends BcAbstractCbor {
  final String address;
  final BcValue value;
  BcTransactionOutput({
    required this.address,
    required this.value,
  });

  factory BcTransactionOutput.fromCbor({required CborList list}) {
    final address =
        bech32ShelleyAddressFromIntList((list[0] as CborBytes).bytes);
    if (list[1] is CborInt) {
      return BcTransactionOutput(
          address: address,
          value: BcValue(coin: (list[1] as CborInt).toInt(), multiAssets: []));
    } else if (list[1] is CborList) {
      final BcValue value = BcValue.fromCbor(list: list[1] as CborList);
      return BcTransactionOutput(address: address, value: value);
    } else {
      throw BcCborDeserializationException();
    }
  }

  CborList toCborList() {
    //length should always be 2
    return CborList([
      CborBytes(unit8BufferFromShelleyAddress(address)),
      value.multiAssets.isEmpty ? CborSmallInt(value.coin) : value.toCborList()
    ]);
  }

  @override
  Uint8List get serialize => toUint8List(toCborList());

  @override
  String toString() {
    return 'BcTransactionOutput(address: $address, value: $value)';
  }
}

/// Core of the Shelley transaction that is signed.
class BcTransactionBody extends BcAbstractCbor {
  final List<BcTransactionInput> inputs;
  final List<BcTransactionOutput> outputs;
  final int fee;
  final int? ttl; //Optional
  final List<int>? metadataHash; //Optional
  final int validityStartInterval;
  final List<BcMultiAsset> mint;

  BcTransactionBody({
    required this.inputs,
    required this.outputs,
    required this.fee,
    this.ttl, //Optional
    this.metadataHash, //Optional
    this.validityStartInterval = 0,
    this.mint = const [],
  });

  factory BcTransactionBody.fromCbor({required CborMap map}) {
    final inputs = (map[const CborSmallInt(0)] as CborList)
        .map((i) => BcTransactionInput.fromCbor(list: i as CborList))
        .toList();
    final outputs = (map[const CborSmallInt(1)] as CborList)
        .map((i) => BcTransactionOutput.fromCbor(list: i as CborList))
        .toList();
    final mint = (map[const CborSmallInt(9)] == null)
        ? null
        : (map[const CborSmallInt(9)] as CborMap)
            .entries
            .map((entry) => BcMultiAsset.fromCbor(mapEntry: entry))
            .toList();
    return BcTransactionBody(
      inputs: inputs,
      outputs: outputs,
      fee: (map[const CborSmallInt(2)] as CborInt).toInt(),
      ttl: map[const CborSmallInt(3)] == null
          ? null
          : (map[const CborSmallInt(3)] as CborInt).toInt(),
      metadataHash: map[const CborSmallInt(7)] == null
          ? null
          : (map[const CborSmallInt(7)] as CborBytes).bytes,
      validityStartInterval: map[const CborSmallInt(8)] == null
          ? 0
          : (map[const CborSmallInt(8)] as CborInt).toInt(),
      mint: mint ?? [],
    );
  }

  CborMap toCborMap() {
    return CborMap({
      //0:inputs
      const CborSmallInt(0):
          CborList([for (final input in inputs) input.toCborList()]),
      //1:outputs
      const CborSmallInt(1):
          CborList([for (final output in outputs) output.toCborList()]),
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
        const CborSmallInt(9): CborMap(
            mint.map((m) => m.toCborMap()).reduce((m1, m2) => m1..addAll(m2))),
    });
  }

  @override
  Uint8List get serialize => toUint8List(toCborMap());

  BcTransactionBody update({
    List<BcTransactionInput>? inputs,
    List<BcTransactionOutput>? outputs,
    int? fee,
    int? ttl,
    List<int>? metadataHash,
    int? validityStartInterval,
    List<BcMultiAsset>? mint,
  }) =>
      BcTransactionBody(
        inputs: inputs ?? this.inputs,
        outputs: outputs ?? this.outputs,
        fee: fee ?? this.fee,
        ttl: ttl ?? this.ttl,
        metadataHash: metadataHash ?? this.metadataHash,
        validityStartInterval:
            validityStartInterval ?? this.validityStartInterval,
        mint: mint ?? this.mint,
      );

  @override
  String toString() {
    return 'BcTransactionBody(inputs: $inputs, outputs: $outputs, fee: $fee, ttl: $ttl, metadataHash: $metadataHash, validityStartInterval: $validityStartInterval, mint: $mint)';
  }
}

/// A witness is a public key and a signature (a signed hash of the body) used for on-chain validation.
class BcVkeyWitness extends BcAbstractCbor {
  final List<int> vkey;
  final List<int> signature;
  BcVkeyWitness({
    required this.vkey,
    required this.signature,
  });

  factory BcVkeyWitness.fromCbor({required CborList list}) {
    return BcVkeyWitness(
        vkey: (list[0] as CborBytes).bytes,
        signature: (list[1] as CborBytes).bytes);
  }

  CborList toCborList() {
    return CborList([CborBytes(vkey), CborBytes(signature)]);
  }

  @override
  Uint8List get serialize => toUint8List(toCborList());

  @override
  String toString() {
    return 'BcVkeyWitness(vkey: $vkey, signature: $signature)';
  }
}

enum BcWitnessSetType {
  verificationKey,
  nativeScript,
  bootstrap,
  plutusScript,
  plutusData,
  redeemer
}

/// this can be transaction signatures or a full blown smart contract
class BcTransactionWitnessSet extends BcAbstractCbor {
  final List<BcVkeyWitness> vkeyWitnesses;
  final List<BcNativeScript> nativeScripts;
  BcTransactionWitnessSet({
    required this.vkeyWitnesses,
    required this.nativeScripts,
  });

  // transaction_witness_set =
  //  { ? 0: [* vkeywitness ]
  //  , ? 1: [* native_script ]
  //  , ? 2: [* bootstrap_witness ]
  //  In the future, new kinds of witnesses can be added like this:
  //  , ? 4: [* foo_script ]
  //  , ? 5: [* plutus_script ]
  //    }
  factory BcTransactionWitnessSet.fromCbor({required CborMap map}) {
    final witnessSetRawList = map[0] == null ? [] : (map[0] as CborList);
    final List<BcVkeyWitness> vkeyWitnesses = witnessSetRawList
        .map((item) => BcVkeyWitness(vkey: item[0], signature: item[1]))
        .toList();
    final scriptRawList = map[1] == null ? [] : map[1] as List;
    final List<BcNativeScript> nativeScripts = scriptRawList
        .map((list) => BcNativeScript.fromCbor(list: list))
        .toList();
    return BcTransactionWitnessSet(
      vkeyWitnesses: vkeyWitnesses,
      nativeScripts: nativeScripts,
    );
  }

  CborValue toCborMap() {
    return CborMap({
      //0:verificationKey key
      if (vkeyWitnesses.isNotEmpty)
        CborSmallInt(BcWitnessSetType.verificationKey.index):
            CborList.of(vkeyWitnesses.map((w) => w.toCborList())),
      //1:nativeScript key
      if (nativeScripts.isNotEmpty)
        CborSmallInt(BcWitnessSetType.nativeScript.index):
            CborList.of(nativeScripts.map((s) => s.toCborList())),
    });
  }

  bool get isEmpty => vkeyWitnesses.isEmpty && nativeScripts.isEmpty;
  bool get isNotEmpty => !isEmpty;

  @override
  Uint8List get serialize => toUint8List(toCborMap());

  @override
  String toString() {
    return 'BcTransactionWitnessSet(vkeyWitnesses: $vkeyWitnesses, nativeScripts: $nativeScripts)';
  }
}

///
/// Allow arbitrary metadata via raw CBOR type. Use CborValue and ListBuilder instances to compose complex nested structures.
///

class BcMetadata extends BcAbstractCbor {
  final CborValue value;
  BcMetadata({
    required this.value,
  });

  CborValue toCborValue() => value;

  // List<int> get serialize => cbor.encode(value);

  @override
  Uint8List get serialize => toUint8List(value);

  String get toCborHex => HEX.encode(serialize);

  List<int> get hash => blake2bHash256(serialize);

  bool get isEmpty => value is CborNull;

  @override
  String toString() {
    return 'BcMetadata(value: ${toJson(value)})';
  }
}

/// outer wrapper of a Cardano blockchain transaction.
class BcTransaction extends BcAbstractCbor {
  final BcTransactionBody body;
  final BcTransactionWitnessSet? witnessSet;
  final bool? isValid;
  final BcMetadata? metadata;

  // if metadata present, rebuilds body to include metadataHash
  BcTransaction(
      {required BcTransactionBody body,
      this.witnessSet,
      this.isValid = true,
      this.metadata})
      : body = BcTransactionBody(
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

  factory BcTransaction.fromCbor({required CborList list}) {
    if (list.length < 3) throw BcCborDeserializationException();
    final body = BcTransactionBody.fromCbor(map: list[0] as CborMap);
    final witnessSet =
        BcTransactionWitnessSet.fromCbor(map: list[1] as CborMap);
    final bool? isValid =
        list[2] is CborBool ? (list[2] as CborBool).value : null;
    final metadata = (list.length >= 3) ? BcMetadata(value: list[3]) : null;
    return BcTransaction(
      body: body,
      witnessSet: witnessSet,
      isValid: isValid,
      metadata: metadata,
    );
  }

  factory BcTransaction.fromHex(String transactionHex) {
    final buff = HEX.decode(transactionHex);
    final cborList = cbor.decode(buff) as CborList;
    return BcTransaction.fromCbor(list: cborList);
  }

  CborValue toCborList() {
    return CborList([
      body.toCborMap(),
      (witnessSet == null || witnessSet!.isEmpty)
          ? CborMap({})
          : witnessSet!.toCborMap(),
      if (isValid != null) CborBool(isValid ?? true),
      (metadata == null || metadata!.isEmpty)
          ? const CborNull()
          : metadata!.toCborValue(),
    ]);
  }

  @override
  Uint8List get serialize => toUint8List(toCborList());

  @override
  String toString() {
    return 'BcTransaction(body: $body, witnessSet: $witnessSet, isValid: $isValid, metadata: $metadata)';
  }

  String get json => toJson(toCborList());
}
