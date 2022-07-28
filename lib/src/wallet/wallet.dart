// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

// import 'package:bip32_ed25519/bip32_ed25519.dart';
// import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:oxidized/oxidized.dart';
// import '../address/hd_wallet.dart';
import '../address/shelley_address.dart';
// import '../transaction/spec/shelley_spec.dart';
import '../transaction/model/bc_tx.dart';
import '../util/ada_types.dart';
import './read_only_wallet.dart';
import '../hd/hd_account.dart';

///
/// Extend ReadOnlyWallet with signing and transactional capabilities. Signing (private),
/// key, verify (public) key and address generation is handled by the HdWallet instance.
///
/// This is currently a prototype wallet and only supports sending simple ADA transactions.
///
abstract class Wallet extends ReadOnlyWallet {
  /// Hierarchical deterministic wallet
  HdAccount get account;

  // /// Account index of wallet, defaults to 0.
  // int get accountIndex;

  // /// Root private and public key
  // Bip32KeyPair get rootKeyPair;

  // /// Base address key pair used for signing transactions
  // Bip32KeyPair get addressKeyPair;

  /// Returns first unused receive address, used by others to send money to this account.
  ShelleyReceiveKit get firstUnusedReceiveAddress;

  /// Returns first unused change address, used to return unspent change to this wallet.
  ShelleyReceiveKit get firstUnusedChangeAddress;

  /// Find signing key for spend or change address.
  Map<ShelleyAddress, ShelleyUtxoKit> findSigningKeyForUtxos(
      {required Set<ShelleyAddress> utxos});

  /// Send ADA to another address.
  Future<Result<BcTransaction, String>> sendAda({
    required AbstractAddress toAddress,
    required Coin lovelace,
    int ttl = 0,
    int fee = 0,
    bool logTxHex = false,
    bool logTx = false,
  });

  /// Send a transaction.
  Future<Result<BcTransaction, String>> submitTransaction({
    required BcTransaction tx,
  });

  /// Build a simple spend transaction.
  Future<Result<BcTransaction, String>> buildSpendTransaction({
    required ShelleyAddress toAddress,
    required int lovelace,
    int ttl = 0,
    int fee = 0,
  });
}
