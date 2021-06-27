import 'dart:typed_data';

import 'package:pinenacl/key_derivation.dart';

import 'package:cardano_wallet_sdk/src/bip32_ed25519/api.dart';
import 'package:cardano_wallet_sdk/src/bip32_ed25519/bip32_ed25519.dart';

class CardanoKeyIcarus extends Bip32Ed25519 {
  CardanoKeyIcarus(Uint8List masterSecret) : super(masterSecret);
  CardanoKeyIcarus.seed(String seed) : super.seed(seed);
  CardanoKeyIcarus.import(String key) : super.import(key);

  @override
  Bip32Key master(Uint8List seed) {
    final rawMaster = PBKDF2.hmac_sha512(Uint8List(0), seed, 4096, 96);

    return Bip32SigningKey.normalizeBytes(rawMaster);
  }

  @override
  Bip32Key doImport(String key) {
    // First we try the verify key as it's very cheap computationally.
    try {
      return Bip32VerifyKey.decode(key);
    } catch (e) {
      return Bip32SigningKey.decode(key);
    }
  }
}
