import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_example/src/wallet/wallet_service.dart';
import 'package:flutter_example/src/widgets/alert_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// WalletStateNotifier notifies UI widgets when the list of Wallet changes.
class WalletStateNotifier extends StateNotifier<List<ReadOnlyWallet>> {
  final WalletService walletService;

  WalletStateNotifier(this.walletService) : super(walletService.wallets);

  /// Create new Wallet and add to list.
  void createNewWallet({required BuildContext context, required String walletName, required List<String> mnemonic}) {
    final result = walletService.createNewWallet(walletName, mnemonic);
    result.when(
      ok: (wallet) {
        debugPrint('created new wallet: $walletName');
        state = walletService.wallets;
      },
      err: (message) => asyncAlertDialog(context, 'Error Creating New Wallet', message),
    );
  }

  /// Create new ReadOnlyWallet and add to list.
  void createReadOnlyWallet({required BuildContext context, required String walletName, required ShelleyAddress stakeAddress}) async {
    final result = await walletService.createReadOnlyWallet(walletName, stakeAddress);
    result.when(
      ok: (wallet) {
        debugPrint('created read-only wallet: $walletName');
        state = walletService.wallets;
      },
      err: (message) => asyncAlertDialog(context, 'Error Creating Read-only Wallet', message),
    );
  }

  /// Create new Wallet and add to list.
  void restoreWallet({required BuildContext context, required String walletName, required List<String> mnemonic}) async {
    final result = await walletService.restoreWallet(walletName, mnemonic);
    result.when(
      ok: (wallet) {
        debugPrint('restored wallet: $walletName');
        state = walletService.wallets;
      },
      err: (message) => asyncAlertDialog(context, 'Error Restoring Wallet', message),
    );
  }

  /// Return stored list of ReadOnlyWallets.
  List<ReadOnlyWallet> get items => walletService.wallets;

  /// Remove SampleItem from store, returning removed instance if found.
  // void removeItemById(String id) {
  //   final result = walletService.deleteWallet(walletId: id);
  //   if (walletService.removeItemById(id) != null) {
  //     debugPrint("item removed: $id");
  //     state = walletService.items;
  //   }
  // }
}
