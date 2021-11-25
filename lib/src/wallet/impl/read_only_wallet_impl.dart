// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/src/address/shelley_address.dart';
import 'package:cardano_wallet_sdk/src/asset/asset.dart';
import 'package:cardano_wallet_sdk/src/network/network_id.dart';
import 'package:cardano_wallet_sdk/src/stake/stake_account.dart';
import 'package:cardano_wallet_sdk/src/transaction/transaction.dart';
import 'package:cardano_wallet_sdk/src/blockchain/blockchain_adapter.dart';
import 'package:cardano_wallet_sdk/src/wallet/read_only_wallet.dart';
import 'package:oxidized/oxidized.dart';
import 'package:quiver/strings.dart';
import 'package:cardano_wallet_sdk/src/util/ada_types.dart';

///
/// Given a stakingAddress, generate a read-only wallet with balances of all native assets,
/// transaction history, staking and reward history.
///
class ReadOnlyWalletImpl implements ReadOnlyWallet {
  @override
  final NetworkId networkId;
  @override
  final ShelleyAddress stakeAddress;
  @override
  final String walletName;
  @override
  final BlockchainAdapter blockchainAdapter;
  int _balance = 0;
  List<WalletTransaction> _transactions = [];
  List<ShelleyAddress> _usedAddresses = [];
  //List<Utxo> utxos = [];
  Map<String, CurrencyAsset> _assets = {};
  List<StakeAccount> _stakeAccounts = [];

  ReadOnlyWalletImpl(
      {required this.blockchainAdapter,
      required this.stakeAddress,
      required this.walletName})
      : networkId = stakeAddress.toBech32().startsWith('stake_test')
            ? NetworkId.testnet
            : NetworkId.mainnet;

  @override
  Map<String, Coin> get currencies {
    return transactions.map((t) => t.currencies).expand((m) => m.entries).fold(
        <String, Coin>{},
        (result, entry) =>
            result..[entry.key] = entry.value + (result[entry.key] ?? 0));
  }

  @override
  Coin get calculatedBalance {
    final Coin rewardsSum = stakeAccounts
        .map((s) => s.withdrawalsSum)
        .fold(0, (p, c) => p + c); //TODO figure out the math
    final Coin lovelaceSum = currencies[lovelaceHex] as Coin;
    final result = lovelaceSum + rewardsSum;
    return result;
  }

  @override
  bool refresh({
    required Coin balance,
    required List<ShelleyAddress> usedAddresses,
    required List<RawTransaction> transactions,
    required Map<String, CurrencyAsset> assets,
    required List<StakeAccount> stakeAccounts,
  }) {
    bool change = false;
    if (_assets.length != assets.length) {
      change = true;
      _assets = assets;
    }
    if (_balance != balance) {
      change = true;
      _balance = balance;
    }
    if (_usedAddresses.length != usedAddresses.length) {
      change = true;
      _usedAddresses = usedAddresses;
    }
    if (_transactions.length != transactions.length) {
      change = true;
      //swap raw transactions for wallet-centric transactions:
      _transactions = transactions
          .map((t) => WalletTransactionImpl(
              rawTransaction: t, addressSet: _usedAddresses.toSet()))
          .toList();
    }
    if (_stakeAccounts.length != stakeAccounts.length) {
      change = true;
      _stakeAccounts = stakeAccounts;
    }
    return change;
  }

  @override
  WalletId get walletId => stakeAddress.toBech32();

  @override
  bool get readOnly => true;

  @override
  List<ShelleyAddress> get addresses => _usedAddresses;

  @override
  String toString() => "Wallet(name: $walletName, balance: $balance lovelace)";

  @override
  Coin get balance => _balance;

  @override
  List<WalletTransaction> get transactions => _transactions;

  @override
  Map<String, CurrencyAsset> get assets => _assets;

  @override
  List<StakeAccount> get stakeAccounts => _stakeAccounts;

  @override
  List<WalletTransaction> filterTransactions({required String assetId}) =>
      transactions.where((t) => t.containsCurrency(assetId: assetId)).toList();

  @override
  CurrencyAsset? findAssetByTicker(String ticker) =>
      findAssetWhere((a) => equalsIgnoreCase(a.metadata?.ticker, ticker));

  @override
  CurrencyAsset? findAssetWhere(bool Function(CurrencyAsset asset) matcher) =>
      _assets.values.firstWhere(matcher);

  @override
  List<WalletTransaction> get unspentTransactions => transactions
      .where((tx) => tx.status == TransactionStatus.unspent)
      .toList();

  @override
  Future<Result<bool, String>> update() async {
    final result =
        await blockchainAdapter.updateWallet(stakeAddress: stakeAddress);
    bool changed = false;
    result.when(
      ok: (update) {
        changed = refresh(
            balance: update.balance,
            transactions: update.transactions,
            usedAddresses: update.addresses,
            assets: update.assets,
            stakeAccounts: update.stakeAccounts);
      },
      err: (err) {
        return Err(err);
      },
    );
    return Ok(changed);
  }
}
