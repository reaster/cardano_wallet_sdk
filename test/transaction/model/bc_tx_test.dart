// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:bip32_ed25519/bip32_ed25519.dart';
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
/// tests and results taken from: https://github.com/bloxbean/cardano-client-lib. Thank you!
///
void main() {
  group('Blockchain CBOR model -', () {
    test('serialize deserialize BcTransactionInput', () {
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

    test('serializeTx', () {
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
      //print("actual: ${tx.json}");
      //print(txHex);
      const expectedHex =
          '84a5008182582073198b7ad003862b9798106b88fbccfca464b1a38afb34958275c4a7d7d8d002010182825839000916a5fed4589d910691b85addf608dceee4d9d60d4c9a4d2a925026c3229b212ba7ef8643cd8f7e38d6279336d61a40d228b036f40feed6199c40825839008c5bf0f2af6f1ef08bb3f6ec702dd16e1c514b7e1d12f7549b47db9f4d943c7af0aaec774757d4745d1a2c8dd3220e6ec2c9df23f757a2f8821a00053020a3581c329728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a247736174636f696e190fa047446174636f696e19044c581c6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7a140192328581c449728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a147666174636f696e191388021a00059d5d031a018fb29a09a3581c329728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a247736174636f696e190fa047446174636f696e19044c581c6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7a140192328581c449728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a147666174636f696e191388a0f5f6';
      final expectedTx = cbor.decode(HEX.decode(expectedHex));
      //print("expected: ${const CborJsonEncoder().convert(expectedTx)}");
      expect(tx.toHex, expectedHex, reason: '1st serialization good');

      final BcTransaction tx2 = BcTransaction.fromHex(tx.toHex);
      expect(tx, tx2, reason: '1st serialization good');
      //print(tx2.toHex);
      expect(tx.toHex, tx2.toHex);
      //print(tx2.toJson(prettyPrint: true));
      //print(codec.decodedToJSON()); // [1,2,3],67.89,10,{"a":"a/ur1","b":1234567899,"c":"19/04/2020"},"^[12]g"
    });

    test('signPaymentTransactionMultiAccount', () {
      final List<BcTransactionInput> inputs = [
        BcTransactionInput(
            transactionId:
                '73198b7ad003862b9798106b88fbccfca464b1a38afb34958275c4a7d7d8d002',
            index: 1), //long balance1 = 989264070;
        BcTransactionInput(
            transactionId:
                '8e03a93578dc0acd523a4dd861793068a06a68b8a6c7358d0c965d2864067b68',
            index: 0), //long balance2 = 1000000000;
      ];
      final fee = 367965;
      final ttl = 26194586;
      final balance1 = 989264070;
      final amount1 = 5000000;
      final changeAmount1 = balance1 - amount1 - fee;
      final balance2 = 1000000000;
      final amount2 = 8000000;
      final changeAmount2 = balance2 - amount2 - fee;
      final List<BcTransactionOutput> outputs = [
        //output 1
        BcTransactionOutput(
            address:
                'addr_test1qqy3df0763vfmygxjxu94h0kprwwaexe6cx5exjd92f9qfkry2djz2a8a7ry8nv00cudvfunxmtp5sxj9zcrdaq0amtqmflh6v',
            value: BcValue(coin: amount1, multiAssets: [])),
        BcTransactionOutput(
            address:
                'addr_test1qzx9hu8j4ah3auytk0mwcupd69hpc52t0cw39a65ndrah86djs784u92a3m5w475w3w35tyd6v3qumkze80j8a6h5tuqq5xe8y',
            value: BcValue(coin: changeAmount1, multiAssets: [])),
        //output 2
        BcTransactionOutput(
            address:
                'addr_test1qrynkm9vzsl7vrufzn6y4zvl2v55x0xwc02nwg00x59qlkxtsu6q93e6mrernam0k4vmkn3melezkvgtq84d608zqhnsn48axp',
            value: BcValue(coin: amount2, multiAssets: [])),
        BcTransactionOutput(
            address:
                'addr_test1qqwpl7h3g84mhr36wpetk904p7fchx2vst0z696lxk8ujsjyruqwmlsm344gfux3nsj6njyzj3ppvrqtt36cp9xyydzqzumz82',
            value: BcValue(coin: changeAmount2, multiAssets: [])),
      ];

      final body = BcTransactionBody(
        inputs: inputs,
        outputs: outputs,
        fee: fee * 2,
        ttl: ttl,
        metadataHash: null,
        validityStartInterval: 0,
      );
      final tx = BcTransaction(body: body, witnessSet: null, metadata: null);
      final txHex = tx.toHex;
      //print(txHex);
      const expectedHex =
          '84a4008282582073198b7ad003862b9798106b88fbccfca464b1a38afb34958275c4a7d7d8d002018258208e03a93578dc0acd523a4dd861793068a06a68b8a6c7358d0c965d2864067b68000184825839000916a5fed4589d910691b85addf608dceee4d9d60d4c9a4d2a925026c3229b212ba7ef8643cd8f7e38d6279336d61a40d228b036f40feed61a004c4b40825839008c5bf0f2af6f1ef08bb3f6ec702dd16e1c514b7e1d12f7549b47db9f4d943c7af0aaec774757d4745d1a2c8dd3220e6ec2c9df23f757a2f81a3aa5102982583900c93b6cac143fe60f8914f44a899f5329433ccec3d53721ef350a0fd8cb873402c73ad8f239f76fb559bb4e3bcff22b310b01eadd3ce205e71a007a1200825839001c1ffaf141ebbb8e3a7072bb15f50f938b994c82de2d175f358fc942441f00edfe1b8d6a84f0d19c25a9c8829442160c0b5c758094c423441a3b1b1aa3021a000b3aba031a018fb29aa0f5f6';
      expect(txHex, expectedHex);
      final acct1 = HdMaster.mnemonic(
        'damp wish scrub sentence vibrant gauge tumble raven game extend winner acid side amused vote edge affair buzz hospital slogan patient drum day vital'
            .split(' '),
        network: Networks.testnet,
      ).account();
      print(
          "acct_xsk: ${Bech32Coder(hrp: 'xprv').encode(acct1.basePrivateKey())}");
      final acct2 = HdMaster.mnemonic(
        'mixture peasant wood unhappy usage hero great elder emotion picnic talent fantasy program clean patch wheel drip disorder bullet cushion bulk infant balance address'
            .split(' '),
        network: Networks.testnet,
      ).account();
      //two witnesses, two signatures
      final txSigned =
          tx.sign([acct1.basePrivateKey(), acct2.basePrivateKey()]);
      final witness1 = txSigned.witnessSet!.vkeyWitnesses[0];
      expect(witness1.vkey, acct1.basePrivateKey().verifyKey.rawKey);
      final expectedSig1 =
          'bdaff70c01b89da00748579d50267a35d0d349fda3779f28e5aa99c947d41e3c9ec5b8b8dd8349278d83f099a1bcfde250c070fc9640063fba40e783e739c704';
      expect(HEX.encode(witness1.signature), expectedSig1);

      final witness2 = txSigned.witnessSet!.vkeyWitnesses[1];
      expect(witness2.vkey, acct2.basePrivateKey().verifyKey.rawKey);
      final expectedSig2 =
          'd384420623677ba4e92d3b0ffe7ed7bb3037f513f75fc68d8b6462acff11314bb755a603a84f3a1a2b3b61f2661fc747b9462ffd5bc8b4641c4ec10b1e42c60a';
      expect(HEX.encode(witness2.signature), expectedSig2);
      expect(txSigned.verify, isTrue);
    });
  });
}
