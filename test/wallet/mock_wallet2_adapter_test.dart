// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'mock_wallet_2.dart';

void main() {
  Logger.root.level = Level.WARNING; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  final logger = Logger('MockWallet2AdapterTest');
  final formatter = AdaFormattter.compactCurrency();
  final mockAdapter = BlockfrostBlockchainAdapter(
      blockfrost: buildMockBlockfrostWallet2(),
      network: Networks.testnet,
      projectId: 'mock-id');
  group('MockPublicWallet -', () {
    test('create testnet wallet 2', () async {
      final address = ShelleyAddress.fromBech32(stakeAddr2);
      final wallet = ReadOnlyWalletImpl(
        blockchainAdapter: mockAdapter,
        stakeAddress: address,
        walletName: 'mock wallet',
      );
      final latestBlockResult = await mockAdapter.latestBlock();
      latestBlockResult.when(
          ok: (block) {
            logger.info("Block(time: ${block.time}, slot: ${block.slot})");
            expect(block.slot, greaterThanOrEqualTo(39241175));
          },
          err: (err) => logger.info(err));
      final updateResult =
          await mockAdapter.updateWallet(stakeAddress: address);
      updateResult.when(
          ok: (update) {
            logger.info(
                "Wallet(balance: ${update.balance}, formatted: ${formatter.format(update.balance)})");
            wallet.refresh(
                balance: update.balance,
                usedAddresses: update.addresses,
                transactions: update.transactions,
                assets: update.assets,
                stakeAccounts: []);

            //addresses
            for (var addr in update.addresses) {
              logger.info(addr.toString());
            }
            expect(wallet.addresses.length, equals(3));

            //assets
            update.assets.forEach(
                (key, value) => logger.info("Asset($key: $key, value: $value"));
            expect(wallet.findAssetByTicker('ADA'), isNotNull);
            expect(
                wallet.findAssetByTicker('ADA')?.assetId, equals(lovelaceHex));
            expect(wallet.findAssetByTicker('TEST'), isNotNull);
            final testcoinHex = wallet.findAssetByTicker('TEST')!.assetId;

            //transactions
            final Set<AbstractAddress> addressSet = update.addresses.toSet();
            for (var tx in update.transactions) {
              final w = WalletTransactionImpl(
                  rawTransaction: tx, addressSet: addressSet);
              logger.info(
                  "${tx.toString()} - ${w.currencyBalancesByTicker(assetByAssetId: update.assets)} fees:${w.fees}");
            }
            expect(wallet.filterTransactions(assetId: lovelaceHex).length,
                equals(4));
            expect(wallet.filterTransactions(assetId: testcoinHex).length,
                equals(2));

            //balances
            expect(wallet.currencies[lovelaceHex], equals(update.balance));
            expect(wallet.currencies[testcoinHex], equals(1));
          },
          err: (err) => logger.info(err));
    }); //, skip: 'not worth the effort to setup and maintain'
  });
}
