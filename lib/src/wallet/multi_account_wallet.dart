// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

// ignore_for_file: non_constant_identifier_names

import 'package:bip32_ed25519/api.dart';

// import '../address/hd_wallet.dart';
// import '../address/hd_wallet.dart';
import '../crypto/mnemonic.dart';
import '../crypto/mnemonic_english.dart';
import '../crypto/shelley_key_derivation.dart';
import '../network/network_id.dart';
import 'account.dart';
import 'derivation_chain.dart';

///
/// A MultiAccountWallet generates accounts based on a unique master secret key.
/// The master key can be supplied in servel formats including a mnemonic phrase,
/// a hex seed, bech32 encoding or raw bytes. A wallet instance can run on
/// the mainnet (default) or testnet network, but not both. Each account is assigned a
/// private key by the wallet, which generates signing keys, validation keys
/// and addresses used to hold and send cryptographic assets. Wallet instances are
/// cached and can be accessed using their BIP32 path.
///
/// Usage - 99% of the time you'll just create a wallet using a mnemonic and get the
/// default account:
///
///   MultiAccountWallet wallet = MultiAccountWallet.mnemonic(['head', 'guard',...]);
///   Account account = wallet.account();
///
class MultiAccountWallet {
  final ShelleyKeyDerivation derivation;
  final NetworkId network;
  final Map<String, Account> _accounts = {};

  MultiAccountWallet({required Bip32Key key, this.network = NetworkId.mainnet})
      : derivation = ShelleyKeyDerivation(key);

  MultiAccountWallet.entropy(Uint8List entropy,
      {this.network = NetworkId.mainnet})
      : derivation = ShelleyKeyDerivation.entropy(entropy);

  MultiAccountWallet.entropyHex(String entropyHex,
      {this.network = NetworkId.mainnet})
      : derivation = ShelleyKeyDerivation.entropyHex(entropyHex);

  MultiAccountWallet.bech32(String root_sk, {this.network = NetworkId.mainnet})
      : derivation = ShelleyKeyDerivation.rootX(root_sk);

  factory MultiAccountWallet.mnemonic(
    ValidMnemonicPhrase mnemonic, {
    LoadMnemonicWordsFunction loadWordsFunction = loadEnglishMnemonicWords,
    MnemonicLang lang = MnemonicLang.english,
    NetworkId network = NetworkId.mainnet,
  }) =>
      MultiAccountWallet.entropyHex(
          mnemonicToEntropyHex(
              mnemonic: mnemonic,
              loadWordsFunction: loadWordsFunction,
              lang: lang),
          network: network);

  /// Lookup and/or create an account if one doesn't exist.
  /// The default zero index will be used if not specified.
  /// Paths are generated using the "m/1852'/1815'/$index'" template.
  Account account({int accountIndex = 0}) {
    final path =
        accountIndex == 0 ? _defaultAcctPath : _acctPathTemplate(accountIndex);
    return accountByPath(path, autoCreate: true)!;
  }

  /// Look up an account based on it's path. Paths define the cryptocraphic key of the account
  /// from which all other account keys and addresses are derived.
  Account? accountByPath(String path, {bool autoCreate = true}) {
    Account? result = _accounts[path];
    if (result == null && autoCreate) {
      final derivationPath = DerivationChain.fromPath(path);
      final accountKey =
          derivation.fromChain(derivationPath) as Bip32SigningKey;
      result = Account(
          accountSigningKey: accountKey,
          accountIndex: derivationPath.segments.last.index,
          network: network);
      _accounts[path] = result;
    }
    return result;
  }

  static const _defaultAcctPath = "m/1852'/1815'/0'";
  String _acctPathTemplate(int accountIndex) => "m/1852'/1815'/$accountIndex'";
}
