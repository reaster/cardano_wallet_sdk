// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:test/test.dart';
import 'mock_wallet_2.dart';

const ada = 1000000;
void main() {
  final mockAdapter = BlockfrostBlockchainAdapter(
      blockfrost: buildMockBlockfrostWallet2(),
      networkId: NetworkId.testnet,
      projectId: '');
  final address = ShelleyAddress.fromBech32(stakeAddr2);
  final wallet = ReadOnlyWalletImpl(
    blockchainAdapter: mockAdapter,
    stakeAddress: address,
    walletName: 'mock wallet',
  );
  group('coin slection: largestFirst -', () {
    setUp(() async {
      //setup wallet
      final updateResult =
          await mockAdapter.updateWallet(stakeAddress: address);
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
    test('setup coin selection - 100 ADA', () async {
      final result = await largestFirst(
        unspentInputsAvailable: wallet.unspentTransactions,
        outputsRequested: [MultiAssetRequest.lovelace(100 * ada)],
        ownedAddresses: wallet.addresses.toSet(),
      );
      expect(result.isOk(), isTrue);
      final coins = result.unwrap();
      expect(coins.inputs.length, 1);
      expect(coins.inputs[0].index, 0);
    });
    test('setup coin selection - 101 ADA', () async {
      final result2 = await largestFirst(
        unspentInputsAvailable: wallet.unspentTransactions,
        outputsRequested: [MultiAssetRequest.lovelace(101 * ada)],
        ownedAddresses: wallet.addresses.toSet(),
      );
      expect(result2.isOk(), isTrue);
      final coins2 = result2.unwrap();
      expect(coins2.inputs.length, 2);
      expect(coins2.inputs[0].index, 0);
      expect(coins2.inputs[1].index, 1);
    });
    test('insufficient funds error', () async {
      //setup coin selection - 201 ADA, which will result in insufficient funds error
      final result3 = await largestFirst(
        unspentInputsAvailable: wallet.unspentTransactions,
        outputsRequested: [MultiAssetRequest.lovelace(201 * ada)],
        coinSelectionLimit: 4,
        ownedAddresses: wallet.addresses.toSet(),
      );
      expect(result3.isErr(), isTrue);
      expect(result3.unwrapErr().reason,
          CoinSelectionErrorEnum.inputValueInsufficient);
    });
    test('InputsExhausted', () async {
      //setup coin selection - 101 ADA and coinSelectionLimit = 1 - which will give InputsExhausted
      final result4 = await largestFirst(
        unspentInputsAvailable: wallet.unspentTransactions,
        outputsRequested: [MultiAssetRequest.lovelace(101 * ada)],
        coinSelectionLimit: 1,
        ownedAddresses: wallet.addresses.toSet(),
      );
      expect(result4.isErr(), isTrue);
      expect(
          result4.unwrapErr().reason, CoinSelectionErrorEnum.inputsExhausted);
    });
  });
}
