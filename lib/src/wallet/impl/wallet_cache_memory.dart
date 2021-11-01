// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0
import 'package:cardano_wallet_sdk/src/transaction/coin_selection.dart';
import 'package:cardano_wallet_sdk/src/wallet/read_only_wallet.dart';
import 'package:cardano_wallet_sdk/src/util/ada_types.dart';
import 'package:cardano_wallet_sdk/src/wallet/wallet_cache.dart';

///
/// Wallet cache interface.
///
abstract class WalletCacheMemory implements WalletCache {
  final Map<String, ReadOnlyWallet> _cache = {};

  ///lookup cached wallet by ID
  ReadOnlyWallet? cachedWalletById(WalletId walletId) => _cache[walletId];

  ///cache wallet.
  void cacheWallet(ReadOnlyWallet wallet) => _cache[wallet.walletId] = wallet;

  ///clear cache, returning number of wallets removed.
  int clearCachedWallets() {
    final length = _cache.length;
    _cache.clear();
    return length;
  }
}
