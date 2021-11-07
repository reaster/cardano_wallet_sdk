// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/src/address/hd_wallet.dart';
import 'package:cardano_wallet_sdk/src/address/shelley_address.dart';
import 'package:cardano_wallet_sdk/src/transaction/spec/shelley_spec.dart';
import 'package:cardano_wallet_sdk/src/wallet/read_only_wallet.dart';
import 'package:oxidized/oxidized.dart';
import 'package:cardano_wallet_sdk/src/util/ada_types.dart';

///
/// Extend ReadOnlyWallet with signing and transactional capabilities. Signing (private),
/// key, verify (public) key and address generation is handled by the HdWallet instance.
///
/// This is currently a prototype wallet and only supports sending simple ADA transactions.
///
abstract class Wallet extends ReadOnlyWallet {
  /// hierarchical deterministic wallet
  HdWallet get hdWallet;

  /// account index of wallet, defaults to 0.
  int get accountIndex;

  /// root private and public key
  Bip32KeyPair get rootKeyPair;

  /// base address key pair used for signing transactions
  Bip32KeyPair get addressKeyPair;

  /// returns first unused receive address, used by others to send money to this account.
  ShelleyAddress get firstUnusedReceiveAddress;

  /// returns first unused change address, used to return unspent change to this wallet.
  ShelleyAddress get firstUnusedChangeAddress;

  /// send ADA to another address.
  Future<Result<ShelleyTransaction, String>> sendAda({
    required ShelleyAddress toAddress,
    required Coin lovelace,
    int ttl = 0,
    int fee = 0,
  });
}
