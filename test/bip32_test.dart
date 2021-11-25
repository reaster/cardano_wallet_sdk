// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:bip32_ed25519/bip32_ed25519.dart';
import 'package:test/test.dart';
import 'package:bip39/bip39.dart' as bip39;

//
// BIP-44 path: m / purpose' / coin_type' / account_ix' / change_chain / address_ix
//
// Cardano adoption: m / 1852' / 1851' / 0' / change_chain / address_ix
//
//
// +--------------------------------------------------------------------------------+
// |                BIP-39 Encoded Seed with CRC a.k.a Mnemonic Words               |
// |                                                                                |
// |    squirrel material silly twice direct ... razor become junk kingdom flee     |
// |                                                                                |
// +--------------------------------------------------------------------------------+
//        |
//        |
//        v
// +--------------------------+    +-----------------------+
// |    Wallet Private Key    |--->|   Wallet Public Key   |
// +--------------------------+    +-----------------------+
//        |
//        | purpose (e.g. 1852')
//        |
//        v
// +--------------------------+
// |   Purpose Private Key    |
// +--------------------------+
//        |
//        | coin type (e.g. 1815' for ADA)
//        v
// +--------------------------+
// |  Coin Type Private Key   |
// +--------------------------+
//        |
//        | account ix (e.g. 0')
//        v
// +--------------------------+    +-----------------------+
// |   Account Private Key    |--->|   Account Public Key  |
// +--------------------------+    +-----------------------+
//        |                                          |
//        | chain  (e.g. 0=external/payments,        |
//        |         1=internal/change, 2=staking)    |
//        v                                          v
// +--------------------------+    +-----------------------+
// |   Change Private Key     |--->|   Change Public Key   |
// +--------------------------+    +-----------------------+
//        |                                          |
//        | address ix (e.g. 0)                      |
//        v                                          v
// +--------------------------+    +-----------------------+
// |   Address Private Key    |--->|   Address Public Key  |
// +--------------------------+    +-----------------------+
//
//              BIP-44 Wallets Key Hierarchy
//
//

void main() {
  // final entropyPlusCs24Words = 256;
  const testMnemonic1 =
      "elder lottery unlock common assume beauty grant curtain various horn spot youth exclude rude boost fence used two spawn toddler soup awake across use";
  const testEntropy1 =
      "475083b81730de275969b1f18db34b7fb4ef79c66aa8efdd7742f1bcfe204097";
  const testHexSeed1 =
      '3e545a8c7aed6e4e0a152a4884ab53b6f1f0d7916f22793c7618949d891a1a80772b7a2e27dbf9b1a8027c4c481a1f423b7da3f4bf6ee70d4a3a2e940c87d74f';
  // final masterPrv =
  //     "ed25519e_sk1drm35zt6mrym4mg8nqcnyvaju6j40gzf8efn6j3elxztpv2fx4ync2a7ed862ew334g3vns0730578z690399j5mfyu3gzhl8a6n38cth3s88";
  // final masterPub =
  //     "ed25519_pk1zddat8qcwxm4gqlawnrvdtec3l20r59pep60e0dzgf5p6ykrnsds6au707";
  // final accountPrv =
  //     "xprv14zqjv6jdyea8mf4v4nwp2wjfn8f42trhtqz0dknd6tjmrw6fx4yhfgnp5cta5ug055c0gl56jm2fx3hexwznc4jjjqmv0d60psdcppvxgzskmsa2f6ydhg53pcvzrnuujeacqamrmvkcq7mgq45e6mr3qvqlp9r5";
  // final accountPub =
  //     "xpub13hk3yrupjdquk6htz0s2yl4r40n9h0hmlleddtsvnf554z4k9nngvs9pdhp65n5gmw3fzrscy88ee9nmspmk8kedspaksptfn4k8zqcq245nd";
  const chainPrv =
      "xprv1cpfh0megyfu4fxyccks4lcszhj2pdj9zdl5plls7r8q50sjfx4yav928dydh94eegljc3hk5jemg37pdh93gh6dmqrz66944m7hkq2k97svm646l363rlgd9nxcs87z7vvjm7tf5kqv07met3nelj90pnsfjclag";
  const chainPub =
      "xpub19vdjcq8rtj0ect0vym8rhfvh2pxjljrgv2mqxkc9xs90lzn7h39utaqeh4t4lr4z87s6txd3q0u9uce9huknfvqclahjhr8nly27r8q5ww6gs";
  // final stakingPrv =
  //     "xprv19r8dgpg4dlq3d2emg5yny893q3d06f4938qqxxjl5h32ms6fx4ym83dl8k2ptt0698gt2sujqespka4vzehd0h3hlfnnqzmd4cn7tzdm5vs7dqzprqyguav46uup83gju7vyjrltkrf5stvs0su75zawzy7amvc6";
  // final stakingPub =
  //     "xpub1eqjlllfhv8fr3tnugfjtttz5nv58pyj9c5kz9sq668y8u4xrhwd0gmc4amza5e85l8yhup63u8jy98gunq47cv5m3g2f7pcea6n8unqdg0s94";
  // final path = "m/1852'/1815'/0'/0";

  final chainPairs = [
    {
      "xprv":
          "xprv1prg8t88k7zqs2uufgh4ze4qx0utnj3gh8d07x6stt45v3jzfx4y5tpdl8ea3r458cntycu7aa4vfzkgqmjdmz0cx922n92pkdhafwxkumxh9cnhnrmldaahwmtvknzs4lqgazqzqx6mxysfc2zqag9jreujgjxt0",
      "xpub":
          "xpub1wygtt6rzgrj3ks864trc5zujv907j6hdxakd6pe9tuy2u7hfee3dekdwt380x8h7mmmwakkedx9pt7q36yqyqd4kvfqns5yp6sty8ncrz8due"
    },
    {
      "xprv":
          "xprv13z96f5ef2vysz4wte0fxh0nvd4j7w337kgdraj2ldvd0f36fx4ykku3uju42rh3ztw0gerehg6srfu70vlz3u3wynquk3vtxwex0ymyjz6uxtuumzf63tku664v3ul7tjzrqfww4q44ck7kf3num6vzccc093rc0",
      "xpub":
          "xpub18ylxj3hgg0wn4wdvx9zjfhk8lq3wwamvhchqsjgcuugq8596l77fy94cvheekyn4zhde442ereluhyyxqjua2ptt3davnr8eh5c933sjrdkge"
    },
    {
      "xprv":
          "xprv1czm39axqut0k35q9gyfwlvyp5l7l3g72jgyef064t3qwfsjfx4ye8am546gsqhdgc6djcnzel2qdws0vafnjyf32ddzhd5jeeasw7vxq2a3lpdgsjsnz05xgks2rtzzp5xt53mzruyf46tcvfkq4svvguyqkneez",
      "xpub":
          "xpub1jpkks95u3wlu8uxdjq2xr3xgyn56klxm4uut0d4avmj5mgzpzyyuq4mr7z63p9pxylgv3dq5xkyyrgvhfrky8cgnt5hscnvptqcc3cgyl30uf"
    },
  ];

  const xprvCoder = Bech32Coder(hrp: 'xprv');
  const xpubCoder = Bech32Coder(hrp: 'xpub');
  // const mPrvCoder = Bech32Coder(hrp: 'ed25519e_sk1');
  // const mPubCoder = Bech32Coder(hrp: 'ed25519_pk1');
  const derivator = Bip32Ed25519KeyDerivation.instance;
  final chainPrvSigning = Bip32SigningKey.decode(chainPrv, coder: xprvCoder);
  final chainPubVerify = Bip32VerifyKey.decode(chainPub, coder: xpubCoder);

  group('key generation - ', () {
    test('mnemoic to entropy', () {
      final String entropy = bip39.mnemonicToEntropy(testMnemonic1);
      expect(entropy, equals(testEntropy1));
    });
    test('mnemonic to seed hex', () {
      final seedHex =
          bip39.mnemonicToSeedHex(testMnemonic1, passphrase: "TREZOR");
      print("seedHex: $seedHex");
      expect(seedHex, equals(testHexSeed1));
    });
    // test('seed hex to master bech32', () async {
    //   var masterPrivate = await ED25519_HD_KEY.getMasterKeyFromSeed(hex.HEX.decode(testHexSeed1));
    //   final masterPrivateHex = hex.HEX.encode(masterPrivate.key);
    //   print(masterPrivateHex);
    //   expect(masterPrivateHex, equals(masterPrv));
    //   var masterPublic = await ED25519_HD_KEY.getPublicKey(masterPrivate.key);
    //   expect(hex.HEX.encode(masterPublic), equals(masterPub));
    //   // print("seedHex: $seedHex");
    //   // expect(seedHex, equals(testHexSeed1));
    // });
    // test('seed hex to master raw', () async {
    //   const seed = "000102030405060708090a0b0c0d0e0f";
    //   var master = await ED25519_HD_KEY.getMasterKeyFromSeed(hex.decode(seed));
    //   expect(hex.encode(master.key), equals(""));
    //   expect(hex.encode(master.chainCode), equals(""));
    //   // print("seedHex: $seedHex");
    //   // expect(seedHex, equals(testHexSeed1));
    // });
    // test('master to purpose', () {
    //   final seedHex = bip39.mnemonicToSeedHex(testMnemonic1, passphrase: "TREZOR");
    //   print("seedHex: $seedHex");
    //   expect(seedHex, equals(testHexSeed1));
    // });
    // test('purpose to coin', () {
    //   final seedHex = bip39.mnemonicToSeedHex(testMnemonic1, passphrase: "TREZOR");
    //   print("seedHex: $seedHex");
    //   expect(seedHex, equals(testHexSeed1));
    // });
    // test('coin to account 0', () {
    //   final seedHex = bip39.mnemonicToSeedHex(testMnemonic1, passphrase: "TREZOR");
    //   print("seedHex: $seedHex");
    //   expect(seedHex, equals(testHexSeed1));
    // });

    var idx = 0;
    for (var keypair in chainPairs) {
      test('m/1852\'/1815\'/0\'/0/$idx', () {
        final xprv = keypair['xprv']!;
        final xpub = keypair['xpub']!;
        final k = Bip32SigningKey.decode(xprv, coder: xprvCoder);
        final K = Bip32VerifyKey.decode(xpub, coder: xpubCoder);
        final derivedPrv = derivator.ckdPriv(chainPrvSigning, idx);
        final derivedPub = derivator.ckdPub(chainPubVerify, idx);
        assert(k == derivedPrv);
        assert(K == derivedPub);
        idx++;
      });
    }
  });
}
