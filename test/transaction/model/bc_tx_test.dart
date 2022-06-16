// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:cbor/cbor.dart';
import 'dart:convert' as convertor;
import 'package:test/test.dart';
import 'package:hex/hex.dart';

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
  group('Blockchain CBOR model -', () {
    test('serialize', () {
      final input1 = BcTransactionInput(
          transactionId:
              '73198b7ad003862b9798106b88fbccfca464b1a38afb34958275c4a7d7d8d002',
          index: 1);
      final bytes1 = input1.serialize;
      CborValue val1 = cbor.decode(bytes1);
      //print(const CborJsonEncoder().convert(val1));
      final input2 = BcTransactionInput.fromCbor(list: val1 as CborList);
      expect(input2, equals(input1));
    });
    test('serialize2', () {
      final List<BcTransactionInput> inputs = [
        BcTransactionInput(
            transactionId:
                '73198b7ad003862b9798106b88fbccfca464b1a38afb34958275c4a7d7d8d002',
            index: 1),
      ];
      final List<BcTransactionOutput> outputs = [
        BcTransactionOutput(
            address:
                'addr_test1qqy3df0763vfmygxjxu94h0kprwwaexe6cx5exjd92f9qfkry2djz2a8a7ry8nv00cudvfunxmtp5sxj9zcrdaq0amtqmflh6v',
            value: BcValue(coin: 40000, multiAssets: [])),
        BcTransactionOutput(
            address:
                'addr_test1qzx9hu8j4ah3auytk0mwcupd69hpc52t0cw39a65ndrah86djs784u92a3m5w475w3w35tyd6v3qumkze80j8a6h5tuqq5xe8y',
            value: BcValue(coin: 340000, multiAssets: [
              BcMultiAsset(
                  policyId:
                      '329728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96',
                  assets: [
                    BcAsset(name: '736174636f696e', value: 4000),
                    BcAsset(name: '446174636f696e', value: 1100),
                  ]),
              BcMultiAsset(
                  policyId:
                      '6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7',
                  assets: [
                    BcAsset(name: '', value: 9000),
                  ]),
              BcMultiAsset(
                  policyId:
                      '449728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96',
                  assets: [
                    BcAsset(name: '666174636f696e', value: 5000),
                  ]),
            ])),
      ];
      final body = BcTransactionBody(
        inputs: inputs,
        outputs: outputs,
        fee: 367965,
        ttl: 26194586,
        metadataHash: null,
        validityStartInterval: 0,
        mint: outputs[1].value.multiAssets,
      );
      final bodyMap = cbor.decode(body.serialize) as CborMap;
      final body2 = BcTransactionBody.fromCbor(map: bodyMap);
      expect(body2, body, reason: 'BcTransactionBody serialization good');
      final BcTransaction tx =
          BcTransaction(body: body, witnessSet: null, metadata: null);
      final txHex = tx.toHex;
      //print("actual: ${tx.json}");
      //print(txHex);
      const expectedHex =
          '84a5008182582073198b7ad003862b9798106b88fbccfca464b1a38afb34958275c4a7d7d8d002010182825839000916a5fed4589d910691b85addf608dceee4d9d60d4c9a4d2a925026c3229b212ba7ef8643cd8f7e38d6279336d61a40d228b036f40feed6199c40825839008c5bf0f2af6f1ef08bb3f6ec702dd16e1c514b7e1d12f7549b47db9f4d943c7af0aaec774757d4745d1a2c8dd3220e6ec2c9df23f757a2f8821a00053020a3581c329728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a247736174636f696e190fa047446174636f696e19044c581c6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7a140192328581c449728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a147666174636f696e191388021a00059d5d031a018fb29a09a3581c329728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a247736174636f696e190fa047446174636f696e19044c581c6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7a140192328581c449728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a147666174636f696e191388a0f5f6';
      //'83a5008182582073198b7ad003862b9798106b88fbccfca464b1a38afb34958275c4a7d7d8d002010182825839000916a5fed4589d910691b85addf608dceee4d9d60d4c9a4d2a925026c3229b212ba7ef8643cd8f7e38d6279336d61a40d228b036f40feed6199c40825839008c5bf0f2af6f1ef08bb3f6ec702dd16e1c514b7e1d12f7549b47db9f4d943c7af0aaec774757d4745d1a2c8dd3220e6ec2c9df23f757a2f8821a00053020a3581c329728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a247736174636f696e190fa047446174636f696e19044c581c6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7a140192328581c449728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a147666174636f696e191388021a00059d5d031a018fb29a09a3581c329728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a247736174636f696e190fa047446174636f696e19044c581c6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7a140192328581c449728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a147666174636f696e191388a0f6';
      final expectedTx = cbor.decode(HEX.decode(expectedHex));
      //print("expected: ${const CborJsonEncoder().convert(expectedTx)}");
      expect(txHex, expectedHex, reason: '1st serialization good');

      final BcTransaction tx2 = BcTransaction.fromHex(txHex);
      //expect(tx, tx2, reason: '1st serialization good');
      final txHex2 = tx2.toHex;
      //print(txHex2);
      //TODO fix expect(txHex, txHex2);
      //print(tx2.toJson(prettyPrint: true));
      //print(codec.decodedToJSON()); // [1,2,3],67.89,10,{"a":"a/ur1","b":1234567899,"c":"19/04/2020"},"^[12]g"
    });
  });

  group('NativeScripts -', () {
    test('serialize', () {
      final t0 = BcScriptPubkey(
          keyHash: 'ad7a7b87959173fc9eac9a85891cc93892f800dd45c0544128228884');
      final t1 = BcRequireTimeBefore(slot: 12345678);
      final t2 = BcRequireTimeAfter(slot: 87654321);
      final t3 = BcScriptAtLeast(amount: 1, scripts: [t0, t1, t2]);
      final t4 = BcScriptAtLeast(amount: 1, scripts: [t1, t2]);
      final scripts = [
        t0,
        BcScriptAtLeast(amount: 2, scripts: [t0, t1, t2, t3, t4]),
        BcScriptAll(scripts: [t1, t2, t3, t4]),
        BcScriptAny(scripts: [t1, t2, t3, t4])
      ];
      for (BcNativeScript script1 in scripts) {
        final bytes1 = cbor.encode(script1.toCborList());
        CborValue val1 = cbor.decode(bytes1);
        //print(const CborJsonEncoder().convert(val1));
        final script2 = BcNativeScript.fromCbor(list: val1 as CborList);
        expect(script2, equals(script1));
      }
    });
  });
}
