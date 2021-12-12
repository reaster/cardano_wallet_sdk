// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import '../../util/ada_types.dart';
import '../wallet_cache.dart';

///
/// Implements an in-memory version of WalletCache.
///
class WalletCacheMemory<T> implements WalletCache<T> {
  final Map<String, WalletValue<T>> _cache = {};

  ///lookup cached WalletValue by ID
  @override
  WalletValue<T>? cachedWalletById(WalletId walletId) => _cache[walletId];

  ///cache WalletValue.
  @override
  void cacheWallet(WalletValue<T> walletValue) =>
      _cache[walletValue.wallet.walletId] = walletValue;

  ///clear cache, returning number of wallets removed.
  @override
  int clearCachedWallets() {
    final length = _cache.length;
    _cache.clear();
    return length;
  }

  Map<String, WalletValue<T>> get cache => _cache;
}
