// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:oxidized/oxidized.dart';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import './wallet_service.dart';

///
/// WalletStateNotifier notifies UI widgets when the list of Wallet changes.
///
class WalletStateNotifier extends StateNotifier<List<ReadOnlyWallet>> {
  final WalletService walletService;

  WalletStateNotifier(this.walletService) : super(walletService.wallets);

  /// Return stored list of ReadOnlyWallets.
  List<ReadOnlyWallet> get items => walletService.wallets;

  /// Create new Wallet and add to list.
  Result<Wallet, String> createNewWallet(
      {required BuildContext context,
      required String walletName,
      required List<String> mnemonic}) {
    final result = walletService.createNewWallet(walletName, mnemonic);
    if (result.isOk()) {
      state = walletService.wallets;
    }
    return result;
  }

  // Map<String, bool> _reloadStatus = {};

  /// Refresh all wallets
  Future<Result<bool, String>> reloadAll() async {
    bool updated = false;
    for (final wallet in walletService.wallets) {
      final result = await wallet.update();
      if (result.isErr()) {
        state = walletService.wallets; //trigger view refresh to stop spinners
        return Err(result.unwrapErr());
      } else if (result.unwrap()) {
        updated = true;
      }
    }
    state = walletService.wallets;
    return Ok(updated);
  }

  /// Create new ReadOnlyWallet and add to list.
  Future<Result<ReadOnlyWallet, String>> createReadOnlyWallet(
      {required BuildContext context,
      required String walletName,
      required ShelleyAddress stakeAddress}) async {
    final result =
        await walletService.createReadOnlyWallet(walletName, stakeAddress);
    if (result.isOk()) {
      state = walletService.wallets;
    }
    return result;
  }

  /// Create new Wallet and add to list.
  Future<Result<Wallet, String>> restoreWallet(
      {required BuildContext context,
      required String walletName,
      required List<String> mnemonic}) async {
    final result = await walletService.restoreWallet(walletName, mnemonic);
    if (result.isOk()) {
      state = walletService.wallets;
    }
    return result;
  }

  Future<Result<ShelleyTransaction, String>> sendAda({
    required Wallet wallet,
    required ShelleyAddress toAddress,
    required int lovelace,
  }) async {
    final result = await wallet.sendAda(
        toAddress: toAddress, lovelace: lovelace, logTx: true, logTxHex: true);
    if (result.isOk()) {
      state = walletService.wallets;
    }
    return result;
  }

  /// Remove Wallet from list.
  Result<ReadOnlyWallet, String> deleteWallet(
      {required BuildContext context, required ReadOnlyWallet wallet}) {
    final result = walletService.deleteWallet(walletId: wallet.walletId);
    if (result.isOk()) {
      state = walletService.wallets;
    }
    return result;
  }

  ReadOnlyWallet? findByWalletId(String walletId) =>
      walletService.findByWalletId(walletId);
}
