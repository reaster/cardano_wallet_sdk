import 'package:cardano_wallet_sdk/src/transaction/spec/shelley_spec.dart';
import 'package:hex/hex.dart';
import 'package:quiver/iterables.dart';
import 'package:test/test.dart';
import 'dart:convert';
import 'package:cbor/cbor.dart' as cbor;

///
/// validate here: http://cbor.me
///
void main() {
  test('encode Transaction', () {
    final List<ShelleyTransactionInput> inputs = [];
    final List<ShelleyTransactionOutput> outputs = [];
    final int fee = 2 * 1000000;
    final int? ttl = 666666; //Optional
    final List<int>? metadataHash = [];
    final int? validityStartInterval = 45678;
    final List<ShelleyMultiAsset>? mint = [];
    final body = ShelleyTransactionBody(
      inputs: inputs,
      outputs: outputs,
      fee: fee,
      ttl: ttl,
      metadataHash: metadataHash,
      validityStartInterval: validityStartInterval,
      mint: mint,
    );

    final ShelleyTransactionWitnessSet? witnessSet = null;
    final ShelleyMetadata? metadata = null;
    final ShelleyTransaction tx = ShelleyTransaction(body: body, witnessSet: witnessSet, metadata: metadata);
    print(tx.toCborHex);
  });

  test('exploreCborBasics', () {
    final codec = cbor.Cbor();
    final encoder = codec.encoder;
    encoder.writeFloat(67.89);
    encoder.writeInt(10);
    final buff = codec.output.getData(); //Uint8Buffer
    print(buff.toString());
    codec.decodeFromInput();
    print(codec.decodedPrettyPrint());
    final codec2 = cbor.Cbor();
    codec2.decodeFromBuffer(buff);
    final list = codec2.getDecodedData()!;
    expect(list.length, 2);
    expect(list[0] as double, 67.89);
    expect(list[1] as int, 10);
  });

  test('testCbor', () {
    // Get our cbor instance, always do this,it correctly
    // initialises the decoder.
    final codec = cbor.Cbor();

    // Get our encoder
    final encoder = codec.encoder;

    // Encode some values
    encoder.writeArray(<int>[1, 2, 3]);
    encoder.writeFloat(67.89);
    encoder.writeInt(10);

    // Get our map builder
    final mapBuilder = cbor.MapBuilder.builder();

    // Add some map entries to the list.
    // Entries are added as a key followed by a value, this ordering is enforced.
    // Map keys can be integers or strings only, this is also enforced.
    mapBuilder.writeString('a'); // key
    mapBuilder.writeURI('a/ur1');
    mapBuilder.writeString('b'); // key
    mapBuilder.writeEpoch(1234567899);
    mapBuilder.writeString('c'); // key
    mapBuilder.writeDateTime('19/04/2020');
    final mapBuilderOutput = mapBuilder.getData();
    encoder.addBuilderOutput(mapBuilderOutput);
    encoder.writeRegEx('^[12]g');
    codec.decodeFromInput();
    print(codec.decodedPrettyPrint(false));
    print(codec.decodedToJSON()); // [1,2,3],67.89,10,{"a":"a/ur1","b":1234567899,"c":"19/04/2020"},"^[12]g"
  });
}
