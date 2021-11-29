import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:oxidized/oxidized.dart';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:flutter_example/src/wallet/wallet_service.dart';

// class Refresh {
//   /// Return true of all wallets have been updated (i.e. turn off Busy Widget)
//   final bool finished;

//   /// Human readable status of update.
//   final String message;

//   Refresh({required this.finished, required this.message});
// }

// typedef RefreshWalletCallback = void Function(Result<Refresh, String> update);

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
  Future<void> reloadAll() async {
    for (final wallet in walletService.wallets) {
      await wallet.update();
      state = walletService
          .wallets; //always reset state to trigger both data and spinner updates.
    }
  }

  // Future<void> reloadAll(RefreshWalletCallback? callback) async {
  //   for (final wallet in walletService.wallets) {
  //     if (_reloadStatus.containsKey(wallet.walletId)) continue; // skip b/c already updating
  //     _reloadStatus[wallet.walletId] = true;
  //     final result = await wallet.update();
  //     _reloadStatus.remove(wallet.walletId);
  //     if (result.isOk() && result.unwrap()) {
  //       state = walletService.wallets;
  //     }
  //     if (callback != null) {
  //       final refreshResult = result.isOk()
  //           ? Ok(Refresh(finished: _reloadStatus.isEmpty, message: "${wallet.walletName} ${result.unwrap() ? ' updated' : ' is current'}"))
  //           : Err(result.unwrapErr());
  //       callback(refreshResult);
  //     }
  //   }
  // }

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
    required BuildContext context,
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
