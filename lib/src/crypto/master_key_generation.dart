// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:pinenacl/key_derivation.dart';
import 'package:bip32_ed25519/api.dart';
// import 'package:pinenacl/digests.dart';

Bip32SigningKey icarusGenerateMasterKey(Uint8List entropy) {
  final rawMaster = PBKDF2.hmac_sha512(Uint8List(0), entropy, 4096, 96);
  return Bip32SigningKey.normalizeBytes(rawMaster);
}

// Bip32SigningKey byronGenerateMasterKey(Uint8List entropy) =>
//     _byronGenerateMasterKey(entropy, index: 0);

// Bip32SigningKey _byronGenerateMasterKey(Uint8List entropy, {int index = 0}) {
//   final rawMaster = PBKDF2.hmac_sha512(Uint8List(0), entropy, 4096, 96);
//   return Bip32SigningKey.normalizeBytes(rawMaster);
// }

/// The default implementation of the original BIP32-ED25519's master key
/// generation.
// Bip32Key originalMaster(Uint8List masterSecret) {
//   final secretBytes = Hash.sha512(masterSecret);

//   if ((secretBytes[31] &= 0x20) != 0) {
//     //0b0010_0000
//     throw InvalidBip32Ed25519MasterSecretException();
//   }

//   final rootChainCode = Hash.sha256([0x01, ...masterSecret].toUint8List());

//   final rootKey = Bip32SigningKey.normalizeBytes(
//       [...secretBytes, ...rootChainCode].toUint8List());

//   PineNaClUtils.listZero(masterSecret);
//   PineNaClUtils.listZero(rootChainCode);

//   return rootKey;
// }

// function hashRepeatedly(key, i) {
//     (iL, iR) = HMAC
//         ( hash=SHA512
//         , key=key
//         , message="Root Seed Chain " + UTF8NFKD(i)
//         );

//     let prv = tweakBits(SHA512(iL));

//     if (prv[31] & 0b0010_0000) {
//         return hashRepeatedly(key, i+1);
//     }

//     return (prv + iR);
// }

// Uint8List byronTweakBits(Uint8List bytes, {int keyLength = 96}) {
//   if (bytes.length != keyLength) {
//     throw InvalidSigningKeyError();
//   }
//   var result = bytes.toUint8List();
//   result[0] &= 0xF8; // clear the last 3 bits, result[0] &= 0b1111_1000;
//   result[31] &= 0x7F; // clear the 1st bit, result[31] &= 0b0111_1111;
//   result[31] |= 0x40; // set the 2nd bit, result[31] |= 0b0100_0000;
//   return result;
// }

// Uint8List clampKey(Uint8List bytes, {int keyLength = 96}) {
//   Uint8List result = byronTweakBits(bytes, keyLength: keyLength);
//   result[31] &= 0xDF; // clear the 3rd bit, result[31] &= 0b1101_1111;
//   return result;
// }

// Uint8List validateKeyBits(Uint8List bytes) {
//   bytes = ExtendedSigningKey.validateKeyBits(bytes);

//   if ((bytes[31] & 32) != 0) {
//     throw InvalidSigningKeyError();
//   }
//   return bytes;
// }
