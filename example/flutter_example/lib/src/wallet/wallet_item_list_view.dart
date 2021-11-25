import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_example/src/widgets/alert_dialog.dart';
import 'package:flutter_example/src/widgets/send_funds_form.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:speed_dial_fab/speed_dial_fab.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:flutter_example/src/providers.dart';
import 'package:flutter_example/src/widgets/ada_shape_maker.dart';
import 'package:flutter_example/src/widgets/create_or_restore_wallet_form.dart';
import 'package:flutter_example/src/widgets/create_read_only_wallet_form.dart';

import '../settings/settings_view.dart';
import 'wallet_details_view.dart';

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
final _formatter = AdaFormattter.compactCurrency();
int _walletNameCounter = 0;

///
/// Displays a list of wallets.
///
class WalletItemListView extends StatelessWidget {
  const WalletItemListView({Key? key}) : super(key: key);

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Flutter SDK'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to the settings page. If the user leaves and returns
              // to the app after it has been killed while running in the
              // background, the navigation stack is restored.
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          ),
        ],
      ),
      floatingActionButton: SpeedDialFabWidget(
        secondaryIconsList: const [
          Icons.add_box,
          Icons.book,
          Icons.restore,
        ],
        secondaryIconsText: const [
          "new wallet",
          "read-only wallet",
          "restore wallet",
        ],
        secondaryIconsOnPress: [
          () => openNewWalletForm(context),
          () => openReadOnlyWalletForm(context),
          () => openRestoreWalletForm(context),
        ],
        secondaryBackgroundColor: Colors.lightBlue[900],
        secondaryForegroundColor: Colors.lightBlueAccent[100],
        primaryBackgroundColor: Colors.lightBlueAccent[700],
        primaryForegroundColor: Colors.lightBlueAccent[100],
      ),
      body: const WalletList(),
    );
  }

  Future<void> openNewWalletForm(BuildContext context) async {
    final form = CreateOrRestoreWalletForm(
      key: const Key('openNewWalletForm'),
      isNew: true,
      suggestedWalletName: 'Wallet #${++_walletNameCounter}',
      isWalletNameUnique: (walletId) => true,
      isMnemonicUnique: (addr) => true,
      doCreateWallet: _createNewWallet,
      doCancel: (context) => Navigator.of(context).pop(),
    );
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(content: form),
    );
  }

  Future<void> openReadOnlyWalletForm(BuildContext context) async {
    final form = CreateReadOnlyWalletForm(
      key: const Key('openReadOnlyWalletForm'),
      suggestedWalletName: 'Wallet #${++_walletNameCounter}',
      isWalletNameUnique: (walletId) => true,
      isAddressUnique: (addr) => true,
      doCreateWallet: _createReadOnlyWallet,
      doCancel: (context) => Navigator.of(context).pop(),
    );
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(content: form),
    );
  }

  Future<void> openRestoreWalletForm(BuildContext context) async {
    final form = CreateOrRestoreWalletForm(
      key: const Key('openRestoreWalletForm'),
      isNew: false,
      suggestedWalletName: 'Wallet #${++_walletNameCounter}',
      isWalletNameUnique: (walletId) => true,
      isMnemonicUnique: (addr) => true,
      doCreateWallet: _restoreWallet,
      doCancel: (context) => Navigator.of(context).pop(),
    );
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(content: form),
    );
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
            Theme.of(context).textTheme.subtitle2!.apply(color: subtitleColor);
        return _wrapInSlidable(
          context: context,
          ref: ref,
          wallet: wallet,
          child: ListTile(
            title: Text(wallet.walletName, style: titleStyle),
            subtitle:
                Text(_formatter.format(wallet.balance), style: subtitleStyle),
            leading: CustomPaint(
              size: const Size(40, 40),
              painter: AdaCustomPainter(color: titleColor),
            ),
            trailing: Icon(
                wallet.readOnly
                    ? Icons.money_off
                    : Icons.monetization_on_outlined,
                color: subtitleColor),
            onTap: () {
              Navigator.restorablePushNamed(
                  context, WalletDetailsView.routeName);
            },
          ),
        );
      },
    );
  }
}

void _send(
    {required BuildContext context,
    required Wallet wallet,
    required ShelleyAddress toAddress,
    required int lovelace}) async {
  Navigator.of(context).pop();
  final result = await walletStateNotifier.sendAda(
      wallet: wallet,
      toAddress: toAddress,
      lovelace: lovelace,
      context: context);
  result.when(
    ok: (tx) {
      final message =
          'sent ${_formatter.format(lovelace)} to ${toAddress.toBech32().substring(0, 30)}...';
      debugPrint(message);
      _showSnackBar(context, message);
    },
    err: (message) {
      debugPrint("error sending ada: $message");
      asyncAlertDialog(
          _scaffoldKey.currentContext!,
          'Error sending ${_formatter.format(lovelace)} to ${toAddress.toBech32().substring(0, 30)}...',
          message);
    },
  );
}

void _deleteWallet(BuildContext context, ReadOnlyWallet wallet) {
  final result =
      walletStateNotifier.deleteWallet(context: context, wallet: wallet);
  result.when(
    ok: (wallet) {
      final message = 'deleted wallet: ${wallet.walletName}';
      debugPrint(message);
      _showSnackBar(context, message);
    },
    err: (message) =>
        asyncAlertDialog(context, 'Error Restoring Wallet', message),
  );
}

void _createNewWallet(
    BuildContext context, String walletName, List<String> mnemonic) {
  Navigator.of(context).pop();
  final result = walletStateNotifier.createNewWallet(
      context: context, walletName: walletName, mnemonic: mnemonic);
  result.when(
    ok: (wallet) {
      final message = 'created new wallet: $walletName';
      debugPrint(message);
      _showSnackBar(context, message);
    },
    err: (message) =>
        asyncAlertDialog(context, 'Error Creating New Wallet', message),
  );
}

void _createReadOnlyWallet(BuildContext context, String walletName,
    ShelleyAddress stakeAddress) async {
  Navigator.of(context).pop();
  final result = await walletStateNotifier.createReadOnlyWallet(
      context: context, walletName: walletName, stakeAddress: stakeAddress);
  result.when(
    ok: (wallet) {
      final message = 'created read-only wallet: $walletName';
      debugPrint(message);
      _showSnackBar(context, message);
    },
    err: (message) =>
        asyncAlertDialog(context, 'Error Creating Read-only Wallet', message),
  );
}

void _restoreWallet(
    BuildContext context, String walletName, List<String> mnemonic) async {
  Navigator.of(context).pop();
  final result = await walletStateNotifier.restoreWallet(
      context: context, walletName: walletName, mnemonic: mnemonic);
  result.when(
    ok: (wallet) {
      final message = 'restored wallet: $walletName';
      debugPrint(message);
      _showSnackBar(context, message);
    },
    err: (message) =>
        asyncAlertDialog(context, 'Error Restoring Wallet', message),
  );
}

Future<void> _openSendAdaForm(BuildContext context, Wallet wallet) async {
  final form = SendFundsForm(
    key: const Key('sendAdaForm'),
    wallet: wallet,
    toAddress: null,
    lovelace: 0,
    doSendAda: _send,
    doCancel: (context) => Navigator.of(context).pop(),
  );
  return await showDialog(
    context: context,
    builder: (context) => AlertDialog(content: form),
  );
}

void _copyReceiveAddressToClipboard(BuildContext context, Wallet wallet) {
  final toAddress = wallet.firstUnusedReceiveAddress.toBech32();
  Clipboard.setData(ClipboardData(text: toAddress)).then((_) {
    _showSnackBar(context, 'address copied to clipboard');
  });
}

void _showSnackBar(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));

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
                  icon: Icons.monetization_on_outlined,
                  onPressed: (context) =>
                      _openSendAdaForm(context, wallet as Wallet),
                ),
                SlidableAction(
                  label: 'Receive',
                  backgroundColor: Colors.orange,
                  icon: Icons.input_outlined,
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
