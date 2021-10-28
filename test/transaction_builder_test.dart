import 'package:bip32_ed25519/bip32_ed25519.dart';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:cardano_wallet_sdk/src/blockchain/blockchain_adapter_factory.dart';
import 'package:cardano_wallet_sdk/src/transaction/spec/shelley_spec.dart';
import 'package:cardano_wallet_sdk/src/transaction/transaction_builder.dart';
import 'package:cardano_wallet_sdk/src/util/blake2bhash.dart';
import 'package:cardano_wallet_sdk/src/util/codec.dart';
import 'package:cardano_wallet_sdk/src/util/misc.dart';
import 'package:test/test.dart';
import 'my_api_key_auth.dart';

///
/// mostly recycled tests from cbor
///
void main() {
  final adapterFactory =
      BlockchainAdapterFactory(authInterceptor: MyApiKeyAuthInterceptor(), networkId: NetworkId.testnet);
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
    print(txHex);
    //deserialize, verify data and signature
    final transaction2 = ShelleyTransaction.deserializeFromHex(txHex);
    final signature2 = transaction2.witnessSet!.vkeyWitnesses[0].signature;
    expect(signature2, signature);
    final verifyKey2 = Bip32VerifyKey(uint8ListFromBytes(transaction2.witnessSet!.vkeyWitnesses[0].vkey));
    expect(verifyKey2, verifyKey);
    final bodyData2 = transaction2.body.toCborMap().getData();
    expect(bodyData2, bodyData);
    final hash2 = blake2bHash256(bodyData2);
    expect(hash2, hash);
    final sig = Signature(uint8ListFromBytes(signature2));
    final verified = verifyKey2.verify(signature: sig, message: uint8ListFromBytes(hash2));
    expect(verified, isTrue);
    // final Bip32KeyPair stakeAddress0Pair = hdWallet.deriveAddressKeys(role: stakingRole);
    // final stake_test = hdWallet.toRewardAddress(spend: stakeAddress0Pair.publicKey!);
    // expect(stake_test.toBech32(), 'stake_test1uzgkwv76l9sgct5xq4gldxe6g93x39yvjh4a7wu8hk2ufeqx3aar6');
    // final Bip32KeyPair spendAddress0Pair = hdWallet.deriveAddressKeys();
    // final addr_test = hdWallet.toBaseAddress(spend: spendAddress0Pair.publicKey!, stake: stakeAddress0Pair.publicKey!);
    // expect(addr_test.toBech32(), addr0Testnet);
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
