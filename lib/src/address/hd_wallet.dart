import 'dart:typed_data';
import 'package:hex/hex.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:pinenacl/key_derivation.dart';
import 'package:bip32_ed25519/bip32_ed25519.dart';
import 'package:cardano_wallet_sdk/src/address/shelley_address.dart';
import 'package:cardano_wallet_sdk/src/network/cardano_network.dart';

///
/// This class generates cryptographic key pairs and addresses given a secret set of nmemonic BIP-39 words.
/// It generates Cardano Shelley addresses by default, but can be used to generate and/or restore any wallet
/// based on the BIP32-ED25519 standard.
///
/// This code builes on following standards:
///
/// https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki - HD wallets
/// https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki - mnemonic words
/// https://github.com/bitcoin/bips/blob/master/bip-0043.mediawiki - Bitcoin purpose
/// https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki - multi-acct wallets
/// https://cips.cardano.org/cips/cip3/       - key generation
/// https://cips.cardano.org/cips/cip5/       - Bech32 prefixes
/// https://cips.cardano.org/cips/cip11/      - staking key
/// https://cips.cardano.org/cips/cip16/      - key serialisation
/// https://cips.cardano.org/cips/cip19/      - address structure
/// https://cips.cardano.org/cips/cip1852/    - 1852 purpose field
/// https://cips.cardano.org/cips/cip1855/    - forging keys
/// https://raw.githubusercontent.com/input-output-hk/adrestia/master/user-guide/static/Ed25519_BIP.pdf
///
///
/// BIP-44 path:
///     m / purpose' / coin_type' / account_ix' / change_chain / address_ix
///
/// Cardano adoption:
///     m / 1852' / 1851' / account' / role / index
///
///
///  BIP-44 Wallets Key Hierarchy - Cardano derivation:
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
///        | role   (e.g. 0=external/payments,        |
///        |         1=internal/change, 2=staking)    |
///        v                                          v
/// +--------------------------+    +-----------------------+
/// |   Change Private Key     |--->|   Change Public Key   |
/// +--------------------------+    +-----------------------+
///        |                                          |
///        | index (e.g. 0)                           |
///        v                                          v
/// +--------------------------+    +-----------------------+
/// |   Address Private Key    |--->|   Address Public Key  |
/// +--------------------------+    +-----------------------+
///
///
class HdWallet {
  final Uint8List seed;
  final Bip32SigningKey rootSigningKey;
  final _derivator = Bip32Ed25519KeyDerivation.instance;

  HdWallet({required this.seed}) : rootSigningKey = _bip32signingKey(seed);

  factory HdWallet.fromHexEntropy(String hexEntropy) =>
      HdWallet(seed: Uint8List.fromList(HEX.decode(hexEntropy)));

  factory HdWallet.fromMnemonic(String mnemonic) =>
      HdWallet.fromHexEntropy(bip39.mnemonicToEntropy(mnemonic));

  Bip32VerifyKey get rootVerifyKey => rootSigningKey.verifyKey;

  static Bip32SigningKey _bip32signingKey(Uint8List seed) {
    final rawMaster = PBKDF2.hmac_sha512(
        Uint8List(0), seed, 4096, cip16ExtendedSigningKeySize);
    final Bip32SigningKey root_xsk = Bip32SigningKey.normalizeBytes(rawMaster);
    return root_xsk;
  }

  Bip32KeyPair derive({required Bip32KeyPair keys, required int index}) {
    // computes a child extended private key from the parent extended private key.
    Bip32PrivateKey? privateKey = keys.privateKey != null
        ? _derivator.ckdPriv(keys.privateKey!, index)
        : null;
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
      int role = paymentRole,
      int index = defaultAddressIndex}) {
    final rootKeys =
        Bip32KeyPair(privateKey: rootSigningKey, publicKey: rootVerifyKey);
    final pair0 = derive(keys: rootKeys, index: purpose);
    final pair1 = derive(keys: pair0, index: coinType);
    final pair2 = derive(keys: pair1, index: account);
    final pair3 = derive(keys: pair2, index: role);
    final pair4 = derive(keys: pair3, index: index);
    return pair4;
  }

  ShelleyAddress toBaseAddress(
          {required Bip32PublicKey spend,
          required Bip32PublicKey stake,
          NetworkId networkId = NetworkId.testnet}) =>
      ShelleyAddress.toBaseAddress(
          spend: spend, stake: stake, networkId: networkId);

  ShelleyAddress toRewardAddress(
          {required Bip32PublicKey spend,
          NetworkId networkId = NetworkId.testnet}) =>
      ShelleyAddress.toRewardAddress(spend: spend, networkId: networkId);
}

class Bip32KeyPair {
  final Bip32PrivateKey? privateKey;
  final Bip32PublicKey? publicKey;
  const Bip32KeyPair({this.privateKey, this.publicKey});
}

/// Hardended chain values should not have public keys.
/// They are denoted by a single quote in chain values.
const int hardenedOffset = 0x80000000;

/// default purpose. Reference: [CIP-1852](https://github.com/cardano-foundation/CIPs/blob/master/CIP-1852/CIP-1852.md)
const int defaultPurpose = 1852 | hardenedOffset;
const int defaultCoinType = 1815 | hardenedOffset;
const int defaultAccountIndex = 0 | hardenedOffset;

/// role 0=external/payments
const int paymentRole = 0;

/// role 1=internal/change
const int changeRole = 1;

/// role 2=staking
const int stakingRole = 2;
const int defaultAddressIndex = 0;

/// Extended private key size in bytes
const cip16ExtendedSigningKeySize = 96;

/// Extended public key size in bytes
const cip16ExtendedVerificationgKeySize = 64;

int harden(int index) => index | hardenedOffset;
bool isHardened(int index) => index & hardenedOffset != 0;
