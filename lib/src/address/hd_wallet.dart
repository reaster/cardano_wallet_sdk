/// import 'package:built_value/built_value.dart';
/// import 'package:built_value/serializer.dart';
import 'dart:typed_data';
// import 'package:built_collection/built_collection.dart';
import 'package:bip32_ed25519/bip32_ed25519.dart';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
// import 'package:cardano_wallet_sdk/src/bip32_ed25519/api.dart';
// import 'package:cardano_wallet_sdk/src/util/blake2bhash.dart';
import 'package:hex/hex.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:pinenacl/key_derivation.dart';
//part 'addresses.g.dart';

///
/// BIP-0044 Multi-Account Hierarchy for Deterministic Wallets is a Bitcoin standard defining a structure
/// and algorithm to build a hierarchy tree of keys from a single root private key. Note that this is the
/// derivation scheme used by Icarus / Yoroi.
///
/// It is built upon BIP-0032 and is a direct application of BIP-0043. It defines a common representation
/// of addresses as a multi-level tree of derivations:
///
///    m / purpose' / coin_type' / account_ix' / change_chain / address_ix
///
/// Where m is the private key, purpose is 1852 for Cardano, coin_type is 1815 for ADA, account_ix is a zero-
/// based index defaulting to 0, change_chain is generaly 1 for change, address_ix is a zero-based index
/// defaulting to 0.
/// see https://docs.cardano.org/projects/cardano-wallet/en/latest/About-Address-Derivation.html
///
class HdWallet {
  final Uint8List seed;
  final Bip32SigningKey rootSigningKey;
  final _derivator = Bip32Ed25519KeyDerivation.instance;

  HdWallet({required this.seed}) : rootSigningKey = _bip32signingKey(seed);

  factory HdWallet.fromHexEntropy(String hexEntropy) => HdWallet(seed: Uint8List.fromList(HEX.decode(hexEntropy)));

  factory HdWallet.fromMnemonic(String mnemonic) => HdWallet.fromHexEntropy(bip39.mnemonicToEntropy(mnemonic));

  Bip32VerifyKey get rootVerifyKey => rootSigningKey.verifyKey;

  static Bip32SigningKey _bip32signingKey(Uint8List seed) {
    final rawMaster = PBKDF2.hmac_sha512(Uint8List(0), seed, 4096, xprv_size);
    final Bip32SigningKey root_xsk = Bip32SigningKey.normalizeBytes(rawMaster);
    return root_xsk;
  }

  ///
  /// BIP-44 path: m / purpose' / coin_type' / account_ix' / change_chain / address_ix
  ///
  /// Cardano adoption: m / 1852' / 1851' / 0' / change_chain / address_ix
  ///
  ///
  /// +--------------------------------------------------------------------------------+
  /// |                BIP-39 Encoded Seed with CRC a.k.a Mnemonic Words               |
  /// |                                                                                |
  /// |    squirrel material silly twice direct ... razor become junk kingdom flee     |
  /// |                                                                                |
  /// +--------------------------------------------------------------------------------+
  ///        |
  ///        |
  ///        v
  /// +--------------------------+    +-----------------------+
  /// |    Wallet Private Key    |--->|   Wallet Public Key   |
  /// +--------------------------+    +-----------------------+
  ///        |
  ///        | purpose (e.g. 1852')
  ///        |
  ///        v
  /// +--------------------------+
  /// |   Purpose Private Key    |
  /// +--------------------------+
  ///        |
  ///        | coin type (e.g. 1815' for ADA)
  ///        v
  /// +--------------------------+
  /// |  Coin Type Private Key   |
  /// +--------------------------+
  ///        |
  ///        | account ix (e.g. 0')
  ///        v
  /// +--------------------------+    +-----------------------+
  /// |   Account Private Key    |--->|   Account Public Key  |
  /// +--------------------------+    +-----------------------+
  ///        |                                          |
  ///        | chain  (e.g. 0=external/payments,        |
  ///        |         1=internal/change, 2=staking)    |
  ///        v                                          v
  /// +--------------------------+    +-----------------------+
  /// |   Change Private Key     |--->|   Change Public Key   |
  /// +--------------------------+    +-----------------------+
  ///        |                                          |
  ///        | address ix (e.g. 0)                      |
  ///        v                                          v
  /// +--------------------------+    +-----------------------+
  /// |   Address Private Key    |--->|   Address Public Key  |
  /// +--------------------------+    +-----------------------+
  ///
  ///              BIP-44 Wallets Key Hierarchy
  ///
  Bip32KeyPair derive({required Bip32KeyPair keys, required int index}) {
    // computes a child extended private key from the parent extended private key.
    Bip32PrivateKey? privateKey = keys.privateKey != null ? _derivator.ckdPriv(keys.privateKey!, index) : null;
    Bip32PublicKey? publicKey = isHardened(index)
        ? null
        : keys.publicKey != null
            ? _derivator.ckdPub(keys.publicKey!, index)
            : _derivator.neuterPriv(privateKey!);
    return Bip32KeyPair(privateKey: privateKey, publicKey: publicKey);
  }

  Bip32KeyPair deriveAddress(
      {int purpose = defaultPurpose,
      int coinType = defaultCoinType,
      int account = defaultAccountIndex,
      int change = defaultChange,
      int address = defaultAddressIndex}) {
    final rootKeys = Bip32KeyPair(privateKey: rootSigningKey, publicKey: rootVerifyKey);
    final pair0 = derive(keys: rootKeys, index: purpose);
    final pair1 = derive(keys: pair0, index: coinType);
    final pair2 = derive(keys: pair1, index: account);
    final pair3 = derive(keys: pair2, index: change);
    final pair4 = derive(keys: pair3, index: address);
    return pair4;
  }

  ShelleyAddress toBaseAddress({required Bip32PublicKey spend, required Bip32PublicKey stake, NetworkId networkId = NetworkId.testnet}) =>
      ShelleyAddress.toBaseAddress(spend: spend, stake: stake, networkId: networkId);

  ShelleyAddress toRewardAddress({required Bip32PublicKey spend, NetworkId networkId = NetworkId.testnet}) =>
      ShelleyAddress.toRewardAddress(spend: spend, networkId: networkId);
}

class Bip32KeyPair {
  final Bip32PrivateKey? privateKey;
  final Bip32PublicKey? publicKey;
  const Bip32KeyPair({this.privateKey, this.publicKey});
}

///
const int hardened_offset = 0x80000000; //denoted by a single quote in chain values

/// default purpose. Reference: [CIP-1852](https://github.com/cardano-foundation/CIPs/blob/master/CIP-1852/CIP-1852.md)
const int defaultPurpose = 1852 | hardened_offset;
const int defaultCoinType = 1815 | hardened_offset;
const int defaultAccountIndex = 0 | hardened_offset;

/// 0=external/payments, 1=internal/change, 2=staking
const int defaultChange = 0;
const int defaultAddressIndex = 0;

/// Extended Private key size in bytes
const xprv_size = 96;
const extended_secret_key_size = 64;

int harden(int index) => index | hardened_offset;
bool isHardened(int index) => index & hardened_offset != 0;
