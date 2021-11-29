import 'package:flutter_example/src/widgets/ada_shape_maker.dart';
import 'package:flutter_example/src/widgets/send_funds_form.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_example/src/providers.dart';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';

/// Displays wallet balance and transactions.
class WalletDetailsView extends StatelessWidget {
  final String walletId;

  const WalletDetailsView({Key? key, required this.walletId}) : super(key: key);

  static const routeName = '/wallet_item';

  @override
  Widget build(BuildContext context) {
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
            style: TextStyle(color: Colors.red),
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
    bool isDark = settingsController.themeMode == ThemeMode.dark;
    print('settingsController.themeMode: ${settingsController.themeMode}');
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
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            openSendAdaForm(_scaffoldKey.currentContext!, wallet as Wallet),
        child: const Icon(Icons.send),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: isDark ? FlutterLogoDecoration() : gradientBackground,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              leading: BackButton(onPressed: () => Navigator.of(context).pop()),
              title: Text(wallet.walletName),
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
                        padding: EdgeInsets.only(right: 16.0),
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
                      child: Text(_formatter.format(wallet.balance),
                          style: balenceStyle),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Hero(
                      tag: 'tx-${wallet.walletId}',
                      transitionOnUserGestures: true,
                      child: Text("${wallet.transactions.length} transactions",
                          style: titleStyle),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // const Divider(height: 1),
                ],
              ),
            ),
            SliverList(
                delegate: new SliverChildBuilderDelegate(
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
                        Text(txType, style: titleStyle),
                        Text(_formatter.format(tx.amount), style: titleStyle),
                      ],
                    ),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          localDateTimeFormat.format(tx.time),
                          style: subtitleStyle,
                        ),
                        if (tx.fees > 0)
                          Text('${_formatter.format(tx.fees)} fee',
                              style: feeStyle),
                      ],
                    ),
                    onTap: () => _launchBrowser(tx, wallet.networkId),
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

  void _launchBrowser(WalletTransaction tx, NetworkId networkId) async {
    final browser = CardanoScanBlockchainExplorer.fromNetwork(networkId);
    final url = browser.transactionUrl(transactionIdHex32: tx.txId);
    print(url);
    try {
      if (!await launch(url)) {
        _showSnackBar('Could not launch $url');
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Widget _leading(WalletTransaction tx) {
    final size = 34.0;
    switch (tx.type) {
      case TransactionType.deposit:
        return Icon(Icons.save_alt, color: Colors.blue, size: size);
      case TransactionType.withdrawal:
        return Icon(Icons.send, color: Colors.blue, size: size);
      default:
        return Icon(Icons.warning, color: Colors.red, size: size);
    }
  }

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
