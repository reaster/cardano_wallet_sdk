// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import '../widgets/alert_dialog.dart';
import '../settings/settings_view.dart';
import '../widgets/send_funds_form.dart';
import '../widgets/ada_shape_maker.dart';
import '../widgets/create_or_restore_wallet_form.dart';
import '../widgets/create_read_only_wallet_form.dart';
import '../providers.dart';
import './wallet_details_view.dart';

///
/// Displays a list of wallets.
///
class WalletListView extends StatelessWidget {
  const WalletListView({Key? key}) : super(key: key);

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Flutter SDK'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => synchWalletsWithBlockchain(context),
          ),
        ],
      ),
      drawer: _buildDrawer(this, context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openNewWalletForm(context),
        child: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent, //.withOpacity(0.8),
      ),
      body: wrapWithBlurredLogoBackground(child: const WalletList()),
      // body: wrapWithGradientBackground(child: const WalletList()),
    );
  }

  Future<void> synchWalletsWithBlockchain(BuildContext context) async {
    final result = await walletStateNotifier.reloadAll();
    result.when(
      ok: (updated) {
        final message = updated ? 'refreshed wallets' : 'wallets up-to-date';
        debugPrint(message);
        _showSnackBar(message);
      },
      err: (message) {
        debugPrint('Refresh Error: $message');
        asyncAlertDialog(context, 'Refresh Error', message);
      },
    );
  }

  Future<void> openNewWalletForm(BuildContext context) async {
    String walletName = '';
    List<String> mnemonic = [];
    final form = CreateOrRestoreWalletForm(
      key: const Key('openNewWalletForm'),
      isNew: true,
      suggestedWalletName: 'Wallet #${++_walletNameCounter}',
      isWalletNameUnique: (walletId) => true,
      isMnemonicUnique: (addr) => true,
      doCreateWallet: (BuildContext context, String walletNameField,
          List<String> mnemonicField) {
        walletName = walletNameField;
        mnemonic = mnemonicField;
        Navigator.of(context).pop(true);
      },
      doCancel: (context) => Navigator.of(context).pop(false),
    );
    bool formCompleted = await showDialog(
          context: context,
          builder: (context) => AlertDialog(content: form),
        ) ??
        false;
    if (formCompleted) {
      final result = walletStateNotifier.createNewWallet(
          context: context, walletName: walletName, mnemonic: mnemonic);
      result.when(
        ok: (wallet) {
          final message = 'created new wallet: $walletName';
          debugPrint(message);
          _showSnackBar(message);
        },
        err: (message) {
          debugPrint('ERROR: $message');
          asyncAlertDialog(context, 'Error Creating New Wallet', message);
        },
      );
    }
  }

  Future<void> openReadOnlyWalletForm(BuildContext context) async {
    String walletName = '';
    late ShelleyAddress stakeAddress;
    final form = CreateReadOnlyWalletForm(
      key: const Key('openReadOnlyWalletForm'),
      suggestedWalletName: 'Wallet #${++_walletNameCounter}',
      isWalletNameUnique: (walletId) => true,
      isAddressUnique: (addr) => true,
      doCreateWallet: (BuildContext context, String walletNameField,
          ShelleyAddress stakeAddressField) {
        walletName = walletNameField;
        stakeAddress = stakeAddressField;
        Navigator.of(context).pop(true);
      },
      doCancel: (context) => Navigator.of(context).pop(false),
    );
    bool formCompleted = await showDialog(
          context: context,
          builder: (context) => AlertDialog(content: form),
        ) ??
        false;
    if (formCompleted) {
      final result = await walletStateNotifier.createReadOnlyWallet(
          context: context, walletName: walletName, stakeAddress: stakeAddress);
      result.when(ok: (wallet) {
        final message = 'created read-only wallet: $walletName';
        debugPrint(message);
        _showSnackBar(message);
      }, err: (message) {
        debugPrint('ERROR: $message');
        asyncAlertDialog(context, 'Error Creating Read-only Wallet', message);
      });
    }
  }

  Future<void> openRestoreWalletForm(BuildContext context) async {
    String walletName = '';
    List<String> mnemonic = [];
    final form = CreateOrRestoreWalletForm(
      key: const Key('openRestoreWalletForm'),
      isNew: false,
      suggestedWalletName: 'Wallet #${++_walletNameCounter}',
      isWalletNameUnique: (walletId) => true,
      isMnemonicUnique: (addr) => true,
      doCreateWallet: (BuildContext context, String walletNameField,
          List<String> mnemonicField) {
        walletName = walletNameField;
        mnemonic = mnemonicField;
        Navigator.of(context).pop(true);
      },
      doCancel: (context) => Navigator.of(context).pop(false),
    );
    bool formCompleted = await showDialog(
          context: context,
          builder: (context) => AlertDialog(content: form),
        ) ??
        false;
    if (formCompleted) {
      final result = await walletStateNotifier.restoreWallet(
          context: context, walletName: walletName, mnemonic: mnemonic);
      result.when(ok: (wallet) {
        final message = 'restored wallet: $walletName';
        debugPrint(message);
        _showSnackBar(message);
      }, err: (message) {
        debugPrint('ERROR: $message');
        asyncAlertDialog(context, 'Error Restoring Wallet', message);
      });
    }
  }
}

///
/// WalletList widget where ConsumerWidget replaces StatelessWidget providing us with access to the providers
/// via the passed-in WidgetRef.
///
class WalletList extends ConsumerWidget {
  const WalletList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // by 'watching' the provider, we trigger a rebuild on item list state changes.
    final wallets = ref.watch(walletProvider);
    final bool wide = MediaQuery.of(context).size.width >= 400.0;
    return ListView.builder(
      // Providing a restorationId allows the ListView to restore the
      // scroll position when a user leaves and returns to the app after it
      // has been killed while running in the background.
      restorationId: 'walletListView',
      itemCount: wallets.length,
      itemBuilder: (BuildContext context, int index) {
        final wallet = wallets[index];
        final titleColor = wallet.readOnly ? Colors.grey : Colors.blue[800];
        final subtitleColor = wallet.readOnly ? Colors.grey : Colors.green;
        final titleStyle = Theme.of(context)
            .textTheme
            .subtitle1!
            .apply(color: titleColor, fontWeightDelta: 2);
        final subtitleStyle =
            Theme.of(context).textTheme.subtitle1!.apply(color: subtitleColor);
        return _wrapInSlidable(
          context: context,
          ref: ref,
          wallet: wallet,
          child: Card(
            child: ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(wallet.walletName,
                      style: titleStyle, overflow: TextOverflow.clip),
                  Hero(
                    tag: 'tx-${wallet.walletId}',
                    transitionOnUserGestures: true,
                    child: Text(
                      "${wallet.transactions.length} ${wide ? 'transactions' : 'txs'}",
                      style: titleStyle,
                      overflow: TextOverflow.clip,
                    ),
                  ),
                ],
              ),
              subtitle: Hero(
                tag: 'bal-${wallet.walletId}',
                transitionOnUserGestures: true,
                child: Text(
                  _formatter.format(wallet.balance),
                  style: subtitleStyle,
                  overflow: TextOverflow.clip,
                ),
              ),
              leading: Hero(
                tag: wallet.walletId,
                child: wallet.loadingTime > Duration.zero
                    ? CircularProgressIndicator(
                        value: null,
                        backgroundColor: Colors.black.withOpacity(0.1))
                    : CustomPaint(
                        size: const Size(40, 40),
                        painter: AdaCustomPainter(color: titleColor),
                      ),
              ),
              trailing: const Icon(Icons.chevron_right),
              // trailing: Icon(wallet.readOnly ? Icons.money_off : Icons.monetization_on_outlined, color: subtitleColor),
              onTap: () {
                Navigator.restorablePushNamed(
                  context,
                  WalletDetailsView.routeName,
                  arguments: wallet.walletId,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

void _deleteWallet(BuildContext context, ReadOnlyWallet wallet) {
  final result =
      walletStateNotifier.deleteWallet(context: context, wallet: wallet);
  result.when(ok: (wallet) {
    final message = 'deleted wallet: ${wallet.walletName}';
    debugPrint(message);
    _showSnackBar(message);
  }, err: (message) {
    debugPrint('ERROR: $message');
    asyncAlertDialog(context, 'Error Deleting Wallet',
        'deleting ${wallet.walletName}: $message');
  });
}

void _copyReceiveAddressToClipboard(BuildContext context, Wallet wallet) {
  final toAddress = wallet.firstUnusedReceiveAddress.toBech32();
  Clipboard.setData(ClipboardData(text: toAddress)).then((_) {
    _showSnackBar('${wallet.walletName} address copied to clipboard');
  });
}

Widget _wrapInSlidable(
        {required ReadOnlyWallet wallet,
        required BuildContext context,
        required WidgetRef ref,
        required Widget child}) =>
    Slidable(
      startActionPane: wallet.readOnly
          ? null
          : ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.4,
              children: [
                SlidableAction(
                  label: 'Send',
                  backgroundColor: Colors.green,
                  icon: Icons.send,
                  onPressed: (context) => openSendAdaForm(
                      _scaffoldKey.currentContext!, wallet as Wallet),
                ),
                SlidableAction(
                  label: 'Receive',
                  backgroundColor: Colors.orange,
                  icon: Icons.save_alt,
                  onPressed: (context) =>
                      _copyReceiveAddressToClipboard(context, wallet as Wallet),
                ),
              ],
            ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.2,
        children: [
          SlidableAction(
            label: 'Delete',
            backgroundColor: Colors.red,
            icon: Icons.delete,
            onPressed: (context) => _deleteWallet(context, wallet),
          ),
        ],
      ),
      child: child,
    );

Widget wrapWithBlurredLogoBackground({required Widget child}) => Container(
      height: double.maxFinite,
      width: double.maxFinite,
      decoration: const FlutterLogoDecoration(),
      child: ClipRRect(
        // make sure we apply clip it properly
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
              alignment: Alignment.center,
              color: Colors.grey.withOpacity(0.1),
              child: child),
        ),
      ),
    );

Widget wrapWithGradientBackground({required Widget child}) => Container(
    decoration: const BoxDecoration(
        gradient: LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [Colors.white, Colors.grey],
    )),
    child: child);

Widget _buildDrawer(
        WalletListView walletItemListView, BuildContext originContext) =>
    Drawer(
      child: Consumer(builder: (context, watch, child) {
        return ListView(padding: EdgeInsets.zero, children: [
          const DrawerHeader(
            decoration: FlutterLogoDecoration(),
            child: Text(
              'Flutter SDK',
              style: TextStyle(
                fontSize: 28,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_box),
            title: const Text('Create New Wallet'),
            onTap: () {
              Navigator.of(context).pop();
              walletItemListView.openNewWalletForm(originContext);
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore Wallet'),
            onTap: () {
              Navigator.of(context).pop();
              walletItemListView.openRestoreWalletForm(originContext);
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_stories_outlined),
            title: const Text('Create Read-only Wallet'),
            onTap: () {
              Navigator.of(context).pop();
              walletItemListView.openReadOnlyWalletForm(originContext);
            },
          ),
          const Divider(),
          ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.restorablePushNamed(context, SettingsView.routeName);
              }),
        ]);
      }),
    );

void _showSnackBar(String message) =>
    ScaffoldMessenger.of(_scaffoldKey.currentContext!)
        .showSnackBar(SnackBar(content: Text(message)));

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

final _formatter = AdaFormattter.compactCurrency();

int _walletNameCounter = 0;
