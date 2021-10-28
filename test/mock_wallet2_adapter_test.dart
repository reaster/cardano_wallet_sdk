import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:test/test.dart';
import 'mock_wallet_2.dart';

void main() {
  final formatter = AdaFormattter.compactCurrency();
  final mockWalletAdapter = buildMockWallet2();
  group('MockPublicWallet -', () {
    test('create testnet wallet 2', () async {
      final address = ShelleyAddress.fromBech32(stakeAddr2);
      final wallet = ReadOnlyWalletImpl(
        blockchainAdapter: mockWalletAdapter,
        stakeAddress: address,
        walletName: 'mock wallet',
      );
      final latestBlockResult = await mockWalletAdapter.latestBlock();
      latestBlockResult.when(
          ok: (block) {
            print("Block(time: ${block.time}, slot: ${block.slot})");
            expect(block.slot, greaterThanOrEqualTo(39241175));
          },
          err: (err) => print(err));
      final updateResult = await mockWalletAdapter.updateWallet(stakeAddress: address);
      updateResult.when(
          ok: (update) {
            print("Wallet(balance: ${update.balance}, formatted: ${formatter.format(update.balance)})");
            wallet.refresh(
                balance: update.balance,
                usedAddresses: update.addresses,
                transactions: update.transactions,
                assets: update.assets,
                stakeAccounts: []);

            //addresses
            update.addresses.forEach((addr) => print(addr.toBech32()));
            expect(wallet.addresses.length, equals(3));

            //assets
            update.assets.forEach((key, value) => print("Asset($key: $key, value: $value"));
            expect(wallet.findAssetByTicker('ADA'), isNotNull);
            expect(wallet.findAssetByTicker('ADA')?.assetId, equals(lovelaceHex));
            expect(wallet.findAssetByTicker('TEST'), isNotNull);
            final testcoinHex = wallet.findAssetByTicker('TEST')!.assetId;

            //transactions
            final Set<ShelleyAddress> addressSet = update.addresses.toSet();
            update.transactions.forEach((RawTransaction tx) {
              final w = WalletTransactionImpl(rawTransaction: tx, addressSet: addressSet);
              print("${tx.toString()} - ${w.currencyBalancesByTicker(assetByAssetId: update.assets)} fees:${w.fees}");
            });
            expect(wallet.filterTransactions(assetId: lovelaceHex).length, equals(4));
            expect(wallet.filterTransactions(assetId: testcoinHex).length, equals(2));

            //balances
            expect(wallet.currencies[lovelaceHex], equals(update.balance));
            expect(wallet.currencies[testcoinHex], equals(1));
          },
          err: (err) => print(err));
    }); //, skip: 'not worth the effort to setup and maintain'
  });
}
