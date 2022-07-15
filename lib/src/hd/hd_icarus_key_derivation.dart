// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

// import 'package:pinenacl/key_derivation.dart';
import 'package:bip32_ed25519/api.dart';
import 'package:hex/hex.dart';
import '../util/codec.dart';
import 'hd_master_key_generation.dart';

// Bip32SigningKey icarusGenerateMasterKey(Uint8List entropy) {
//   final rawMaster = PBKDF2.hmac_sha512(Uint8List(0), entropy, 4096, 96);
//   return Bip32SigningKey.normalizeBytes(rawMaster);
// }

class IcarusKeyDerivation extends Bip32Ed25519KeyDerivation with Bip32KeyTree {
  IcarusKeyDerivation(Bip32Key key) {
    assert(key is Bip32SigningKey || key is Bip32VerifyKey);
    root = key;
  }
  IcarusKeyDerivation.entropy(Uint8List entropy) {
    root = master(entropy);
  }
  IcarusKeyDerivation.entropyHex(String entropyHex) {
    root = master(Uint8List.fromList(HEX.decode(entropyHex)));
  }
  IcarusKeyDerivation.bech32Key(String key) {
    root = doImport(key);
  }

  /// Use Icarus master key generation algo as used by Yoroi, Daedalus (Shelley era)
  /// https://github.com/cardano-foundation/CIPs/blob/master/CIP-0003/Icarus.md
  @override
  Bip32Key master(Uint8List seed) => icarusGenerateMasterKey(seed);

  /// Modify to support Cardano bech32 prefixes that make sense.
  /// https://cips.cardano.org/cips/cip5/
  @override
  Bip32Key doImport(String key) {
    final prefixSep = key.indexOf('1');
    if (prefixSep == -1 || prefixSep > 8) {
      throw ArgumentError(
          "expecting bech32 encoding with '1' as prefix seperator", key);
    }
    final prefix = key.substring(0, prefixSep);
    switch (prefix) {
      case 'root_xsk':
        return Bip32SigningKey.decode(key, coder: rootXskCoder);
      case 'acct_xsk':
        return Bip32SigningKey.decode(key, coder: acctXskCoder);
      case 'acct_xvk':
        return Bip32VerifyKey.decode(key, coder: acctXvkCoder);
      default:
        throw ArgumentError(
            "unsupported bech32 prefix: $prefix, expecting 'root_xsk', 'acct_xsk' or 'acct_xvk'",
            key);
    }
  }
}
