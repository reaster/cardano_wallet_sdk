import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_example/src/widgets/alert_dialog.dart';
import 'package:flutter_example/src/widgets/send_funds_form.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_example/src/providers.dart';
import 'package:flutter_example/src/widgets/ada_shape_maker.dart';
import 'package:flutter_example/src/widgets/create_or_restore_wallet_form.dart';
import 'package:flutter_example/src/widgets/create_read_only_wallet_form.dart';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import '../settings/settings_view.dart';
import 'wallet_details_view.dart';

///
/// Displays a list of wallets.
///
class WalletListView extends StatelessWidget {
  const WalletListView({Key? key}) : super(key: key);

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    bool isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Flutter SDK'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              walletStateNotifier.reloadAll();
              //Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          ),
        ],
      ),
      drawer: _buildDrawer(this, context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openNewWalletForm(context),
        child: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: isDark ? FlutterLogoDecoration() : gradientBackground,
        child: const WalletList(),
      ),
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

  static const gradientBackground = BoxDecoration(
      gradient: LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Colors.white, Colors.grey],
  ));
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
                  Text(wallet.walletName, style: titleStyle),
                  Hero(
                    tag: 'tx-${wallet.walletId}',
                    transitionOnUserGestures: true,
                    child: Text(
                        "${wallet.transactions.length} ${wide ? 'transactions' : 'txs'}",
                        style: titleStyle),
                  ),
                ],
              ),
              subtitle: Hero(
                tag: 'bal-${wallet.walletId}',
                transitionOnUserGestures: true,
                child: Text(_formatter.format(wallet.balance),
                    style: subtitleStyle),
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
              trailing: Icon(Icons.chevron_right),
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

// void _send({required BuildContext context, required Wallet wallet, required ShelleyAddress toAddress, required int lovelace}) async {
//   Navigator.of(context).pop();
//   final result = await walletStateNotifier.sendAda(wallet: wallet, toAddress: toAddress, lovelace: lovelace, context: context);
//   result.when(
//     ok: (tx) {
//       final message = 'sent ${_formatter.format(lovelace)} to ${toAddress.toBech32().substring(0, 30)}...';
//       debugPrint(message);
//       _showSnackBar(message);
//     },
//     err: (message) {
//       debugPrint("error sending ada: $message");
//       asyncAlertDialog(_scaffoldKey.currentContext!,
//           'Error sending ${_formatter.format(lovelace)} to ${toAddress.toBech32().substring(0, 30)}...', message);
//     },
//   );
// }

void _deleteWallet(BuildContext context, ReadOnlyWallet wallet) {
  final result =
      walletStateNotifier.deleteWallet(context: context, wallet: wallet);
  result.when(
    ok: (wallet) {
      final message = 'deleted wallet: ${wallet.walletName}';
      debugPrint(message);
      _showSnackBar(message);
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
      _showSnackBar(message);
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
      _showSnackBar(message);
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
      _showSnackBar(message);
    },
    err: (message) =>
        asyncAlertDialog(context, 'Error Restoring Wallet', message),
  );
}

// Future<void> openSendAdaForm(BuildContext context, Wallet wallet) async {
//   final form = SendFundsForm(
//     key: const Key('sendAdaForm'),
//     wallet: wallet,
//     toAddress: null,
//     lovelace: 0,
//     doSendAda: _send,
//     doCancel: (context) => Navigator.of(context).pop(),
//   );
//   return await showDialog(
//     context: context,
//     builder: (context) => AlertDialog(content: form),
//   );
// }

void _copyReceiveAddressToClipboard(BuildContext context, Wallet wallet) {
  final toAddress = wallet.firstUnusedReceiveAddress.toBech32();
  Clipboard.setData(ClipboardData(text: toAddress)).then((_) {
    _showSnackBar('address copied to clipboard');
  });
}

void _showSnackBar(String message) =>
    ScaffoldMessenger.of(_scaffoldKey.currentContext!)
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

Widget _buildDrawer(
        WalletListView walletItemListView, BuildContext originContext) =>
    Drawer(
      child: Consumer(builder: (context, watch, child) {
        return ListView(padding: EdgeInsets.zero, children: [
          DrawerHeader(
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
            leading: const Icon(Icons.book),
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

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
final _formatter = AdaFormattter.compactCurrency();
int _walletNameCounter = 0;
