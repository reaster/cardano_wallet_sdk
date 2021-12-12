// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import '../widgets/alert_dialog.dart';
import '../widgets/ada_shape_maker.dart';
import '../widgets/send_funds_form.dart';
import '../providers.dart';

/// Displays wallet balance and transactions.
class WalletDetailsView extends ConsumerWidget {
  final String walletId;

  const WalletDetailsView({Key? key, required this.walletId}) : super(key: key);

  static const routeName = '/wallet';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // by 'watching' the provider, we trigger a rebuild on state changes.
    ref.watch(walletProvider);
    final wallet = walletStateNotifier.findByWalletId(walletId);
    return wallet != null
        ? WalletCustomScrollView(wallet: wallet)
        : _errorMessage;
  }

  Widget get _errorMessage => Scaffold(
        appBar: AppBar(
          title: const Text('ERROR'),
        ),
        body: Center(
          child: Text(
            'no wallet found for walletId: $walletId',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
}

class WalletCustomScrollView extends StatelessWidget {
  final ReadOnlyWallet wallet;

  const WalletCustomScrollView({Key? key, required this.wallet})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bool wide = mediaQuery.size.width >= 400.0;
    // bool isDark = settingsController.themeMode == ThemeMode.dark;
    // print('settingsController.themeMode: ${settingsController.themeMode}');
    final titleColor = wallet.readOnly ? Colors.grey : Colors.blue[800];
    final subtitleColor = wallet.readOnly ? Colors.grey : Colors.green;
    final feeColor = wallet.readOnly ? Colors.grey : Colors.red;
    final titleStyle = Theme.of(context)
        .textTheme
        .subtitle1!
        .apply(color: titleColor, fontWeightDelta: 2);
    final subtitleStyle =
        Theme.of(context).textTheme.subtitle2!.apply(color: subtitleColor);
    final feeStyle =
        Theme.of(context).textTheme.subtitle2!.apply(color: feeColor);
    final balenceStyle =
        Theme.of(context).textTheme.headline4!.apply(color: subtitleColor);
    final localDateTimeFormat =
        wide ? DateFormat.yMd().add_jm() : DateFormat.yMd();

    return Scaffold(
      key: _scaffoldKey,
      floatingActionButton: wallet.readOnly
          ? null
          : FloatingActionButton(
              onPressed: () => openSendAdaForm(
                  _scaffoldKey.currentContext!, wallet as Wallet),
              child: const Icon(Icons.send),
              backgroundColor: Colors.blueAccent.withOpacity(0.8),
            ),
      // body: Container(
      //   decoration: isDark ? FlutterLogoDecoration() : gradientBackground,
      body: _wrapWithBlurredLogo(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              leading: BackButton(onPressed: () => Navigator.of(context).pop()),
              title: Text(wallet.walletName),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _synchWalletsWithBlockchain(context),
                ),
              ],
            ),
            SliverList(
              delegate: SliverChildListDelegate.fixed(
                [
                  const SizedBox(height: 8),
                  Center(
                    child: Hero(
                      tag: wallet.walletId,
                      transitionOnUserGestures: true,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: CustomPaint(
                          size: const Size(80, 80),
                          painter: AdaCustomPainter(color: titleColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Hero(
                      tag: 'bal-${wallet.walletId}',
                      transitionOnUserGestures: true,
                      child: Text(
                        _formatter.format(wallet.balance),
                        style: balenceStyle,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Hero(
                      tag: 'tx-${wallet.walletId}',
                      transitionOnUserGestures: true,
                      child: Text(
                        "${wallet.transactions.length} transactions",
                        style: titleStyle,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // const Divider(height: 1),
                ],
              ),
            ),
            SliverList(
                delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                WalletTransaction tx = wallet.transactions[index];
                final txType = tx.type == TransactionType.deposit
                    ? 'Deposit'
                    : 'Withdrawal';
                return Card(
                  child: ListTile(
                    leading: _leading(tx),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(txType,
                            style: titleStyle, overflow: TextOverflow.clip),
                        Text(_formatter.format(tx.amount),
                            style: titleStyle, overflow: TextOverflow.clip),
                      ],
                    ),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          localDateTimeFormat.format(tx.time),
                          style: subtitleStyle,
                          overflow: TextOverflow.clip,
                        ),
                        if (tx.fees > 0)
                          Text(
                            '${_formatter.format(tx.fees)} fee',
                            style: feeStyle,
                            overflow: TextOverflow.clip,
                          ),
                      ],
                    ),
                    onTap: () => _launchBrowser(tx, wallet.networkId),
                    //exit_to_app, call_made_outlined, insert_link, launch, logout, open_in_browser, open_in_new, visibility_outlined
                    trailing: const Icon(Icons.insert_link, color: Colors.grey),
                  ),
                );
              },
              childCount: wallet.transactions.length,
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _synchWalletsWithBlockchain(BuildContext context) async {
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

  void _launchBrowser(WalletTransaction tx, NetworkId networkId) async {
    final browser = CardanoScanBlockchainExplorer.fromNetwork(networkId);
    final url = browser.transactionUrl(transactionIdHex32: tx.txId);
    debugPrint(url);
    try {
      if (!await launch(url)) {
        _showSnackBar('Could not launch $url');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Widget _leading(WalletTransaction tx) {
    const size = 34.0;
    switch (tx.type) {
      case TransactionType.deposit:
        return const Icon(Icons.save_alt, color: Colors.blue, size: size);
      case TransactionType.withdrawal:
        return const Icon(Icons.send, color: Colors.blue, size: size);
      default:
        return const Icon(Icons.warning, color: Colors.red, size: size);
    }
  }

  Widget _wrapWithBlurredLogo({required Widget child}) => Container(
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

  static const gradientBackground = BoxDecoration(
      gradient: LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Colors.white, Colors.grey],
  ));
}

final _formatter = AdaFormattter.compactCurrency();

void _showSnackBar(String message) =>
    ScaffoldMessenger.of(_scaffoldKey.currentContext!)
        .showSnackBar(SnackBar(content: Text(message)));

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
