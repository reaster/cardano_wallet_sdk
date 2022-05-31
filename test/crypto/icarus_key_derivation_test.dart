// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:bip32_ed25519/bip32_ed25519.dart';
import 'package:hex/hex.dart';
import 'package:pinenacl/key_derivation.dart';
import 'package:test/test.dart';

void main() {
  group('IcarusKeyDerivation -', () {
    List<int> tolist(String csv) =>
        csv.split(',').map((n) => int.parse(n)).toList();
    const entropyHex =
        "4e828f9a67ddcff0e6391ad4f26ddb7579f59ba14b6dd4baf63dcfdb9d2420da";
    final entropy = HexCoder.instance.decode(entropyHex);
    final masterKey = cardanoEntropyToRootSigningKey(entropy);
    final excpectedXskBytes96 = tolist(
        '152,156,7,208,14,141,61,24,124,24,85,242,84,104,224,19,251,27,202,217,52,48,252,90,41,138,37,152,2,17,143,69,30,132,107,115,166,39,197,74,177,61,73,245,153,91,133,99,179,42,216,96,192,25,162,139,11,149,50,9,205,17,188,24,67,84,138,25,214,42,52,209,113,75,26,194,25,3,82,78,255,250,186,0,196,244,252,178,3,100,150,97,182,30,44,166');
    //final Bech32Coder rootXsk = Bech32Coder(hrp: 'root_xsk');
    const rootXsk =
        'root_xsk1nzwq05qw3573slqc2he9g68qz0a3hjkexsc0ck3f3gjesqs33az3aprtwwnz0322ky75navetwzk8ve2mpsvqxdz3v9e2vsfe5gmcxzr2j9pn432xnghzjc6cgvsx5jwllat5qxy7n7tyqmyjesmv83v5cg2v2tz';
    final acct0XskBytes = tolist(
        '48, 245, 170, 143, 126, 183, 92, 208, 221, 36, 229, 132, 200, 12, 143, 190, 181, 140, 92, 241, 16, 105, 162, 182, 158, 140, 219, 32, 18, 17, 143, 69, 24, 218, 170, 222, 97, 4, 72, 150, 9, 49, 31, 11, 25, 137, 43, 225, 70, 44, 234, 93, 161, 248, 100, 199, 164, 41, 58, 173, 122, 193, 181, 161, 1, 110, 240, 158, 97, 221, 140, 187, 27, 219, 94, 105, 96, 122, 202, 239, 196, 216, 136, 245, 197, 189, 192, 27, 62, 207, 136, 194, 46, 100, 144, 206');
    const acct0Xsk =
        'acct_xsk1xr664rm7kawdphfyukzvsry0h66cch83zp569d573ndjqys33az33k42messgjykpyc37zce3y47z33vafw6r7ryc7jzjw4d0tqmtggpdmcfucwa3ja3hk67d9s84jh0cnvg3aw9hhqpk0k03rpzueysec6pnfz0';
    const acct0Xvk =
        'acct_xvk158nues2j0wxm449lfs42m39vww8vrxhf2tlwjv9tfekwy7trndgszmhsnesamr9mr0d4u6tq0t9wl3xc3r6ut0wqrvlvlzxz9ejfpns0fwtce';
    const addr0Xsk =
        'addr_xsk1epu0em5lwqe9ssqnexpr4fxfea7taj35mh8znawvh4k9q9g33az6jajedqauh97z2r34ww4u9kjgv58hpp4kmm26m3dzzz3a2w7lexrxjwp999wasek0xev33yefmf0hkl97rhfway8fr26fa2kpun59vgm0s9lm';
    const addr0Xvk =
        'addr_xvk1jnv9vuajcmdsfwd6y7wlvgdwcmymfac9wvdk3tvp50205m94wwtkdyuz222ampnv7djerzfjnkjl0d7tu8wja6gwjx45n64vre8g2csh7v67c';

    // test('constructors', () {
    //   //expect(excpectedXskBytes96, masterKey);
    //   final derMaster = IcarusKeyDerivation(masterKey);
    //   expect(derMaster.root is Bip32SigningKey, isTrue);
    //   final derSeed = IcarusKeyDerivation.entropy(entropy);
    //   //expect(derMaster.root, derSeed.root);
    //   final derBech32Key = IcarusKeyDerivation.bech32Key(rootXsk);
    //   expect(derMaster.root, derBech32Key.root);
    // });

    // test('root_xsk', () {
    //   final derMaster = IcarusKeyDerivation(masterKey);
    //   expect(derMaster.root is Bip32SigningKey, isTrue);
    //   expect(
    //       derMaster.root.keyBytes,
    //       equals(excpectedXskBytes96.sublist(
    //           0, cip16ExtendedVerificationgKeySize)),
    //       reason: 'first 64 bytes are private key');
    //   expect(derMaster.root.chainCode,
    //       excpectedXskBytes96.sublist(cip16ExtendedVerificationgKeySize),
    //       reason: 'second 32 bytes are chain code');
    //   final acctXsk = derMaster.forPath("m/1852'/1885'/0'") as Bip32SigningKey;
    //   expect(acctXsk, equals(acct0XskBytes));
    //   //print(acctXsk.encode(Bech32Coder(hrp: 'acct_xsk')));
    //   final acctXvk = acctXsk.publicKey;
    //   //print(acctXvk.encode(Bech32Coder(hrp: 'acct_xvk')));
    //   final addr0Key =
    //       derMaster.forPath("m/1852'/1885'/0'/0/0") as Bip32SigningKey;
    //   expect(addr0Key.encode(Bech32Coder(hrp: 'addr_xsk')), equals(addr0Xsk));
    //   //print(addr0Key.encode(Bech32Coder(hrp: 'addr_xsk')));
    //   final addr0PublicKey = addr0Key.publicKey;
    //   expect(addr0PublicKey.encode(Bech32Coder(hrp: 'addr_xvk')),
    //       equals(addr0Xvk));
    //   //print(addr0PublicKey.encode(Bech32Coder(hrp: 'addr_xvk')));
    // });
    test('acct_xsk', () {
      final derAcct0 = IcarusKeyDerivation.bech32Key(acct0Xsk);
      final addr0Key = derAcct0.forPath("m/0/0") as Bip32SigningKey;
      expect(addr0Key.encode(Bech32Coder(hrp: 'addr_xsk')), equals(addr0Xsk));
    });
    test('acct_xvk', () {
      final derAcct0 = IcarusKeyDerivation.bech32Key(acct0Xvk);
      final addr0Key = derAcct0.forPath("M/0/0") as Bip32VerifyKey;
      expect(addr0Key.encode(Bech32Coder(hrp: 'addr_xvk')), equals(addr0Xvk));
    });
  });
}
