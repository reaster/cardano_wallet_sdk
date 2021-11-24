// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/src/wallet/read_only_wallet.dart';
import 'package:cardano_wallet_sdk/src/util/ada_types.dart';

///
/// Wallet cache interface.
///
abstract class WalletCache<T> {
  ///lookup cached wallet by ID
  WalletValue<T>? cachedWalletById(WalletId walletId);

  ///cache wallet.
  void cacheWallet(WalletValue<T> walletValue);

  ///clear cache
  int clearCachedWallets();
}

class WalletValue<T> {
  final ReadOnlyWallet wallet;
  final T metadata;
  WalletValue({required this.wallet, required this.metadata});
}
