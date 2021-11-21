import 'package:flutter/material.dart';
import 'package:flutter_example/src/wallet/create_read_only_wallet_form.dart';
import 'package:speed_dial_fab/speed_dial_fab.dart';

import '../settings/settings_view.dart';
import 'wallet_item.dart';
import 'wallet_details_view.dart';

/// Displays a list of wallets.
class WalletItemListView extends StatelessWidget {
  const WalletItemListView({
    Key? key,
    this.items = const [WalletItem(1), WalletItem(2), WalletItem(3)],
  }) : super(key: key);

  static const routeName = '/';

  final List<WalletItem> items;

  @override
  Widget build(BuildContext context) {
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
          () => {},
          () => openReadOnlyWallet(context),
          () => {},
        ],
        secondaryBackgroundColor: Colors.lightBlue[900],
        secondaryForegroundColor: Colors.lightBlueAccent[100],
        primaryBackgroundColor: Colors.lightBlueAccent[700],
        primaryForegroundColor: Colors.lightBlueAccent[100],
      ),
      body: ListView.builder(
        // Providing a restorationId allows the ListView to restore the
        // scroll position when a user leaves and returns to the app after it
        // has been killed while running in the background.
        restorationId: 'walletItemListView',
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          final item = items[index];

          return ListTile(
              title: Text('Wallet ${item.id}'),
              leading: const CircleAvatar(
                // Display the Flutter Logo image asset.
                foregroundImage: AssetImage('assets/images/flutter_logo.png'),
              ),
              onTap: () {
                // Navigate to the details page. If the user leaves and returns to
                // the app after it has been killed while running in the
                // background, the navigation stack is restored.
                Navigator.restorablePushNamed(
                  context,
                  WalletItemDetailsView.routeName,
                );
              });
        },
      ),
    );
  }

  void createReadOnlyWalletForm(
      BuildContext context, String walletName, String address) {
    Navigator.of(context).pop();
    print('TODO create $walletName with ID:$address');
  }

  static int _walletNameCounter = 0;

  Future<void> openReadOnlyWallet(BuildContext context) async {
    final form = CreateReadOnlyWalletForm(
      key: const Key('createReadOnlyWallet'),
      suggestedWalletName: 'Wallet #${++_walletNameCounter}',
      isWalletNameUnique: (walletId) => true,
      isAddressUnique: (addr) => true,
      doCreateWallet: createReadOnlyWalletForm,
      doCancel: (context) => Navigator.of(context).pop(),
    );
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(content: form),
    );
  }
}
