// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:oxidized/oxidized.dart';
import 'package:test/test.dart';
import 'mock_wallet_2.dart';

const ada = 1000000;
void main() {
  final mockAdapter = BlockfrostBlockchainAdapter(
      blockfrost: buildMockBlockfrostWallet2(),
      networkId: NetworkId.testnet,
      projectId: '');
  final stakeAddress = ShelleyAddress.fromBech32(stakeAddr2);
  final toAddress = ShelleyAddress.fromBech32(
      'addr_test1qrf6r5df3v4p43f5ncyjgtwmajnasvw6zath6wa7226jxcfxngwdkqgqcvjtzmz624d6efz67ysf3597k24uyzqg5ctsw3hqzt');
  const mnemonic =
      'chest task gorilla dog maximum forget shove tag project language head try romance memory actress raven resist aisle grunt check immense wrap enlist napkin';
  final hdWallet = HdWallet.fromMnemonic(mnemonic);
  final accountIndex = defaultAccountIndex;
  final addressKeyPair = hdWallet.deriveAddressKeys(account: accountIndex);
  final wallet = WalletImpl(
    blockchainAdapter: mockAdapter,
    stakeAddress: stakeAddress,
    addressKeyPair: addressKeyPair,
    walletName: 'mock wallet',
    hdWallet: HdWallet.fromMnemonic(mnemonic),
  );

  group('TransactionBuilder -', () {
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
      expect(unspentTxs.length, equals(2));
    });
    test('sendAda - 99 ADA - 1 UTxOs', () async {
      Result<ShelleyTransaction, String> result =
          await wallet.sendAda(toAddress: toAddress, lovelace: ada * 99);
      expect(result.isOk(), isTrue);
      final tx = result.unwrap();
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
      Result<ShelleyTransaction, String> result =
          await wallet.sendAda(toAddress: toAddress, lovelace: ada * 100);
      expect(result.isOk(), isTrue);
      final tx = result.unwrap();
      expect(tx.body.inputs.length, 2,
          reason: 'the largest Utxo 100ADA will not cover fee');
      expect(tx.body.outputs.length, 2, reason: 'spend & change outputs');
      final balResult =
          tx.body.transactionIsBalanced(cache: mockAdapter, fee: tx.body.fee);
      expect(balResult.isOk(), isTrue);
      expect(balResult.unwrap(), isTrue);
      expect(tx.body.fee, lessThan(2000000));
    });
    test('sendAda - 200 ADA - insufficient balance', () async {
      Result<ShelleyTransaction, String> result =
          await wallet.sendAda(toAddress: toAddress, lovelace: ada * 200);
      expect(result.isErr(), isTrue);
      //print("Error: ${result.unwrapErr()}");
    });
    // test('send multi-asset transaction using builder', () async {
    //   //build multi-asset request of 5 ADD and 1 TEST token
    //   final Coin maxFeeGuess = 200000; //add fee to requested ADA amount
    //   final multiAssetRequest = MultiAssetRequestBuilder(coin: ADA * 5 + maxFeeGuess)
    //       .nativeAsset(policyId: '6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7', value: 1)
    //       .build();
    //   //coin selection:
    //   final inputsResult = await largestFirst(
    //     unspentInputsAvailable: wallet.unspentTransactions,
    //     outputsRequested: multiAssetRequest,
    //     ownedAddresses: wallet.addresses.toSet(),
    //   );
    //   expect(inputsResult.isOk(), isTrue);

    //   //mirror request in a ShelleyValue, less the fee:
    //   final shelleyValue = MultiAssetBuilder(coin: ADA * 5)
    //       .nativeAsset(policyId: '6b8d07d69639e9413dd637a1a815a7323c69c86abbafb66dbfdb1aa7', value: 1)
    //       .build();

    //   //use TransactionBuilder to assemble ShelleyTransaction:
    //   final builder = TransactionBuilder()
    //     ..inputs(inputsResult.unwrap().inputs)
    //     ..value(shelleyValue)
    //     ..fee(maxFeeGuess)
    //     ..kit(wallet.hdWallet.deriveUnusedBaseAddressKit()) //contains sign key, verify key & toAddress
    //     ..blockchainAdapter(wallet.blockchainAdapter)
    //     ..changeAddress(wallet.firstUnusedChangeAddress);
    //   final txResult = await builder.build();
    //   expect(txResult.isOk(), isTrue);
    //   final ShelleyTransaction tx = txResult.unwrap();
    //   expect(tx.body.inputs.length, 2, reason: 'need an ADA tx and a TEST tx');
    //   expect(tx.body.outputs.length, 2, reason: 'spend & change outputs');

    //   //submit transaction to blockchain:
    //   final submitResult = await wallet.blockchainAdapter.submitTransaction(tx.serialize);
    //   expect(submitResult.isOk(), isTrue);
    // });
  });
}
