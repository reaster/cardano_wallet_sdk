// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:collection/collection.dart';
import 'package:oxidized/oxidized.dart';
import '../settings/settings_service.dart';

///
/// Wallet service loads stores wallets in memory along with a name property in
/// the it's metadata.
///
class WalletService {
  static const NetworkId testnet = NetworkId.testnet;
  final store = WalletCacheMemory<WalletMetadata>();
  final SettingsService settingService;

  /// BlockchainAdapter caches invarient blockchain data, so we want a singleton.
  final BlockchainAdapter blockchainAdapter;

  WalletService({required this.settingService})
      : blockchainAdapter = BlockchainAdapterFactory.fromKey(
                key: settingService.adapterKey, networkId: testnet)
            .adapter();

  List<ReadOnlyWallet> get wallets =>
      store.cache.values.map((v) => v.wallet).toList();

  Result<ReadOnlyWallet, String> deleteWallet({required String walletId}) {
    final value = store.cachedWalletById(walletId);
    if (value == null) {
      return Err("wallet not found for ID: $walletId");
    } else {
      store.cache.remove(walletId);
      return Ok(value.wallet);
    }
  }

  /// Create a read-only wallet.
  Future<Result<ReadOnlyWallet, String>> createReadOnlyWallet(
      String walletName, ShelleyAddress stakeAddress) async {
    final builder = WalletBuilder()
      ..blockchainAdapter = blockchainAdapter
      ..walletName = walletName
      ..stakeAddress = stakeAddress;
    final result = await builder.readOnlyBuildAndSync();
    if (result.isOk()) {
      //cache wallet instance:
      store.cacheWallet(WalletValue(
          wallet: result.unwrap(),
          metadata: WalletMetadata(created: DateTime.now())));
    }
    return result;
  }

  /// Restore wallet.
  Future<Result<Wallet, String>> restoreWallet(
      String walletName, List<String> mnemonic) async {
    final builder = WalletBuilder()
      ..blockchainAdapter = blockchainAdapter
      ..walletName = walletName
      ..mnemonic = mnemonic;
    final result = await builder.buildAndSync();
    if (result.isOk()) {
      //cache wallet instance:
      store.cacheWallet(WalletValue(
          wallet: result.unwrap(),
          metadata: WalletMetadata(created: DateTime.now())));
    }
    return result;
  }

  /// Create new wallet.
  Result<Wallet, String> createNewWallet(
      String walletName, List<String> mnemonic) {
    final builder = WalletBuilder()
      ..blockchainAdapter = blockchainAdapter
      ..walletName = walletName
      ..mnemonic = mnemonic;
    final result = builder.build();
    if (result.isOk()) {
      //cache wallet instance:
      store.cacheWallet(WalletValue(
          wallet: result.unwrap(),
          metadata: WalletMetadata(created: DateTime.now())));
    }
    return result;
  }

  /// Lookup a wallet by walletId.
  ReadOnlyWallet? findByWalletId(String walletId) =>
      wallets.firstWhereOrNull((wallet) => wallet.walletId == walletId);

  /// Check if a wallet name has not been used yet.
  bool isWalletNameAvailable(String walletName) =>
      !wallets.any((wallet) => wallet.walletName == walletName);

  /// Lookup a wallet by name.
  ReadOnlyWallet? findByName(String walletName) =>
      wallets.firstWhereOrNull((wallet) => wallet.walletName == walletName);

  /// Collect list of wallet names.
  List<String> get walletNames =>
      wallets.map((wallet) => wallet.walletName).toList();
}

/// Metadata stored along with wallet.
class WalletMetadata {
  final DateTime created;
  WalletMetadata({required this.created});
}
