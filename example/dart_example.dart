// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'dart:io' show File, sleep;
import 'package:dio/dio.dart';
import 'package:oxidized/oxidized.dart';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:bip32_ed25519/bip32_ed25519.dart';

///
/// Demonstrates using the BlockchainAdapter and WalletBuilder to create read-only wallets,
/// restore existing and create new wallets. A wallet can list it's transactions and send
/// payments to other wallets.
///
void main() async {
  // fish the blockfrost key out of a text file
  final blockfrostKey = _readApiKey();

  // the adapter talks to the blockchain and caches immutable data
  final blockchainAdapter = BlockchainAdapterFactory.fromKey(
    key: blockfrostKey,
    networkId: NetworkId.testnet,
  ).adapter();

  final mnemonic0 =
      'army bid park alter aunt click border awake happy sport addict heavy robot change artist sniff height general dust fiber salon fan snack wheat';
  final hdWallet = HdWallet.fromMnemonic(mnemonic0);
  final Bip32SigningKey rootSigningKey = hdWallet.rootSigningKey;

  final walletBuilder = WalletBuilder()
    ..networkId = NetworkId.testnet
    ..testnetAdapterKey = blockfrostKey
    ..rootSigningKey = rootSigningKey;
  Result<Wallet, String> result = walletBuilder.build();
  Wallet wallet = result.unwrap();
  Coin oldBalance = wallet.balance;
  for (int i = 0; i < 20; i++) {
    sleep(Duration(seconds: 1));
    var result2 = await wallet.update();
    result2.when(
      ok: (changed) => print(
          "#$i: old:$oldBalance ADA, new: ${wallet.balance} ADA, changed: $changed"),
      err: (message) => print("Error: $message"),
    );
  }
  if (oldBalance >= 0) return;

  //build a read-only wallet from a staking address
  final stakeAddress = ShelleyAddress.fromBech32(
      'stake_test1uz425a6u2me7xav82g3frk2nmxhdujtfhmf5l275dr4a5jc3urkeg');
  final walletBuilder1 = WalletBuilder()
    ..walletName = 'Fred'
    ..blockchainAdapter = blockchainAdapter
    ..stakeAddress = stakeAddress;
  final Result<ReadOnlyWallet, String> result1 =
      await walletBuilder1.readOnlyBuildAndSync();
  result1.when(
    ok: (wallet) {
      print(
          "${wallet.walletName}'s balance: ${formatter.format(wallet.balance)}");
      for (final tx in wallet.transactions) {
        final type =
            tx.type == TransactionType.deposit ? 'deposit' : 'withdrawal';
        print("    $type ${tx.time} ${tx.amount} + ${tx.fees} fee");
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
    ..blockchainAdapter = blockchainAdapter
    ..mnemonic = mnemonic;
  final Result<Wallet, String> result2 = await walletBuilder2.buildAndSync();
  if (result2.isErr()) {
    print("Error: ${result2.unwrapErr()}");
    return;
  }
  final bobsWallet = result2.unwrap();
  print("${bobsWallet.walletName}'s: ${formatter.format(bobsWallet.balance)}");

  //create a new wallet
  final mnemonic2 = WalletBuilder.generateNewMnemonic();
  final walletBuilder3 = WalletBuilder()
    ..walletName = 'Alice'
    ..blockchainAdapter = blockchainAdapter
    ..mnemonic = mnemonic2;
  final Result<Wallet, String> result3 = await walletBuilder3.buildAndSync();
  if (result3.isErr()) {
    print("Error: ${result3.unwrapErr()}");
    return;
  }
  final alicesWallet = result3.unwrap();
  print(
      "${alicesWallet.walletName}'s: ${formatter.format(alicesWallet.balance)}");

  // Bob sends 2 ADA to Alice
  const lovelace = 2 * 1000000;
  final sendResult = await bobsWallet.sendAda(
    toAddress: alicesWallet.firstUnusedReceiveAddress,
    lovelace: lovelace,
    logTx: true,
    logTxHex: true,
  );
  sendResult.when(
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

final formatter = AdaFormattter.compactCurrency();
