// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:oxidized/oxidized.dart';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';

final formatter = AdaFormattter.compactCurrency();

///
/// Demonstrates using the BlockchainAdapter and WalletBuilder to create read-only wallets,
/// restore existing and create new wallets. A wallet can list it's transactions and send
/// payments to other wallets.
///
void main() async {
  // fish the blockfrost key out of a text file
  final adapterKey = _readApiKey();
  // the adapter talks to the blockchain and caches immutable data
  final adapter = BlockchainAdapterFactory.fromKey(
    key: adapterKey,
    networkId: NetworkId.testnet,
  ).adapter();
  //build a read-only wallet from a staking address
  final stakeAddress = ShelleyAddress.fromBech32(
      'stake_test1uz425a6u2me7xav82g3frk2nmxhdujtfhmf5l275dr4a5jc3urkeg');
  final walletBuilder1 = WalletBuilder()
    ..walletName = 'Fred'
    ..adapter = adapter
    ..stakeAddress = stakeAddress;
  final Result<ReadOnlyWallet, String> fred =
      await walletBuilder1.readOnlyBuildAndSync();
  fred.when(
    ok: (wallet) {
      print(
          "${wallet.walletName}'s balance: ${formatter.format(wallet.balance)}");
      for (final tx in wallet.transactions) {
        final txType = tx.type.toString().split('.')[1];
        print("    $txType ${tx.time} ${tx.amount} + ${tx.fees} fee");
      }
    },
    err: (message) => print("Error: $message"),
  );
  //restore a wallet from it's mnemonic phrase
  final mnemonic =
      'army bid park alter aunt click border awake happy sport addict heavy robot change artist sniff height general dust fiber salon fan snack wheat'
          .split(' ');
  final walletBuilder2 = WalletBuilder()
    ..walletName = 'Bob'
    ..adapter = adapter
    ..mnemonic = mnemonic;
  final Result<Wallet, String> bob = await walletBuilder2.buildAndSync();
  bob.when(
    ok: (wallet) => print(
        "${wallet.walletName}'s balance: ${formatter.format(wallet.balance)}"),
    err: (message) => print("Error: $message"),
  );
  //create a new wallet
  final mnemonic2 = WalletBuilder.generateNewMnemonic();
  final walletBuilder3 = WalletBuilder()
    ..walletName = 'Alice'
    ..adapter = adapter
    ..mnemonic = mnemonic2;
  final Result<Wallet, String> alice = await walletBuilder3.buildAndSync();
  alice.when(
    ok: (wallet) => print(
        "${wallet.walletName}'s balance: ${formatter.format(wallet.balance)}"),
    err: (message) => print("Error: $message"),
  );
  // Bob sends 2 ADA to Alice
  const lovelace = 2 * 1000000;
  final result = await bob.unwrap().sendAda(
        toAddress: alice.unwrap().firstUnusedReceiveAddress,
        lovelace: lovelace,
        logTx: true,
        logTxHex: true,
      );
  result.when(
    ok: (tx) => print(
        "Bob sent ${formatter.format(lovelace)} with a ${formatter.format(tx.body.fee)} fee to Alice."),
    err: (message) => print("Error: $message"),
  );
}

String _readApiKey() {
  final file = File(apiKeyFilePath).absolute;
  return file.readAsStringSync();
}

const apiKeyFilePath = '../blockfrost_project_id.txt';
