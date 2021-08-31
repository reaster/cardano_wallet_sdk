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
import 'dart:typed_data';
import 'package:bip39/bip39.dart' as bip39;
import 'package:cardano_wallet_sdk/src/bip32_ed25519/bip32_ed25519.dart';
// import 'package:cardano_wallet_sdk/src/util/codec.dart';
import 'package:hex/hex.dart';
import 'package:pinenacl/key_derivation.dart';
import 'package:test/test.dart';

void main() {
  final entropyPlusCs24Words = 256;
  final testMnemonic1 =
      "rude stadium move tumble spice vocal undo butter cargo win valid session question walk indoor nothing wagon column artefact monster fold gallery receive just";
  final testEntropy1 = "bcfa7e43752d19eabb38fa22bf6bc3622af9ed1cc4b6f645b833c7a5a8be2ce3";
  final testHexSeed1 =
      'ee344a00f29cc2fb0a84e43afd91f06beabe5f39e9e84eec729f64c56068d5795ea367d197e5d851a529f33e1d582c63887d0bb59fba8956d78fcf9f697f16a1';

  /// Extended Private key size in bytes
  const xprv_size = 96;
  const extended_secret_key_size = 64;

  /// Extended Public key size in bytes
  const xpub_size = 64;
  const public_key_size = 32;
  const choin_code_size = 32;
/*
pub fn from_bip39_entropy(entropy: &[u8],password: &[u8]) -> SecretKey<Ed25519Bip32> {
    let mut pbkdf2_result = [0; XPRV_SIZE];

    const ITER: u32 = 4096;
    let mut mac = Hmac::new(Sha512::new(),password);
    pbkdf2(&mut mac,entropy.as_ref(),ITER,&mut pbkdf2_result);

    SecretKey(XPrv::normalize_bytes_force3rd(pbkdf2_result))
}

  Bip32Key master(Uint8List seed) {
    final rawMaster = PBKDF2.hmac_sha512(Uint8List(0),seed,4096,96);

    return Bip32SigningKey.normalizeBytes(rawMaster);
  }

*/
  group('cardano-serialization-lib', () {
    test('entropy to root private and public keys', () {
      final excpectedXskBip32Bytes =
          '152,156,7,208,14,141,61,24,124,24,85,242,84,104,224,19,251,27,202,217,52,48,252,90,41,138,37,152,2,17,143,69,30,132,107,115,166,39,197,74,177,61,73,245,153,91,133,99,179,42,216,96,192,25,162,139,11,149,50,9,205,17,188,24,67,84,138,25,214,42,52,209,113,75,26,194,25,3,82,78,255,250,186,0,196,244,252,178,3,100,150,97,182,30,44,166'
              .split(',')
              .map((n) => int.parse(n))
              .toList();
      final expectedXvkBip32Bytes =
          '144,157,252,200,194,195,56,252,90,234,197,170,203,188,44,108,87,67,179,130,54,219,203,57,57,5,159,226,111,24,18,158,67,84,138,25,214,42,52,209,113,75,26,194,25,3,82,78,255,250,186,0,196,244,252,178,3,100,150,97,182,30,44,166'
              .split(',')
              .map((n) => int.parse(n))
              .toList();
      //[0x4e,0x82,0x8f,0x9a,0x67,0xdd,0xcf,0xf0,0xe6,0x39,0x1a,0xd4,0xf2,0x6d,0xdb,0x75,0x79,0xf5,0x9b,0xa1,0x4b,0x6d,0xd4,0xba,0xf6,0x3d,0xcf,0xdb,0x9d,0x24,0x20,0xda];
      final testEntropy = '4e828f9a67ddcff0e6391ad4f26ddb7579f59ba14b6dd4baf63dcfdb9d2420da';
      final seed = Uint8List.fromList(HEX.decode(testEntropy));
      final rawMaster = PBKDF2.hmac_sha512(Uint8List(0), seed, 4096, xprv_size);
      expect(rawMaster[0], 156, reason: 'byte 0 before normalization');
      expect(rawMaster[31], 101, reason: 'byte 31 before normalization');
      //print(rawMaster.join(','));
      final Bip32SigningKey root_xsk = Bip32SigningKey.normalizeBytes(rawMaster);
      expect(root_xsk.keyBytes[0], 152, reason: 'byte 0 after normalization');
      expect(root_xsk.keyBytes[31], 69, reason: 'byte 31 after normalization');
      //print(xpvtKey.keyBytes.join(','));
      expect(root_xsk.keyBytes, excpectedXskBip32Bytes.sublist(0, extended_secret_key_size), reason: 'first 64 bytes are private key');
      expect(root_xsk.chainCode, excpectedXskBip32Bytes.sublist(extended_secret_key_size), reason: 'second 32 bytes are chain code');
      Bip32VerifyKey root_xvk = root_xsk.verifyKey;
      expect(root_xvk.keyBytes, expectedXvkBip32Bytes.sublist(0, public_key_size), reason: 'first 32 bytes are public key');
      expect(root_xvk.chainCode, expectedXvkBip32Bytes.sublist(public_key_size), reason: 'second 32 bytes are chain code');
      expect(root_xsk.chainCode, root_xvk.chainCode);
    });
  });

  group('mnemonic words -', () {
    setUp(() {});
    test('validate', () {
      expect(bip39.validateMnemonic(testMnemonic1), isTrue, reason: 'validateMnemonic returns true');
    });
    test('to entropy', () {
      final String entropy = bip39.mnemonicToEntropy(testMnemonic1);
      //print(entropy);
      expect(entropy, equals(testEntropy1));
    });
    test('to seed hex', () {
      final seedHex = bip39.mnemonicToSeedHex(testMnemonic1, passphrase: "TREZOR");
      //print("seedHex: $seedHex");
      expect(seedHex, equals(testHexSeed1));
    });
  });

  // const xprvCoder = Bech32Coder(hrp: 'xprv');
  // const xpubCoder = Bech32Coder(hrp: 'xpub');
  // group('Key derivation tests',() {
  //   final dir = Directory.current;
  //   final file = File('${dir.path}/test/data/yoroi_keys.json');

  //   final contents = file.readAsStringSync();
  //   final dynamic yoroi = JsonDecoder().convert(contents);

  //   final dynamic keypairs = yoroi['keypairs'];

  //   final dynamic ck = yoroi['chain_prv']! as String;
  //   final dynamic cK = yoroi['chain_pub']! as String;

  //   group('mnemonic words -',() {
  //     final chainPrv = Bip32SigningKey.decode(ck,coder: xprvCoder);
  //     final chainPub = Bip32VerifyKey.decode(cK,coder: xpubCoder);
  //   });
  // });
}
