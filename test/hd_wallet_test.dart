// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32_ed25519/bip32_ed25519.dart';
import 'package:hex/hex.dart';
import 'package:pinenacl/key_derivation.dart';
import 'package:test/test.dart';

List<int> tolist(String csv) =>
    csv.split(',').map((n) => int.parse(n)).toList();

void main() {
  //final entropyPlusCs24Words = 256;
  const testMnemonic1 =
      "rude stadium move tumble spice vocal undo butter cargo win valid session question walk indoor nothing wagon column artefact monster fold gallery receive just";
  const testEntropy1 =
      "bcfa7e43752d19eabb38fa22bf6bc3622af9ed1cc4b6f645b833c7a5a8be2ce3";
  const testHexSeed1 =
      'ee344a00f29cc2fb0a84e43afd91f06beabe5f39e9e84eec729f64c56068d5795ea367d197e5d851a529f33e1d582c63887d0bb59fba8956d78fcf9f697f16a1';
  final excpectedXskBip32Bytes = tolist(
      '152,156,7,208,14,141,61,24,124,24,85,242,84,104,224,19,251,27,202,217,52,48,252,90,41,138,37,152,2,17,143,69,30,132,107,115,166,39,197,74,177,61,73,245,153,91,133,99,179,42,216,96,192,25,162,139,11,149,50,9,205,17,188,24,67,84,138,25,214,42,52,209,113,75,26,194,25,3,82,78,255,250,186,0,196,244,252,178,3,100,150,97,182,30,44,166');
  final expectedXvkBip32Bytes = tolist(
      '144,157,252,200,194,195,56,252,90,234,197,170,203,188,44,108,87,67,179,130,54,219,203,57,57,5,159,226,111,24,18,158,67,84,138,25,214,42,52,209,113,75,26,194,25,3,82,78,255,250,186,0,196,244,252,178,3,100,150,97,182,30,44,166');
  final expectedPurposeXsk = tolist(
      '184,74,168,186,106,194,150,231,102,65,4,152,99,223,135,221,172,111,161,213,247,232,5,104,70,137,45,159,3,17,143,69,185,148,219,125,227,191,90,209,187,14,186,202,238,5,40,3,126,167,45,77,98,97,196,155,137,209,156,114,248,63,132,20,24,173,18,17,250,137,178,51,117,154,118,193,74,61,58,237,1,117,26,105,181,45,253,35,129,230,99,44,202,180,207,58');
  final expectedCoinTypeXsk = tolist(
      '168,20,53,153,225,95,189,33,37,223,221,179,95,87,95,173,36,26,69,122,164,192,96,113,233,34,221,163,3,17,143,69,13,219,136,133,14,140,84,207,148,241,93,82,57,166,103,54,152,156,198,70,254,62,37,213,117,32,194,118,252,106,243,91,152,227,170,252,140,142,206,250,55,157,136,182,253,116,99,243,136,59,60,64,15,225,113,195,108,201,251,70,74,252,111,24');
  final expectedAccount0Xsk = tolist(
      '64,246,231,31,5,34,87,102,234,127,223,47,231,16,38,174,155,203,159,162,244,12,68,28,233,29,109,16,7,17,143,69,99,163,20,154,255,245,240,102,22,115,68,73,66,109,26,74,157,47,205,195,175,131,141,179,153,220,26,66,152,143,39,236,77,87,90,245,169,59,223,73,5,163,112,47,173,237,244,81,234,88,71,145,210,51,173,233,9,101,214,8,186,197,115,4');
  final expectedChange0Xsk = tolist(
      '32,252,38,192,255,180,208,38,209,162,139,214,141,102,30,46,192,248,56,119,93,226,69,198,254,58,141,139,13,17,143,69,224,178,189,12,154,221,217,239,241,203,71,202,74,183,204,47,136,167,210,244,145,190,241,11,68,112,19,130,182,133,18,35,96,160,127,43,182,21,248,82,206,177,177,173,172,158,72,208,107,10,26,177,129,220,101,177,220,6,159,132,181,88,187,203');
  final expectedSpend0Xsk = tolist(
      '16,41,227,180,98,205,86,19,164,21,138,56,61,41,138,149,60,198,210,108,65,244,169,96,247,21,18,90,21,17,143,69,194,70,255,246,50,124,72,102,231,105,50,116,96,25,83,94,245,96,206,37,0,21,11,224,246,1,224,54,119,47,202,15,23,236,32,214,162,3,215,59,218,48,86,59,210,15,41,200,58,115,47,149,36,193,106,147,177,129,121,138,250,247,136,13');
  final expectedSpend0Xvk = tolist(
      '249,22,43,145,18,98,18,183,21,0,232,157,199,218,49,17,29,252,20,102,169,242,79,72,163,78,126,165,41,210,211,56,23,236,32,214,162,3,215,59,218,48,86,59,210,15,41,200,58,115,47,149,36,193,106,147,177,129,121,138,250,247,136,13');
  final expectedStake0Xsk = tolist(
      '40,184,124,185,16,22,113,157,33,204,24,190,209,97,23,160,125,79,145,114,178,38,114,18,12,243,32,248,12,17,143,69,125,104,75,46,40,163,136,6,34,32,65,216,70,97,70,131,241,143,123,118,111,164,172,17,148,250,121,254,98,152,125,49,87,224,30,183,139,184,57,170,146,167,191,86,138,123,240,59,3,81,148,105,27,177,61,94,63,155,51,150,90,200,13,150');
  final expectedStake0Xvk = tolist(
      '198,178,48,87,100,108,196,77,168,58,125,66,86,243,155,111,205,69,182,176,228,239,165,107,172,195,228,202,189,233,179,128,87,224,30,183,139,184,57,170,146,167,191,86,138,123,240,59,3,81,148,105,27,177,61,94,63,155,51,150,90,200,13,150');
  const expectedSpend0Bech32 =
      'addr1qyy6nhfyks7wdu3dudslys37v252w2nwhv0fw2nfawemmn8k8ttq8f3gag0h89aepvx3xf69g0l9pf80tqv7cve0l33sdn8p3d';
  const expectedTestnetSpend0Bech32 =
      'addr_test1qqy6nhfyks7wdu3dudslys37v252w2nwhv0fw2nfawemmn8k8ttq8f3gag0h89aepvx3xf69g0l9pf80tqv7cve0l33sw96paj';

  /// Extended Public key size in bytes
  // const xpub_size = 64;
  const publicKeySize = 32;
  // const choin_code_size = 32;

  group('rust cardano-serialization-lib test -', () {
    test('entropy to root private and public keys', () {
      //[0x4e,0x82,0x8f,0x9a,0x67,0xdd,0xcf,0xf0,0xe6,0x39,0x1a,0xd4,0xf2,0x6d,0xdb,0x75,0x79,0xf5,0x9b,0xa1,0x4b,0x6d,0xd4,0xba,0xf6,0x3d,0xcf,0xdb,0x9d,0x24,0x20,0xda];
      const testEntropy =
          '4e828f9a67ddcff0e6391ad4f26ddb7579f59ba14b6dd4baf63dcfdb9d2420da';
      final seed = Uint8List.fromList(HEX.decode(testEntropy));
      final rawMaster = PBKDF2.hmac_sha512(
          Uint8List(0), seed, 4096, cip16ExtendedSigningKeySize);
      expect(rawMaster[0], 156, reason: 'byte 0 before normalization');
      expect(rawMaster[31], 101, reason: 'byte 31 before normalization');
      //print(rawMaster.join(','));
      final Bip32SigningKey rootXsk = Bip32SigningKey.normalizeBytes(rawMaster);
      expect(rootXsk.keyBytes[0], 152, reason: 'byte 0 after normalization');
      expect(rootXsk.keyBytes[31], 69, reason: 'byte 31 after normalization');
      //print(xpvtKey.keyBytes.join(','));
      expect(rootXsk.keyBytes,
          excpectedXskBip32Bytes.sublist(0, cip16ExtendedVerificationgKeySize),
          reason: 'first 64 bytes are private key');
      expect(rootXsk.chainCode,
          excpectedXskBip32Bytes.sublist(cip16ExtendedVerificationgKeySize),
          reason: 'second 32 bytes are chain code');
      Bip32VerifyKey rootXvk = rootXsk.verifyKey; //get public key
      expect(rootXvk.keyBytes, expectedXvkBip32Bytes.sublist(0, publicKeySize),
          reason: 'first 32 bytes are public key');
      expect(rootXvk.chainCode, expectedXvkBip32Bytes.sublist(publicKeySize),
          reason: 'second 32 bytes are chain code');
      expect(rootXsk.chainCode, rootXvk.chainCode,
          reason: 'chain code is identical in both private and public keys');
      //generate chain and addresses - m/1852'/1815'/0'/0/0
      const derivator = Bip32Ed25519KeyDerivation.instance;
      final pvtPurpose1852 = derivator.ckdPriv(rootXsk, harden(1852));
      expect(pvtPurpose1852, expectedPurposeXsk);
      final pvtCoin1815 = derivator.ckdPriv(pvtPurpose1852, harden(1815));
      expect(pvtCoin1815, expectedCoinTypeXsk);
      final pvtAccount0 = derivator.ckdPriv(pvtCoin1815, harden(0));
      expect(pvtAccount0, expectedAccount0Xsk);
      final pvtChange0 = derivator.ckdPriv(pvtAccount0, 0);
      expect(pvtChange0, expectedChange0Xsk);
      final pvtAddress0 = derivator.ckdPriv(pvtChange0, 0);
      expect(pvtAddress0, expectedSpend0Xsk);
      final pubAddress0 = pvtAddress0.publicKey;
      expect(pubAddress0, expectedSpend0Xvk);
    });
  });

  group('HdWallet -', () {
    test('private/public key and address generation', () {
      const testEntropy =
          '4e828f9a67ddcff0e6391ad4f26ddb7579f59ba14b6dd4baf63dcfdb9d2420da';
      final hdWallet = HdWallet.fromHexEntropy(testEntropy);
      expect(hdWallet.rootSigningKey, excpectedXskBip32Bytes,
          reason: 'root private/signing key');
      expect(hdWallet.rootVerifyKey, expectedXvkBip32Bytes,
          reason: 'root public/verify key');
      final Bip32KeyPair spendAddress0Pair =
          hdWallet.deriveAddressKeys(index: 0);
      expect(spendAddress0Pair.signingKey, expectedSpend0Xsk);
      expect(spendAddress0Pair.verifyKey, expectedSpend0Xvk);
      final Bip32KeyPair stakeAddress0Pair =
          hdWallet.deriveAddressKeys(role: stakingRole, index: 0);
      expect(stakeAddress0Pair.signingKey, expectedStake0Xsk);
      expect(stakeAddress0Pair.verifyKey, expectedStake0Xvk);
      final addr0 = hdWallet.toBaseAddress(
          networkId: NetworkId.mainnet,
          spend: spendAddress0Pair.verifyKey!,
          stake: stakeAddress0Pair.verifyKey!);
      // print(addr0.join(','));
      expect(addr0.toBech32(), expectedSpend0Bech32);
      final addrTest0 = hdWallet.toBaseAddress(
          spend: spendAddress0Pair.verifyKey!,
          stake: stakeAddress0Pair.verifyKey!);
      expect(addrTest0.toBech32(), expectedTestnetSpend0Bech32);
    });

    test('bip32_12_reward address', () {
      const mnemonic =
          'test walk nut penalty hip pave soap entry language right filter choice';
      final hdWallet = HdWallet.fromMnemonic(mnemonic);
      final Bip32KeyPair stakeAddress0Pair =
          hdWallet.deriveAddressKeys(role: stakingRole);
      final stake = hdWallet.toRewardAddress(
          networkId: NetworkId.mainnet, spend: stakeAddress0Pair.verifyKey!);
      expect(stake.toBech32(),
          'stake1uyevw2xnsc0pvn9t9r9c7qryfqfeerchgrlm3ea2nefr9hqxdekzz');
      final stakeTest =
          hdWallet.toRewardAddress(spend: stakeAddress0Pair.verifyKey!);
      expect(stakeTest.toBech32(),
          'stake_test1uqevw2xnsc0pvn9t9r9c7qryfqfeerchgrlm3ea2nefr9hqp8n5xl');
    });
  });

  /*
cardano-address logs
Notes: --network-tag 1 is mainnet,--network-tag 0 is testnet
Source: https://github.com/input-output-hk/cardano-addresses
Source: https://github.com/uniVocity/cardano-tutorials/blob/master/cardano-addresses.md


> ./cardano-address recovery-phrase generate --size 24 > phrase.prv
> cat phrase.prv
rude stadium move tumble spice vocal undo butter cargo win valid session question walk indoor nothing wagon column artefact monster fold gallery receive just
> cat phrase.prv | ./cardano-address key from-recovery-phrase Shelley > root.xsk
> cat root.xsk 
root_xsk1wp6nhemf5djl9rf7mrzw2u75xuy2g2tsmyyqd7u73v44qt8f49xqus60er5l3r33lj9shhvqygav3l3hy62ewj2l7pj86ft9nwgq2rguxtkz7j66aqjf80xeccepd3873e5umsee5z454wqv82xcl80xuvv57734%                                                                          > cat root.xsk | ./cardano-address key public > public_key.txt
> cat public_key.txt 
> cat root.xsk | ./cardano-address key public --with-chain-code > public_key.txt
> cat public_key.txt                                                                   
root_xvk1rgd2fz33qwe83vdy2sxcduavx5c56m8m232ezyvkqx07upzyhwy3cvhv9a9446pyjw7dn33jzmz0arnfehpnng9tf2uqcw5d37w7dcc9psu04%                                                                                                                                      
> cat root.xsk | ./cardano-address key public --without-chain-code > public_key-without-chain-code.txt
> cat public_key-without-chain-code.txt                                                                      
root_vk1rgd2fz33qwe83vdy2sxcduavx5c56m8m232ezyvkqx07upzyhwysp0js2t%                                                                                                                                                                                          
> cat root.xsk | ./cardano-address key child 1852H/1815H/0H > account_0_key_path.txt
> cat account_0_key_path.txt 
acct_xsk1npdht8s7wzqf5whm8ahyrwg6w3tjnh53c56zk675f67xwvhf49x0kt9tks8w49039ytmaurnngvmqxuq3cq09jhp2vg6d59sn3k96hsem5tw77eusxvvwzpee9acnzd0jclzjtaspr49k2ytk5ndx4xvsur7vh0j%                                                                                   
> cat account_0_key_path.txt | ./cardano-address key public --with-chain-code > account_0_public_root_key.txt 
> cat account_0_public_root_key.txt 
acct_xvk1r7ceazv8kqssd9rk4u3p2hdmprplrn8pftj798qnq8hygwkc6ft3nhgkaaaneqvccuyrnjtm3xy6l9379yhmqz82tv5ghdfx6d2vepc0vn0hr%                                                                                                                                      
> cat account_0_public_root_key.txt | ./cardano-address key child 0/0 > key_for_account_0_address_0.txt
> cat key_for_account_0_address_0.txt 
addr_xvk1esyq6apw8590yjux07mt97m964zafmwcux2vht2d0x454xm2qtp8d6xtgkwxq6l36c35adzjeguu04t39d7nnvr30x8nh9quur9unqqjtlzzr%                                                                                                                                      
> cat account_0_public_root_key.txt | ./cardano-address key child 0/1 > key_for_account_0_address_1.txt
> cat key_for_account_0_address_1.txt                                                                  
addr_xvk1zm347726w5t93vy0ghd00xjtezyx4rlmynv5zzgps8n95trekzwh6zzv3z3x0wuqp86jundlt7t6et0pjqkwxjtq3snd6wn6jzcy50gcctsw2%                                                                                                                                      
> cat key_for_account_0_address_0.txt | ./cardano-address address payment --network-tag 1 > pay_to_account_0_address_0.txt
> cat pay_to_account_0_address_0.txt                                                                                      
addr1v8lqwws609v256tuydd4hf5vanrwyljwftanh2ntafkkpkghlyxln%                                                                                                                                                                                                  
> ./cardano-address key child 1852H/1815H/0H/2/0 < root.xsk | ./cardano-address key public --with-chain-code > stake.xvk
> cat stake.xvk 
stake_xvk18qvnk9eppdf0qnl7csz5h7lwdhf4jhjhu6x8a6m7fmmgz94zu9pv5xkazdaavyeq0xv9lz7cpj3u4yz5q5p4wk3hksppsskdrkm6ucqalzd2x%                                                                                                                                     
> ./cardano-address key child 1852H/1815H/0H/0/0 < root.xsk | ./cardano-address key public --with-chain-code > addr.xvk
> cat addr.xvk
addr_xvk1esyq6apw8590yjux07mt97m964zafmwcux2vht2d0x454xm2qtp8d6xtgkwxq6l36c35adzjeguu04t39d7nnvr30x8nh9quur9unqqjtlzzr%                                                                                                                                      
> ./cardano-address address payment --network-tag testnet < addr.xvk > payment.addr
> cat payment.addr
addr_test1vrlqwws609v256tuydd4hf5vanrwyljwftanh2ntafkkpkgvhs6sk%                                                                                                                                                                                             
> ./cardano-address address delegation $(cat stake.xvk) < payment.addr > payment-delegated.addr
> cat payment-delegated.addr 
addr_test1qrlqwws609v256tuydd4hf5vanrwyljwftanh2ntafkkpkv3vuea47tq3shgvp2376dn5stzdz2ge90tmuac00v4cnjqm2rpzj%                                                                                                                                                
> ./cardano-address address stake --network-tag testnet < stake.xvk > stake.addr
> cat stake.addr 
stake_test1uzgkwv76l9sgct5xq4gldxe6g93x39yvjh4a7wu8hk2ufeqx3aar6%  
>
> cat root.xsk | ./cardano-address key public --with-chain-code | ./cardano-address key inspect 
{
    "chain_code": "1c32ec2f4b5ae82493bcd9c63216c4fe8e69cdc339a0ab4ab80c3a8d8f9de6e3",
    "key_type": "public",
    "extended_key": "1a1aa48a3103b278b1a4540d86f3ac35314d6cfb5455911196019fee0444bb89"
}
>
> ls
account_0_key_path.txt                  cardano-address                         pay_to_account_0_address_0.txt          root.xsk                         phrase.prv
account_0_public_root_key.txt           key_for_account_0_address_0.txt         payment-delegated.addr                  public_key-without-chain-code.txt       stake.addr
addr.xvk                                key_for_account_0_address_1.txt         payment.addr                            public_key.txt                          stake.xvk

*/
  group('Haskell cardano-address data -', () {
    const mnemonic =
        'rude stadium move tumble spice vocal undo butter cargo win valid session question walk indoor nothing wagon column artefact monster fold gallery receive just';
    const addr0Testnet =
        'addr_test1qrlqwws609v256tuydd4hf5vanrwyljwftanh2ntafkkpkv3vuea47tq3shgvp2376dn5stzdz2ge90tmuac00v4cnjqm2rpzj';
    const addr1Testnet =
        'addr_test1qp68ev9dryvaq4nn0yyntv3zwmrcvz99mgr4f7yqzzq6c6v3vuea47tq3shgvp2376dn5stzdz2ge90tmuac00v4cnjqfmsyuj';
    const addr0Mainnet =
        'addr1q8lqwws609v256tuydd4hf5vanrwyljwftanh2ntafkkpkv3vuea47tq3shgvp2376dn5stzdz2ge90tmuac00v4cnjqcu7pwd';
    const change0Mainnet =
        'addr1qx25lzk4msem7df6a3ktcqh7knmzqul40rjxyghyk69jqnv3vuea47tq3shgvp2376dn5stzdz2ge90tmuac00v4cnjq5cyenl';
    test('toBaseAddress', () {
      final hdWallet = HdWallet.fromMnemonic(mnemonic);
      print("hdWallet.rootSigningKey: ${hdWallet.rootSigningKey.encode()}");
      print("hdWallet.rootVerifyKey:  ${hdWallet.rootVerifyKey.encode()}");
      final Bip32KeyPair stakeAddress0Pair =
          hdWallet.deriveAddressKeys(role: stakingRole);
      final verifyKey = stakeAddress0Pair.verifyKey!;
      print("verifyKey: ${verifyKey.encode()}");
      expect(
          verifyKey.encode(Bech32Coder(hrp: 'root_xpk')),
          // verifyKey.encode(),
          'root_xpk18qvnk9eppdf0qnl7csz5h7lwdhf4jhjhu6x8a6m7fmmgz94zu9pv5xkazdaavyeq0xv9lz7cpj3u4yz5q5p4wk3hksppsskdrkm6ucqas6km0');
      final stakeTest =
          hdWallet.toRewardAddress(spend: stakeAddress0Pair.verifyKey!);
      expect(stakeTest.toBech32(),
          'stake_test1uzgkwv76l9sgct5xq4gldxe6g93x39yvjh4a7wu8hk2ufeqx3aar6');
      final Bip32KeyPair spendAddress0Pair = hdWallet.deriveAddressKeys();
      final addrTest = hdWallet.toBaseAddress(
          spend: spendAddress0Pair.verifyKey!,
          stake: stakeAddress0Pair.verifyKey!);
      expect(addrTest.toBech32(), addr0Testnet);
    });
    test('deriveUnusedBaseAddress', () {
      final hdWallet = HdWallet.fromMnemonic(mnemonic);
      ShelleyAddress spend0 = hdWallet.deriveUnusedBaseAddressKit().address;
      expect(spend0.toBech32(), addr0Testnet);
      ShelleyAddress spend1 =
          hdWallet.deriveUnusedBaseAddressKit(index: 1).address;
      expect(spend1.toBech32(), addr1Testnet);
      ShelleyAddress spend1a = hdWallet
          .deriveUnusedBaseAddressKit(
              unusedCallback: (a) => a.toBech32() != addr0Testnet)
          .address;
      expect(spend1a.toBech32(), addr1Testnet,
          reason: 'callback flags addr0 as used, so returns addr1');
      ShelleyAddress spend0Mainnet = hdWallet
          .deriveUnusedBaseAddressKit(networkId: NetworkId.mainnet)
          .address;
      expect(spend0Mainnet.toBech32(), addr0Mainnet);
      ShelleyAddress change0 = hdWallet
          .deriveUnusedBaseAddressKit(
              networkId: NetworkId.mainnet, role: changeRole)
          .address;
      expect(change0.toBech32(), change0Mainnet);
    });

    test('buildAddressKitCache', () {
      final mnemonicBob =
          'army bid park alter aunt click border awake happy sport addict heavy robot change artist sniff height general dust fiber salon fan snack wheat';
      final spend9 =
          'addr_test1qpgtfaalupum9evdwqleqcp5rhac8nty720mahpse4pc35p7v8d0ph6h78xxlkc4e6nxz5xk873akuwfp78nx7tqysas3zacqu';
      final change0 =
          'addr_test1qqnfp25ptct0gg3xust2jty863g0l8lugjgvkz4nn5x2tcp7v8d0ph6h78xxlkc4e6nxz5xk873akuwfp78nx7tqysasgzufcd';
      final hdWallet = HdWallet.fromMnemonic(mnemonicBob);
      List<ShelleyAddressKit> spendResults =
          hdWallet.buildAddressKitCache(usedSet: {});
      expect(spendResults[9].address.toBech32(), spend9);
      List<ShelleyAddressKit> changeResults = hdWallet.buildAddressKitCache(
          role: changeRole, beyondUsedOffset: 5, usedSet: {});
      expect(changeResults.length, 5, reason: 'overrun 5');
      expect(changeResults[0].address.toBech32(), change0);
      List<ShelleyAddressKit> changeResults2 = hdWallet.buildAddressKitCache(
          role: changeRole,
          beyondUsedOffset: 5,
          usedSet: {ShelleyAddress.fromBech32(change0)});
      expect(changeResults2.length, 6,
          reason: 'overrun 5 beyond existing used addresses');
    });
  });

  group('convergence -', () {
    const testEntropy =
        '4e828f9a67ddcff0e6391ad4f26ddb7579f59ba14b6dd4baf63dcfdb9d2420da';
    final hdWallet = HdWallet.fromHexEntropy(testEntropy);
    final Bip32KeyPair stakeAddress0Pair =
        hdWallet.deriveAddressKeys(role: stakingRole, index: 0);
    setUp(() {});
    test('validate', () {
      final Bip32KeyPair keys0 = hdWallet.deriveAddressKeys(index: 0);
      final addr0 = hdWallet.toBaseAddress(
          networkId: NetworkId.mainnet,
          spend: keys0.verifyKey!,
          stake: stakeAddress0Pair.verifyKey!);
      print('   addr[0]: ${addr0.toBech32()}');
      final Bip32KeyPair keys1 = hdWallet.deriveAddressKeys(index: 1);
      final addr1 = hdWallet.toBaseAddress(
          networkId: NetworkId.mainnet,
          spend: keys1.verifyKey!,
          stake: stakeAddress0Pair.verifyKey!);
      print('   addr[1]: ${addr1.toBech32()}');
      //public to public key
      final Bip32KeyPair keys1Pub = hdWallet.derive(
          keys: Bip32KeyPair(signingKey: null, verifyKey: keys0.verifyKey),
          index: 1);
      final addr1Pub = hdWallet.toBaseAddress(
          networkId: NetworkId.mainnet,
          spend: keys1Pub.verifyKey!,
          stake: stakeAddress0Pair.verifyKey!);
      print('addrPub[1]: ${addr1Pub.toBech32()}');
      expect(addr1Pub.toBech32(), equals(addr1.toBech32()));
    }, skip: 'path generation misunderstanding?');
  });

  group('mnemonic words -', () {
    setUp(() {});
    test('validate', () {
      expect(bip39.validateMnemonic(testMnemonic1), isTrue,
          reason: 'validateMnemonic returns true');
    });
    test('to entropy', () {
      final String entropy = bip39.mnemonicToEntropy(testMnemonic1);
      //print(entropy);
      expect(entropy, equals(testEntropy1));
    });
    test('to seed hex', () {
      final seedHex =
          bip39.mnemonicToSeedHex(testMnemonic1, passphrase: "TREZOR");
      //print("seedHex: $seedHex");
      expect(seedHex, equals(testHexSeed1));
    });
  });
}
