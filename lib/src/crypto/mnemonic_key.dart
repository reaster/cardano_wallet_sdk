// import 'package:pinenacl/digests.dart';
// import 'package:pinenacl/tweetnacl.dart';
// import 'mnemonic.dart';
// import 'package:bip32_ed25519/api.dart';
// import 'package:pinenacl/key_derivation.dart';
// import 'package:hex/hex.dart';

///
/// Extends bip39 mnemonics to generate
///

/// return master signing key given seed byte array
// Bip32SigningKey seedToMasterKey(Uint8List seedBytes) {
//   //final key = ExtendedSigningKey.fromSeed(seedBytes);
//   final rawMaster = PBKDF2.hmac_sha512(Uint8List(0), seedBytes, 4096, 96);
//   return Bip32SigningKey.normalizeBytes(rawMaster);
// }

/// return master signing key given a entropy hex string
// Bip32SigningKey seedHexToMasterKey(String seedHex) =>
//     seedToMasterKey(Uint8List.fromList(HEX.decode(seedHex)));

/// return signing key given a mnemonic
// Bip32SigningKey mnemonicToMasterKey(List<String> mnemonic,
//         {String passphrase = ''}) =>
//     seedToMasterKey(mnemonicToSeed(mnemonic, passphrase: passphrase));

// /// return master signing key given a entropy byte array
// Bip32SigningKey entropyToMasterKey(Uint8List entropy) =>
//     mnemonicToMasterKey(entropyBytesToMnemonic(entropy));

// /// return master signing key given a hex encoded entropy
// Bip32SigningKey entropyHexToMasterKey(String entropyHex) => mnemonicToMasterKey(
//     entropyBytesToMnemonic(Uint8List.fromList(HEX.decode(entropyHex))));

// Uint8List _seedToSecret(Uint8List seed) {
//   const seedSize = 32;
//   const int publicKeyLength = 32;
//   if (seed.length != seedSize) {
//     throw Exception('SigningKey must be created from a $seedSize byte seed');
//   }
//   final priv = Uint8List.fromList(seed + Uint8List(publicKeyLength));
//   final pub = Uint8List(publicKeyLength);
//   TweetNaCl.crypto_sign_keypair(pub, priv, Uint8List.fromList(seed));
//   return SigningKey.fromValidBytes(priv).asTypedList;
// }
