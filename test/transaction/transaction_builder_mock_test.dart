// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:oxidized/oxidized.dart';
import 'package:test/test.dart';
import '../wallet/mock_wallet_2.dart';
import 'package:logging/logging.dart';

void main() {
  Logger.root.level = Level.WARNING; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  final logger = Logger('TxBuilderMockTest');
  const ada = 1000000;
  final mockAdapter = BlockfrostBlockchainAdapter(
      blockfrost: buildMockBlockfrostWallet2(),
      network: Networks.testnet,
      projectId: '');
  final stakeAddress = ShelleyAddress.fromBech32(stakeAddr2);
  final toAddress = parseAddress(
      'addr_test1qrf6r5df3v4p43f5ncyjgtwmajnasvw6zath6wa7226jxcfxngwdkqgqcvjtzmz624d6efz67ysf3597k24uyzqg5ctsw3hqzt');
  const mnemonic =
      'chest task gorilla dog maximum forget shove tag project language head try romance memory actress raven resist aisle grunt check immense wrap enlist napkin';
  // final hdWallet = HdWallet.fromMnemonic(mnemonic: mnemonic.split(' '));
  // final accountIndex = defaultAccountIndex;
  // final addressKeyPair = hdWallet.deriveAddressKeys(account: accountIndex);
  final wallet = WalletImpl(
    account: HdMaster.mnemonic(mnemonic.split(' '), network: Networks.testnet)
        .account(),
    blockchainAdapter: mockAdapter,
    walletName: 'mock wallet',
  );

  //Wallet UTxOs
  //tx.outputs[1].amounts: TransactionAmount(unit: 6c6f76656c616365 quantity: 99,228,617)
  //tx.outputs[1].amounts: TransactionAmount(unit: 6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7 quantity: 1)
  //tx.outputs[0].amounts: TransactionAmount(unit: 6c6f76656c616365 quantity: 100,000,000)
  //Total balance:
  //6c6f76656c616365(lovelace): 199,228,617
  // 6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7(test): 1

  group('TxBuilder -', () {
    setUp(() async {
      //setup wallet
      final updateResult =
          await mockAdapter.updateWallet(stakeAddress: stakeAddress);
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
      unspentTxs.forEach((tx) {
        logger.info("txId: ${tx.txId}:");
        tx.utxos.forEach((utxo) {
          tx.outputs[utxo.index].amounts.forEach((a) {
            logger.info("tx.outputs[${utxo.index}].amounts: ${a}");
          });
          logger.info("utxo.output: ${tx.outputs[utxo.index]}");
        });
      });
      expect(unspentTxs.length, equals(2));
      wallet.currencies.forEach((key, value) {
        logger.info("$key: $value");
      });
    });
    test('sendAda - 99 ADA - 1 UTxOs', () async {
      Result<BcTransaction, String> result =
          await wallet.sendAda(toAddress: toAddress, lovelace: ada * 99);
      expect(result.isOk(), isTrue);
      final tx = result.unwrap();
      expect(tx.verify, isTrue, reason: 'witnesses validate signatures');
      expect(tx.body.inputs.length, 1,
          reason: 'the largest Utxo 100ADA > spend + fee');
      expect(tx.body.outputs.length, 2, reason: 'spend & change outputs');
      final balResult =
          tx.body.transactionIsBalanced(cache: mockAdapter, fee: tx.body.fee);
      expect(balResult.isOk(), isTrue);
      expect(balResult.unwrap(), isTrue);
      expect(tx.body.fee, lessThan(defaultFee));
    });
    test('sendAda - 100 ADA - 2 UTxOs', () async {
      Result<BcTransaction, String> result =
          await wallet.sendAda(toAddress: toAddress, lovelace: ada * 100);
      expect(result.isOk(), isTrue);
      final tx = result.unwrap();
      expect(tx.verify, isTrue, reason: 'witnesses validate signatures');
      expect(tx.body.inputs.length, 2,
          reason: 'the largest Utxo 100ADA will not cover fee');
      expect(tx.body.outputs.length, 2, reason: 'spend & change outputs');
      final balResult =
          tx.body.transactionIsBalanced(cache: mockAdapter, fee: tx.body.fee);
      expect(balResult.isOk(), isTrue);
      expect(balResult.unwrap(), isTrue);
      expect(tx.body.fee, lessThan(2000000));
    }, skip: "TODO");
    test('sendAda - 200 ADA - insufficient balance', () async {
      Result<BcTransaction, String> result =
          await wallet.sendAda(toAddress: toAddress, lovelace: ada * 200);
      expect(result.isErr(), isTrue);
      //logger.info("Error: ${result.unwrapErr()}");
    });

    test(
      'send multi-asset transaction using builder',
      () async {
        //build multi-asset request of 5 ADD and 1 TEST token
        wallet.currencies.forEach((key, value) {
          logger.info("currency: $key -> $value");
        });
        final filteredTxs = wallet.filterTransactions(
            assetId:
                '6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7');
        logger.info("currency 6b8d..1aa7 tx count: ${filteredTxs.length}");
        final Coin maxFeeGuess = 200000; //add fee to requested ADA amount
        // final multiAssetRequest = MultiAssetRequestBuilder(coin: ada * 5)
        //     .nativeAsset(
        //         policyId:
        //             '6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7',
        //         value: 1)
        //     .build();
        //coin selection:
        final inputsResult = await largestFirst(
          unspentInputsAvailable: wallet.unspentTransactions,
          spendRequest: FlatMultiAsset(fee: maxFeeGuess, assets: {
            lovelaceHex: 5 * ada,
            '6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7': 1,
          }),
          ownedAddresses: wallet.addresses.toSet(),
        );
        if (inputsResult.isErr())
          logger.severe("error: ${inputsResult.unwrapErr()}");
        expect(inputsResult.isOk(), isTrue);

        //mirror request in a ShelleyValue, less the fee:
        final shelleyValue = MultiAssetBuilder(coin: ada * 5)
            .nativeAsset(
                policyId:
                    '6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7',
                value: 1)
            .build();

        //use TxBuilder to assemble BcTransaction:
        final builder = TxBuilder()
          ..inputs(inputsResult.unwrap().inputs)
          ..value(shelleyValue)
          ..fee(maxFeeGuess)
          ..wallet(wallet)
          ..blockchainAdapter(wallet.blockchainAdapter)
          ..changeAddress(wallet.firstUnusedChangeAddress);
        final BcTransaction tx = await builder.build();
        expect(builder.isBalanced, isTrue);
        expect(tx.body.inputs.length, 2,
            reason: 'need an ADA tx and a TEST tx');
        expect(tx.body.outputs.length, 2, reason: 'spend & change outputs');
        expect(tx.verify, isTrue, reason: 'found private keys');

        //submit transaction to blockchain:
        final submitResult =
            await wallet.blockchainAdapter.submitTransaction(tx.serialize);
        expect(submitResult.isOk(), isTrue);
      },
      //skip:  'not supported yet, need to rewrite largestFirst CoinSelectionAlgorithm'
    );
  });
}
