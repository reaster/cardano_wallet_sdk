// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

@Tags(['blockfrost'])

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'blockfrost_test_auth_interceptor.dart';
import 'package:bip32_ed25519/bip32_ed25519.dart';
import 'package:test/test.dart';

///
/// mostly recycled tests from cbor
///
void main() {
  final interceptor = BlockfrostTestAuthInterceptor();
  final adapterFactory = BlockchainAdapterFactory(authInterceptor: interceptor, networkId: NetworkId.testnet);

  // final ADA = 1000000;

  test('Deserialization', () async {
    final builder = TransactionBuilder()
      ..blockchainAdapter(adapterFactory.adapter())
      ..input(transactionId: '73198b7ad003862b9798106b88fbccfca464b1a38afb34958275c4a7d7d8d002', index: 1)
      ..output(
          address:
              'addr_test1qqy3df0763vfmygxjxu94h0kprwwaexe6cx5exjd92f9qfkry2djz2a8a7ry8nv00cudvfunxmtp5sxj9zcrdaq0amtqmflh6v',
          value: ShelleyValue(coin: 40000, multiAssets: []))
      ..output(
        address:
            'addr_test1qzx9hu8j4ah3auytk0mwcupd69hpc52t0cw39a65ndrah86djs784u92a3m5w475w3w35tyd6v3qumkze80j8a6h5tuqq5xe8y',
        multiAssetBuilder: MultiAssetBuilder(coin: 340000)
            .nativeAsset2(
              policyId: '329728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96',
              hexName1: '736174636f696e',
              value1: 4000,
              hexName2: '446174636f696e',
              value2: 1100,
            )
            .nativeAsset(policyId: '6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7', value: 9000)
            .nativeAsset(
                policyId: '449728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96',
                hexName: '666174636f696e',
                value: 5000),
      )
      ..fee(367965)
      ..ttl(26194586);

    final ShelleyTransaction tx = await builder.build();
    final txHex = tx.toCborHex;
    //print(txHex);
    final expectedHex =
        '83a5008182582073198b7ad003862b9798106b88fbccfca464b1a38afb34958275c4a7d7d8d002010182825839000916a5fed4589d910691b85addf608dceee4d9d60d4c9a4d2a925026c3229b212ba7ef8643cd8f7e38d6279336d61a40d228b036f40feed6199c40825839008c5bf0f2af6f1ef08bb3f6ec702dd16e1c514b7e1d12f7549b47db9f4d943c7af0aaec774757d4745d1a2c8dd3220e6ec2c9df23f757a2f8821a00053020a3581c329728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a247736174636f696e190fa047446174636f696e19044c581c6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7a140192328581c449728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a147666174636f696e191388021a00059d5d031a018fb29a09a3581c329728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a247736174636f696e190fa047446174636f696e19044c581c6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7a140192328581c449728f73683fe04364631c27a7912538c116d802416ca1eaf2d7a96a147666174636f696e191388a0f6';
    expect(txHex, expectedHex, reason: '1st serialization good');

    final ShelleyTransaction tx2 = ShelleyTransaction.deserializeFromHex(txHex);
    final txHex2 = tx2.toCborHex;
    //print(txHex2);
    expect(txHex, txHex2);
    // print(codec.decodedPrettyPrint(false));
  });

  /// from fees.rs tests
  // test(
  //   'tx_simple_utxo',
  //   () {
  //     final input = ShelleyTransactionInput(
  //         transactionId: '3b40265111d8bb3c3c608d95b3a0bf83461ace32d79336579a1939b3aad1c0b7', index: 0);
  //     final toAddress = ShelleyAddress(HEX.decode('611c616f1acb460668a9b2f123c80372c2adad3583b9c6cd2b1deeed1c'));
  //     final output =
  //         ShelleyTransactionOutput(address: toAddress.toBech32(), value: ShelleyValue(coin: 1, multiAssets: []));
  //     final body = ShelleyTransactionBody(inputs: [input], outputs: [output], fee: 94002, ttl: 10);
  //     List<int> hash = blake2bHash256(body.toCborMap().getData());
  //     final signingKey = Bip32SigningKey.normalizeBytes(
  //         uint8ListFromBytes(HEX.decode('c660e50315d76a53d80732efda7630cae8885dfb85c46378684b3c6103e1284a')));
  //     // final signingKey = Bip32SigningKey(
  //     // uint8ListFromBytes(HEX.decode('c660e50315d76a53d80732efda7630cae8885dfb85c46378684b3c6103e1284a')));
  //     final signature = signingKey.sign(hash);
  //     final verifyKey = signingKey.publicKey;
  //     final witness = ShelleyVkeyWitness(signature: signature, vkey: verifyKey.keyBytes);
  //     final witnessSet = ShelleyTransactionWitnessSet(vkeyWitnesses: [witness], nativeScripts: []);
  //     final transaction = ShelleyTransaction(body: body, witnessSet: witnessSet);
  //     final expectedBytes = HEX.decode(
  //         '83a400818258203b40265111d8bb3c3c608d95b3a0bf83461ace32d79336579a1939b3aad1c0b700018182581d611c616f1acb460668a9b2f123c80372c2adad3583b9c6cd2b1deeed1c01021a00016f32030aa10081825820f9aa3fccb7fe539e471188ccc9ee65514c5961c070b06ca185962484a4813bee5840fae5de40c94d759ce13bf9886262159c4f26a289fd192e165995b785259e503f6887bf39dfa23a47cf163784c6eee23f61440e749bc1df3c73975f5231aeda0ff6');
  //     final txBytes = transaction.serialize;
  //     expect(txBytes, expectedBytes);
  //   },
  //   // skip: 'key fails Bip32SigningKey validateKeyBits test'
  // );
  final mnemonic =
      'rude stadium move tumble spice vocal undo butter cargo win valid session question walk indoor nothing wagon column artefact monster fold gallery receive just';
  test('signAndVerify', () {
    final hdWallet = HdWallet.fromMnemonic(mnemonic);
    ShelleyAddressKit kit = hdWallet.deriveUnusedBaseAddressKit();
    final input = ShelleyTransactionInput(
        transactionId: '3b40265111d8bb3c3c608d95b3a0bf83461ace32d79336579a1939b3aad1c0b7', index: 0);
    final output = ShelleyTransactionOutput(
        address:
            'addr_test1qrf6r5df3v4p43f5ncyjgtwmajnasvw6zath6wa7226jxcfxngwdkqgqcvjtzmz624d6efz67ysf3597k24uyzqg5ctsw3hqzt',
        value: ShelleyValue(coin: 1, multiAssets: []));
    final body = ShelleyTransactionBody(inputs: [input], outputs: [output], fee: 94002, ttl: 10);
    final bodyData = body.toCborMap().getData();
    print(b2s(bodyData));
    List<int> hash = blake2bHash256(bodyData);
    final signature = kit.signingKey!.sign(hash);
    final verifyKey = kit.verifyKey!.publicKey;
    final witness = ShelleyVkeyWitness(signature: signature, vkey: verifyKey.toUint8List());
    final witnessSet = ShelleyTransactionWitnessSet(vkeyWitnesses: [witness], nativeScripts: []);
    final transaction = ShelleyTransaction(body: body, witnessSet: witnessSet);
    final txHex = transaction.toCborHex;
    print("transaction.toCborHex: $txHex");
    //deserialize, manually verify data and signature
    final transaction2 = ShelleyTransaction.deserializeFromHex(txHex);
    final signature2 = transaction2.witnessSet!.vkeyWitnesses[0].signature;
    expect(signature2, signature);
    final verifyKey2 = Bip32VerifyKey(uint8ListFromBytes(transaction2.witnessSet!.vkeyWitnesses[0].vkey));
    expect(verifyKey2, verifyKey);
    final bodyData2 = transaction2.body.toCborMap().getData();
    expect(bodyData2, bodyData);
    final hash2 = blake2bHash256(bodyData2);
    expect(hash2, hash);
    final sig = kit.signingKey!.sign(hash2).signature;
    final verified = verifyKey2.verify(signature: sig, message: uint8ListFromBytes(hash2));
    expect(verified, isTrue);
    // now ask the transaction to verify itself
    expect(transaction2.verify, isTrue);
    // final Bip32KeyPair stakeAddress0Pair = hdWallet.deriveAddressKeys(role: stakingRole);
    // final stake_test = hdWallet.toRewardAddress(spend: stakeAddress0Pair.publicKey!);
    // expect(stake_test.toBech32(), 'stake_test1uzgkwv76l9sgct5xq4gldxe6g93x39yvjh4a7wu8hk2ufeqx3aar6');
    // final Bip32KeyPair spendAddress0Pair = hdWallet.deriveAddressKeys();
    // final addr_test = hdWallet.toBaseAddress(spend: spendAddress0Pair.publicKey!, stake: stakeAddress0Pair.publicKey!);
    // expect(addr_test.toBech32(), addr0Testnet);
  });

  test('manually build and sign', () async {
    final mnemonic =
        "alpha desert more credit sad balance receive sand someone correct used castle present bar shop borrow inmate estate year flip theory recycle measure silk"
            .split(' ');
    final expectedTxHex =
        '83a40081825820d65a6fdb484f4984cb982d4a4f3cba04e8e64feceec1891c63ea7c97ffe9458e010182825839001d3c7cb138111826ba11e67f1c4ad2660aab4b593a3646f6a1ed9208269a1cdb0100c324b16c5a555baca45af12098d0beb2abc20808a6171a001e848082583900cb50b9f579320a1bd4444f29c2482d06cd18959116bcb796eafe16aaaaad89c262cf305fdf4fc3edde834a9b0444d1e3469f401b975ec2ac1a3b589fbe021a000290a1031a02745f28a0f6';
    final expectedSignedTx =
        '83a40081825820d65a6fdb484f4984cb982d4a4f3cba04e8e64feceec1891c63ea7c97ffe9458e010182825839001d3c7cb138111826ba11e67f1c4ad2660aab4b593a3646f6a1ed9208269a1cdb0100c324b16c5a555baca45af12098d0beb2abc20808a6171a001e848082583900cb50b9f579320a1bd4444f29c2482d06cd18959116bcb796eafe16aaaaad89c262cf305fdf4fc3edde834a9b0444d1e3469f401b975ec2ac1a3b589fbe021a000290a1031a02745f28a10081825820f94431a84c877cac81092cca3448219808111398021a2c3dbb30ba5be289ec5b584043b43c33619852eb4ca45573eac05c62a32557e5ff78d2a7b0af3b47bae2b77ca82cb02bd03cb6cd2dc416de24ed9560b2afb5c78e46a4df02a4b67ca2aa280cf6';
    final privateKey =
        "xprv1jz89agqn8utrqypwsmmwhalwv8uzadvxj7s0jwrx94xzvv8t64fwghtnct8um3sxq9xspvprw8v4u94mu6jxh7esalk77z537kyvcr0hz7jjgg2fx6mfj9se3tt4f39ldqy644e4mv3xy05l5g8mdvl94srxh7hd";

    final walletBuilder = WalletBuilder()
      ..networkId = NetworkId.testnet
      ..testnetAdapterKey = interceptor.apiKey
      ..mnemonic = mnemonic;
    final createResult = await walletBuilder.buildAndSync();
    if (createResult.isOk()) {
      var walley = createResult.unwrap();
      const decoder = Bech32Coder(hrp: 'xprv');
      expect(decoder.encode(walley.addressKeyPair.signingKey!.toList()), privateKey);
      final builder = TransactionBuilder()
        ..input(transactionId: 'd65a6fdb484f4984cb982d4a4f3cba04e8e64feceec1891c63ea7c97ffe9458e', index: 1)
        ..output(
            address:
                'addr_test1qqwncl938qg3sf46z8n878z26fnq426ttyarv3hk58keyzpxngwdkqgqcvjtzmz624d6efz67ysf3597k24uyzqg5ctsq32vnr',
            value: ShelleyValue(coin: 2000000, multiAssets: []))
        ..output(
            address:
                'addr_test1qr94pw040yeq5x75g38jnsjg95rv6xy4jyttedukatlpd2424kyuyck0xp0a7n7rah0gxj5mq3zdrc6xnaqph967c2kqja24jq',
            value: ShelleyValue(coin: 995663806, multiAssets: []))
        ..fee(168097)
        ..ttl(41180968)
        ..blockchainAdapter(walley.blockchainAdapter)
        ..keyPair(walley.addressKeyPair);
      //expect(builder.isBalanced, isTrue);
      ShelleyTransaction tx = builder.build();
      // print("expectCborHex: $expectedTxHex");
      // print("tx.toCborHex:  ${tx.toCborHex}");
      expect(tx.toCborHex, expectedTxHex);
      ShelleyTransaction signedTx = builder.sign();
      print("fee: ${builder.calculateMinFee(tx: tx)}");
      // print("expectedSignedTx  : $expectedSignedTx");
      // print("signedTx.toCborHex:  ${signedTx.toCborHex}");
      expect(signedTx.toCborHex, expectedSignedTx);
    } else {
      print("error creating wallet: ${createResult.unwrapErr()}");
    }
  });
}

// fn tx_simple_utxo() { // # Vector #1: simple transaction
//         let mut inputs = TransactionInputs::new();
//         inputs.add(&TransactionInput::new(
//             &TransactionHash::from_bytes(hex::decode("3b40265111d8bb3c3c608d95b3a0bf83461ace32d79336579a1939b3aad1c0b7").unwrap()).unwrap(),
//             0
//         ));
//         let mut outputs = TransactionOutputs::new();

//         outputs.add(&TransactionOutput::new(
//             &Address::from_bytes(
//                 hex::decode("611c616f1acb460668a9b2f123c80372c2adad3583b9c6cd2b1deeed1c").unwrap(),
//             )
//             .unwrap(),
//             &Value::new(&to_bignum(1)),
//         ));
//         let body = TransactionBody::new(&inputs, &outputs, &to_bignum(94002), Some(10));

//         let mut w = TransactionWitnessSet::new();
//         let mut vkw = Vkeywitnesses::new();
//         vkw.add(&make_vkey_witness(
//             &hash_transaction(&body),
//             &PrivateKey::from_normal_bytes(
//                 &hex::decode("c660e50315d76a53d80732efda7630cae8885dfb85c46378684b3c6103e1284a").unwrap()
//             ).unwrap()
//         ));
//         w.set_vkeys(&vkw);

//         let signed_tx = Transaction::new(
//             &body,
//             &w,
//             None,
//         );

//         let linear_fee = LinearFee::new(&to_bignum(500), &to_bignum(2));
//         assert_eq!(
//             hex::encode(signed_tx.to_bytes()),
//             "83a400818258203b40265111d8bb3c3c608d95b3a0bf83461ace32d79336579a1939b3aad1c0b700018182581d611c616f1acb460668a9b2f123c80372c2adad3583b9c6cd2b1deeed1c01021a00016f32030aa10081825820f9aa3fccb7fe539e471188ccc9ee65514c5961c070b06ca185962484a4813bee5840fae5de40c94d759ce13bf9886262159c4f26a289fd192e165995b785259e503f6887bf39dfa23a47cf163784c6eee23f61440e749bc1df3c73975f5231aeda0ff6"
//         );
//         assert_eq!(
//             min_fee(&signed_tx, &linear_fee).unwrap().to_str(),
//             "94002" // todo: compare to Haskell fee to make sure the diff is not too big
//         );
//     }

// fn build_tx_exact_change() {
//         // transactions where we have exactly enough ADA to add change should pass
//         let linear_fee = LinearFee::new(&to_bignum(0), &to_bignum(0));
//         let mut tx_builder = TransactionBuilder::new(
//             &linear_fee,
//             &to_bignum(1),
//             &to_bignum(0),
//             &to_bignum(0),
//             MAX_VALUE_SIZE,
//             MAX_TX_SIZE
//         );
//         let spend = root_key_15()
//             .derive(harden(1852))
//             .derive(harden(1815))
//             .derive(harden(0))
//             .derive(0)
//             .derive(0)
//             .to_public();
//         let change_key = root_key_15()
//             .derive(harden(1852))
//             .derive(harden(1815))
//             .derive(harden(0))
//             .derive(1)
//             .derive(0)
//             .to_public();
//         let stake = root_key_15()
//             .derive(harden(1852))
//             .derive(harden(1815))
//             .derive(harden(0))
//             .derive(2)
//             .derive(0)
//             .to_public();
//         tx_builder.add_key_input(
//             &&spend.to_raw_key().hash(),
//             &TransactionInput::new(&genesis_id(), 0),
//             &Value::new(&to_bignum(6))
//         );
//         let spend_cred = StakeCredential::from_keyhash(&spend.to_raw_key().hash());
//         let stake_cred = StakeCredential::from_keyhash(&stake.to_raw_key().hash());
//         let addr_net_0 = BaseAddress::new(
//             NetworkInfo::testnet().network_id(),
//             &spend_cred,
//             &stake_cred,
//         )
//         .to_address();
//         tx_builder
//             .add_output(&TransactionOutput::new(
//                 &addr_net_0,
//                 &Value::new(&to_bignum(5)),
//             ))
//             .unwrap();
//         tx_builder.set_ttl(0);

//         let change_cred = StakeCredential::from_keyhash(&change_key.to_raw_key().hash());
//         let change_addr = BaseAddress::new(NetworkInfo::testnet().network_id(), &change_cred, &stake_cred).to_address();
//         let added_change = tx_builder.add_change_if_needed(
//             &change_addr
//         ).unwrap();
//         assert_eq!(added_change, true);
//         let final_tx = tx_builder.build().unwrap();
//         assert_eq!(final_tx.outputs().len(), 2);
//         assert_eq!(final_tx.outputs().get(1).amount().coin().to_str(), "1");
//     }
