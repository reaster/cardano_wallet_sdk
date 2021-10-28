import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:oxidized/oxidized.dart';
import 'package:test/test.dart';
import 'mock_wallet_2.dart';

const ADA = 1000000;
void main() {
  final mockWalletAdapter = buildMockWallet2();
  final stakeAddress = ShelleyAddress.fromBech32(stakeAddr2);
  final mnemonic =
      'chest task gorilla dog maximum forget shove tag project language head try romance memory actress raven resist aisle grunt check immense wrap enlist napkin';
  final wallet = WalletImpl(
    blockchainAdapter: mockWalletAdapter,
    stakeAddress: stakeAddress,
    walletName: 'mock wallet',
    hdWallet: HdWallet.fromMnemonic(mnemonic),
  );

  group('TransactionBuilder -', () {
    setUp(() async {
      //setup wallet
      final updateResult = await mockWalletAdapter.updateWallet(stakeAddress: stakeAddress);
      expect(updateResult.isOk(), isTrue);
      final update = updateResult.unwrap();
      wallet.refresh(
          balance: update.balance,
          usedAddresses: update.addresses,
          transactions: update.transactions,
          assets: update.assets,
          stakeAccounts: []);
      final filteredTxs = wallet.filterTransactions(assetId: lovelaceHex);
      expect(filteredTxs.length, equals(4));
      final unspentTxs = wallet.unspentTransactions;
      expect(unspentTxs.length, equals(2));
    });
    test('sendAda - 99 ADA - 1 UTxOs', () async {
      Result<ShelleyTransaction, String> result = await wallet.sendAda(
          toAddress: ShelleyAddress.fromBech32(
              'addr_test1qqy6nhfyks7wdu3dudslys37v252w2nwhv0fw2nfawemmn8k8ttq8f3gag0h89aepvx3xf69g0l9pf80tqv7cve0l33sw96paj'),
          lovelaceAmount: ADA * 99);
      expect(result.isOk(), isTrue);
      final tx = result.unwrap();
      expect(tx.body.inputs.length, 1, reason: 'the largest Utxo 100ADA > spend + fee');
      expect(tx.body.outputs.length, 2, reason: 'spend & change outputs');
      final balResult = tx.body.transactionIsBalanced(cache: mockWalletAdapter, fee: tx.body.fee);
      expect(balResult.isOk(), isTrue);
      expect(balResult.unwrap(), isTrue);
      expect(tx.body.fee, lessThan(defaultFee));
    });
    test('sendAda - 100 ADA - 2 UTxOs', () async {
      Result<ShelleyTransaction, String> result = await wallet.sendAda(
          toAddress: ShelleyAddress.fromBech32(
              'addr_test1qqy6nhfyks7wdu3dudslys37v252w2nwhv0fw2nfawemmn8k8ttq8f3gag0h89aepvx3xf69g0l9pf80tqv7cve0l33sw96paj'),
          lovelaceAmount: ADA * 100);
      expect(result.isOk(), isTrue);
      final tx = result.unwrap();
      expect(tx.body.inputs.length, 2, reason: 'the largest Utxo 100ADA will not cover fee');
      expect(tx.body.outputs.length, 2, reason: 'spend & change outputs');
      final balResult = tx.body.transactionIsBalanced(cache: mockWalletAdapter, fee: tx.body.fee);
      expect(balResult.isOk(), isTrue);
      expect(balResult.unwrap(), isTrue);
      expect(tx.body.fee, greaterThan(defaultFee));
    });
    test('sendAda - 100 ADA - 2 UTxOs', () async {
      Result<ShelleyTransaction, String> result = await wallet.sendAda(
          toAddress: ShelleyAddress.fromBech32(
              'addr_test1qqy6nhfyks7wdu3dudslys37v252w2nwhv0fw2nfawemmn8k8ttq8f3gag0h89aepvx3xf69g0l9pf80tqv7cve0l33sw96paj'),
          lovelaceAmount: ADA * 100);
      expect(result.isOk(), isTrue);
      final tx = result.unwrap();
      expect(tx.body.inputs.length, 2, reason: 'the largest Utxo 100ADA will not cover fee');
      expect(tx.body.outputs.length, 2, reason: 'spend & change outputs');
      final balResult = tx.body.transactionIsBalanced(cache: mockWalletAdapter, fee: tx.body.fee);
      expect(balResult.isOk(), isTrue);
      expect(balResult.unwrap(), isTrue);
      expect(tx.body.fee, greaterThan(defaultFee));
    });
    test('sendAda - 200 ADA - insufficient balance', () async {
      Result<ShelleyTransaction, String> result = await wallet.sendAda(
          toAddress: ShelleyAddress.fromBech32(
              'addr_test1qqy6nhfyks7wdu3dudslys37v252w2nwhv0fw2nfawemmn8k8ttq8f3gag0h89aepvx3xf69g0l9pf80tqv7cve0l33sw96paj'),
          lovelaceAmount: ADA * 200);
      expect(result.isErr(), isTrue);
      print("Error: ${result.unwrapErr()}");
    });
  });
}
