import 'package:flutter/material.dart';
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

/// Displays a list of wallets.
class WalletItemListView extends StatelessWidget {
  const WalletItemListView({Key? key}) : super(key: key);

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    // final walletService = ref.watch(walletStateNotifier);
    // final wallets = walletService.wallets;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallets'),
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

  void _createNewWallet(BuildContext context, String walletName, List<String> mnemonic) {
    Navigator.of(context).pop();
    walletStateNotifier.createNewWallet(context: context, walletName: walletName, mnemonic: mnemonic);
  }

  void _createReadOnlyWallet(BuildContext context, String walletName, ShelleyAddress stakeAddress) async {
    Navigator.of(context).pop();
    walletStateNotifier.createReadOnlyWallet(context: context, walletName: walletName, stakeAddress: stakeAddress);
  }

  void _restoreWallet(BuildContext context, String walletName, List<String> mnemonic) async {
    Navigator.of(context).pop();
    walletStateNotifier.restoreWallet(context: context, walletName: walletName, mnemonic: mnemonic);
  }

  static int _walletNameCounter = 0;

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

final _formatter = AdaFormattter.compactCurrency();

/// ConsumerWidget replaces StatelessWidget providing us with access to the providers
/// via the passed-in WidgetRef.
class WalletList extends ConsumerWidget {
  const WalletList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleStyle = Theme.of(context).textTheme.subtitle1!.apply(color: Colors.blue, fontWeightDelta: 2);
    final subtitleStyle = Theme.of(context).textTheme.subtitle2!.apply(color: Colors.green);
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
        return _wrapInSlidable(
          context: context,
          ref: ref,
          wallet: wallet,
          child: ListTile(
            title: Text(wallet.walletName, style: titleStyle),
            subtitle: Text(_formatter.format(wallet.balance), style: subtitleStyle),
            leading: CustomPaint(
              size: const Size(40, 40),
              painter: AdaCustomPainter(color: Colors.blue[800]),
            ),
            trailing: wallet.readOnly
                ? const Icon(
                    Icons.money_off,
                    color: Colors.grey,
                  )
                : const Icon(
                    Icons.monetization_on_outlined,
                    color: Colors.green,
                  ),
            onTap: () {
              Navigator.restorablePushNamed(
                context,
                WalletDetailsView.routeName,
              );
            },
          ),
        );
      },
    );
  }
}

void _send(BuildContext context, ReadOnlyWallet wallet) {}

void _deleteWallet(BuildContext context, ReadOnlyWallet wallet) {}

Widget _wrapInSlidable({
  required ReadOnlyWallet wallet,
  required BuildContext context,
  required WidgetRef ref,
  required Widget child,
}) {
//      AssetStateEnum state = stringToState(record.tag1);
  const showDelete = true;
  final showPay = !wallet.readOnly;
  List<Widget> leftButtons = [];
  List<Widget> rightButtons = [];
  if (showPay) {
    leftButtons.add(SlidableAction(
      label: 'Send',
      backgroundColor: Colors.green,
      icon: Icons.monetization_on_outlined,
      onPressed: (context) => _send(context, wallet),
    ));
  }
  if (showDelete) {
    rightButtons.add(SlidableAction(
      label: 'Delete',
      backgroundColor: Colors.red,
      icon: Icons.delete,
      onPressed: (context) => _deleteWallet(context, wallet),
    ));
  }
  Slidable slidable = Slidable(
    startActionPane: ActionPane(
      motion: const DrawerMotion(),
      extentRatio: 0.25,
      children: leftButtons,
    ),
    endActionPane: ActionPane(
      motion: const DrawerMotion(),
      extentRatio: 0.25,
      children: rightButtons,
    ),
    child: child,
  );

  return slidable;
}
