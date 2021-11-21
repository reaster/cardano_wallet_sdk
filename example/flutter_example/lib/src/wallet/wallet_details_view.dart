import 'package:flutter/material.dart';

/// Displays detailed information about a SampleItem.
class WalletItemDetailsView extends StatelessWidget {
  const WalletItemDetailsView({Key? key}) : super(key: key);

  static const routeName = '/wallet_item';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
      ),
      body: const Center(
        child: Text('More Information Here'),
      ),
    );
  }
}
