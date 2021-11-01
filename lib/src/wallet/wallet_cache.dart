// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0
import 'package:cardano_wallet_sdk/src/transaction/coin_selection.dart';
import 'package:cardano_wallet_sdk/src/wallet/read_only_wallet.dart';
import 'package:cardano_wallet_sdk/src/util/ada_types.dart';

///
/// Wallet cache interface.
///
abstract class WalletCache {
  ///lookup cached wallet by ID
  ReadOnlyWallet? cachedWalletById(WalletId walletId);

  ///cache wallet.
  void cacheWallet(ReadOnlyWallet wallet);

  ///clear cache
  int clearCachedWallets();
}
