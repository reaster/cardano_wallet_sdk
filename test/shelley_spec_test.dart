// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:cbor/cbor.dart' as cbor;
import 'dart:convert' as convertor;
import 'package:test/test.dart';

///
/// CBOR output can be validated here: http://cbor.me
/// CBOR encoding reference: https://www.rfc-editor.org/rfc/rfc7049.html#appendix-B
///
/// Current CBOR spec is rfc8949: https://www.rfc-editor.org/rfc/rfc8949.html
///
/// Dart cbor package only supporst old spec, rfc7049 with map keys limited to integer
/// and string types: https://pub.dev/packages/cbor
///
/// tests and results taken from: https://github.com/bloxbean/cardano-client-lib. Thank you!
///
void main() {
  test('Deserialization', () {
    final List<ShelleyTransactionInput> inputs = [
      ShelleyTransactionInput(
          transactionId:
              '73198b7ad003862b9798106b88fbccfca464b1a38afb34958275c4a7d7d8d002',
          index: 1),
    ];
    final List<ShelleyTransactionOutput> outputs = [
      ShelleyTransactionOutput(
          address:
              'addr_test1qqy3df0763vfmygxjxu94h0kprwwaexe6cx5exjd92f9qfkry2djz2a8a7ry8nv00cudvfunxmtp5sxj9zcrdaq0amtqmflh6v',
          value: ShelleyValue(coin: 40000, multiAssets: [])),
      ShelleyTransactionOutput(
          address:
              'addr_test1qzx9hu8j4ah3auytk0mwcupd69hpc52t0cw39a65ndrah86djs784u92a3m5w475w3w35tyd6v3qumkze80j8a6h5tuqq5xe8y',
          value: ShelleyValue(coin: 340000, multiAssets: [
            ShelleyMultiAsset(
                policyId:
                    '329728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96',
                assets: [
                  ShelleyAsset(name: '736174636f696e', value: 4000),
                  ShelleyAsset(name: '446174636f696e', value: 1100),
                ]),
            ShelleyMultiAsset(
                policyId:
                    '6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7',
                assets: [
                  ShelleyAsset(name: '', value: 9000),
                ]),
            ShelleyMultiAsset(
                policyId:
                    '449728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96',
                assets: [
                  ShelleyAsset(name: '666174636f696e', value: 5000),
                ]),
          ])),
    ];
    final body = ShelleyTransactionBody(
      inputs: inputs,
      outputs: outputs,
      fee: 367965,
      ttl: 26194586,
      metadataHash: null,
      validityStartInterval: 0,
      mint: outputs[1].value.multiAssets,
    );
    final ShelleyTransaction tx =
        ShelleyTransaction(body: body, witnessSet: null, metadata: null);
    final txHex = tx.toCborHex;
    print(txHex);
    const expectedHex =
        '84a5008182582073198b7ad003862b9798106b88fbccfca464b1a38afb34958275c4a7d7d8d002010182825839000916a5fed4589d910691b85addf608dceee4d9d60d4c9a4d2a925026c3229b212ba7ef8643cd8f7e38d6279336d61a40d228b036f40feed6199c40825839008c5bf0f2af6f1ef08bb3f6ec702dd16e1c514b7e1d12f7549b47db9f4d943c7af0aaec774757d4745d1a2c8dd3220e6ec2c9df23f757a2f8821a00053020a3581c329728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a247736174636f696e190fa047446174636f696e19044c581c6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7a140192328581c449728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a147666174636f696e191388021a00059d5d031a018fb29a09a3581c329728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a247736174636f696e190fa047446174636f696e19044c581c6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7a140192328581c449728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a147666174636f696e191388a0f5f6';
    //'83a5008182582073198b7ad003862b9798106b88fbccfca464b1a38afb34958275c4a7d7d8d002010182825839000916a5fed4589d910691b85addf608dceee4d9d60d4c9a4d2a925026c3229b212ba7ef8643cd8f7e38d6279336d61a40d228b036f40feed6199c40825839008c5bf0f2af6f1ef08bb3f6ec702dd16e1c514b7e1d12f7549b47db9f4d943c7af0aaec774757d4745d1a2c8dd3220e6ec2c9df23f757a2f8821a00053020a3581c329728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a247736174636f696e190fa047446174636f696e19044c581c6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7a140192328581c449728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a147666174636f696e191388021a00059d5d031a018fb29a09a3581c329728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a247736174636f696e190fa047446174636f696e19044c581c6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7a140192328581c449728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a147666174636f696e191388a0f6';
    expect(txHex, expectedHex, reason: '1st serialization good');

    final ShelleyTransaction tx2 = ShelleyTransaction.deserializeFromHex(txHex);
    final txHex2 = tx2.toCborHex;
    print(txHex2);
    expect(txHex, txHex2);
    print(tx2.toJson(prettyPrint: true));
    //print(codec.decodedToJSON()); // [1,2,3],67.89,10,{"a":"a/ur1","b":1234567899,"c":"19/04/2020"},"^[12]g"
  });

  test('Serialize Transaction with Metadata', () {
    final List<ShelleyTransactionInput> inputs = [
      ShelleyTransactionInput(
          transactionId:
              '73198b7ad003862b9798106b88fbccfca464b1a38afb34958275c4a7d7d8d002',
          index: 1),
    ];
    final List<ShelleyTransactionOutput> outputs = [
      ShelleyTransactionOutput(
          address:
              'addr_test1qqy3df0763vfmygxjxu94h0kprwwaexe6cx5exjd92f9qfkry2djz2a8a7ry8nv00cudvfunxmtp5sxj9zcrdaq0amtqmflh6v',
          value: ShelleyValue(coin: 40000, multiAssets: [])),
      ShelleyTransactionOutput(
          address:
              'addr_test1qzx9hu8j4ah3auytk0mwcupd69hpc52t0cw39a65ndrah86djs784u92a3m5w475w3w35tyd6v3qumkze80j8a6h5tuqq5xe8y',
          value: ShelleyValue(coin: 340000, multiAssets: [
            ShelleyMultiAsset(
                policyId:
                    '329728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96',
                assets: [
                  ShelleyAsset(name: '736174636f696e', value: 4000),
                ]),
            ShelleyMultiAsset(
                policyId:
                    '6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7',
                assets: [
                  ShelleyAsset(name: '', value: 9000),
                ]),
          ])),
    ];
    final body = ShelleyTransactionBody(
      inputs: inputs,
      outputs: outputs,
      fee: 367965,
      ttl: 26194586,
      metadataHash: null,
      validityStartInterval: 0,
      mint: outputs[1].value.multiAssets,
    );

    //metadata
    final metadataMap = cbor.MapBuilder.builder()
      ..writeInt(1978) //key
      ..writeString('201value') //value
      ..writeInt(197819) //key
      ..writeInt(200001) //value
      ..writeString('203') //key
      ..writeBytes(unit8BufferFromBytes([11, 11, 10])); //value
    final metadataList = cbor.ListBuilder.builder()
      ..writeString('301value')
      ..writeInt(300001)
      ..writeBytes(unit8BufferFromBytes([11, 11, 10]))
      ..addBuilderOutput((cbor.MapBuilder.builder()
            ..writeInt(401) //key
            ..writeString('401str') //value
            ..writeString('hello') //key
            ..writeString('hellovalue')) //value
          .getData());
    final metadata = CBORMetadata(cbor.MapBuilder.builder()
          ..writeInt(197819781978) //key
          ..writeString('John') //value
          ..writeInt(197819781979) //key
          ..writeString('CA') //value
          ..writeInt(1978197819710) //key
          ..writeBytes(unit8BufferFromBytes([0, 11])) //value
          ..writeInt(1978197819711) //key
          ..addBuilderOutput(metadataMap.getData()) //value
          ..writeInt(1978197819712) //key
          ..addBuilderOutput(metadataList.getData()) //value
        );
    // print("  actual: ${metadata.toCborHex}");
    // print('expected: a51b0000002e0efa535a644a6f686e1b0000002e0efa535b6243411b000001cc95c7413e42000b1b000001cc95c7413fa31907ba6832303176616c75651a000304bb1a00030d4163323033430b0b0a1b000001cc95c74140846833303176616c75651a000493e1430b0b0aa2190191663430317374726568656c6c6f6a68656c6c6f76616c7565');
    final ShelleyTransaction tx =
        ShelleyTransaction(body: body, witnessSet: null, metadata: metadata);
    final txHex = tx.toCborHex;
    print(txHex);
    const expectedHex =
        '84a6008182582073198b7ad003862b9798106b88fbccfca464b1a38afb34958275c4a7d7d8d002010182825839000916a5fed4589d910691b85addf608dceee4d9d60d4c9a4d2a925026c3229b212ba7ef8643cd8f7e38d6279336d61a40d228b036f40feed6199c40825839008c5bf0f2af6f1ef08bb3f6ec702dd16e1c514b7e1d12f7549b47db9f4d943c7af0aaec774757d4745d1a2c8dd3220e6ec2c9df23f757a2f8821a00053020a2581c329728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a147736174636f696e190fa0581c6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7a140192328021a00059d5d031a018fb29a0758203f4851269f7b360569e7fbc7ab3dadd504980d6ccda7afd9e52d83cba855a8bf09a2581c329728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a147736174636f696e190fa0581c6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7a140192328a0f5a51b0000002e0efa535a644a6f686e1b0000002e0efa535b6243411b000001cc95c7413e42000b1b000001cc95c7413fa31907ba6832303176616c75651a000304bb1a00030d4163323033430b0b0a1b000001cc95c74140846833303176616c75651a000493e1430b0b0aa2190191663430317374726568656c6c6f6a68656c6c6f76616c7565';
    // '83a6008182582073198b7ad003862b9798106b88fbccfca464b1a38afb34958275c4a7d7d8d002010182825839000916a5fed4589d910691b85addf608dceee4d9d60d4c9a4d2a925026c3229b212ba7ef8643cd8f7e38d6279336d61a40d228b036f40feed6199c40825839008c5bf0f2af6f1ef08bb3f6ec702dd16e1c514b7e1d12f7549b47db9f4d943c7af0aaec774757d4745d1a2c8dd3220e6ec2c9df23f757a2f8821a00053020a2581c329728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a147736174636f696e190fa0581c6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7a140192328021a00059d5d031a018fb29a0758203f4851269f7b360569e7fbc7ab3dadd504980d6ccda7afd9e52d83cba855a8bf09a2581c329728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a147736174636f696e190fa0581c6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7a140192328a0a51b0000002e0efa535a644a6f686e1b0000002e0efa535b6243411b000001cc95c7413e42000b1b000001cc95c7413fa31907ba6832303176616c75651a000304bb1a00030d4163323033430b0b0a1b000001cc95c74140846833303176616c75651a000493e1430b0b0aa2190191663430317374726568656c6c6f6a68656c6c6f76616c7565';
    expect(txHex, expectedHex);
  });

  test('Serialize Transaction with Mint', () {
    final List<ShelleyTransactionInput> inputs = [
      ShelleyTransactionInput(
          transactionId:
              '73198b7ad003862b9798106b88fbccfca464b1a38afb34958275c4a7d7d8d002',
          index: 1),
    ];
    final List<ShelleyTransactionOutput> outputs = [
      ShelleyTransactionOutput(
          address:
              'addr_test1qqy3df0763vfmygxjxu94h0kprwwaexe6cx5exjd92f9qfkry2djz2a8a7ry8nv00cudvfunxmtp5sxj9zcrdaq0amtqmflh6v',
          value: ShelleyValue(coin: 40000, multiAssets: [])),
      ShelleyTransactionOutput(
          address:
              'addr_test1qzx9hu8j4ah3auytk0mwcupd69hpc52t0cw39a65ndrah86djs784u92a3m5w475w3w35tyd6v3qumkze80j8a6h5tuqq5xe8y',
          value: ShelleyValue(coin: 340000, multiAssets: [
            ShelleyMultiAsset(
                policyId:
                    '329728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96',
                assets: [
                  ShelleyAsset(name: '736174636f696e', value: 4000),
                ]),
            ShelleyMultiAsset(
                policyId:
                    '6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7',
                assets: [
                  ShelleyAsset(name: '', value: 9000),
                ]),
          ])),
    ];
    final body = ShelleyTransactionBody(
      inputs: inputs,
      outputs: outputs,
      fee: 367965,
      ttl: 26194586,
      metadataHash: null,
      validityStartInterval: 0,
      mint: outputs[1].value.multiAssets,
    );
    final ShelleyTransaction tx =
        ShelleyTransaction(body: body, witnessSet: null, metadata: null);
    final txHex = tx.toCborHex;
    print(txHex);
    const expectedHex =
        '84a5008182582073198b7ad003862b9798106b88fbccfca464b1a38afb34958275c4a7d7d8d002010182825839000916a5fed4589d910691b85addf608dceee4d9d60d4c9a4d2a925026c3229b212ba7ef8643cd8f7e38d6279336d61a40d228b036f40feed6199c40825839008c5bf0f2af6f1ef08bb3f6ec702dd16e1c514b7e1d12f7549b47db9f4d943c7af0aaec774757d4745d1a2c8dd3220e6ec2c9df23f757a2f8821a00053020a2581c329728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a147736174636f696e190fa0581c6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7a140192328021a00059d5d031a018fb29a09a2581c329728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a147736174636f696e190fa0581c6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7a140192328a0f5f6';
    // '83a5008182582073198b7ad003862b9798106b88fbccfca464b1a38afb34958275c4a7d7d8d002010182825839000916a5fed4589d910691b85addf608dceee4d9d60d4c9a4d2a925026c3229b212ba7ef8643cd8f7e38d6279336d61a40d228b036f40feed6199c40825839008c5bf0f2af6f1ef08bb3f6ec702dd16e1c514b7e1d12f7549b47db9f4d943c7af0aaec774757d4745d1a2c8dd3220e6ec2c9df23f757a2f8821a00053020a2581c329728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a147736174636f696e190fa0581c6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7a140192328021a00059d5d031a018fb29a09a2581c329728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a147736174636f696e190fa0581c6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7a140192328a0f6';
    expect(txHex, expectedHex);
  });

  test('Serialize address to hex', () {
    const addr =
        'addr_test1qqy3df0763vfmygxjxu94h0kprwwaexe6cx5exjd92f9qfkry2djz2a8a7ry8nv00cudvfunxmtp5sxj9zcrdaq0amtqmflh6v';
    const addrHexExpected =
        '000916A5FED4589D910691B85ADDF608DCEEE4D9D60D4C9A4D2A925026C3229B212BA7EF8643CD8F7E38D6279336D61A40D228B036F40FEED6';
    final addrHex = hexFromShelleyAddress(addr, uppercase: true);
    print(addrHex);
    expect(addrHex, addrHexExpected);
  });

  test('exploreCborRoundTrip', () {
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

  test('exploreCborSupportedTypes', () {
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
    // mapBuilder.writeBuff(uint8BufferFromHex('1fcf')); // key
    // mapBuilder.writeEpoch(777);
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
    print(codec.decodedPrettyPrint(true));
    print(codec
        .decodedToJSON()); // [1,2,3],67.89,10,{"a":"a/ur1","b":1234567899,"c":"19/04/2020"},"^[12]g"
  });
  test('exploreJsonPrettyPrint', () {
    const toJsonFromString = convertor.JsonDecoder();
    final json = toJsonFromString.convert(
        '[[1,2,3],67.89,10,{"a":"a/ur1","b":1234567899,"c":"19/04/2020"}]');
    const jsonFormatter = convertor.JsonEncoder.withIndent('  ');
    final formattedJson = jsonFormatter.convert(json);
    print(formattedJson);
    expect(formattedJson.contains('\n'), isTrue);
  });
  // test('Serialize transaction hex to hex', () {
  //   final transactionId = '73198b7ad003862b9798106b88fbccfca464b1a38afb34958275c4a7d7d8d002';
  //   final input = ShelleyTransactionInput(index: 7, transactionId: transactionId);
  //   final listBuilder = input.toCborList();
  //   final uint8buffer = listBuilder.getData();
  //   print(uint8buffer.toString());
  // });
}
