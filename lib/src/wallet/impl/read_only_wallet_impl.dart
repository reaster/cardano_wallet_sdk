// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:quiver/strings.dart';
import 'package:oxidized/oxidized.dart';
import '../../address/shelley_address.dart';
import '../../asset/asset.dart';
import '../../network/network_id.dart';
import '../../stake/stake_account.dart';
import '../../transaction/transaction.dart';
import '../../blockchain/blockchain_adapter.dart';
import '../../util/ada_types.dart';
import '../read_only_wallet.dart';

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
  Map<String, Coin> get currencies =>
      transactions.map((t) => t.currencies).expand((m) => m.entries).fold(
          <String, Coin>{},
          (result, entry) =>
              result..[entry.key] = entry.value + (result[entry.key] ?? 0));

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

  /// used to track update in-progress and timeout conditions
  int _updateCalledTime = 0;

  /// Timeout on update call. Hard-coded to 2 minutes
  Duration get updateTimeout => const Duration(minutes: 2);

  @override
  Future<Result<bool, String>> update() async {
    if (_updateCalledTime != 0 && loadingTime < updateTimeout) {
      return Err('$walletName update already in progress');
    }
    _updateCalledTime = DateTime.now().millisecondsSinceEpoch;
    final result =
        await blockchainAdapter.updateWallet(stakeAddress: stakeAddress);
    if (result.isErr()) {
      _updateCalledTime = 0;
      return Err(result.unwrapErr());
    }
    bool changed = false;
    final update = result.unwrap();
    changed = refresh(
        balance: update.balance,
        transactions: update.transactions,
        usedAddresses: update.addresses,
        assets: update.assets,
        stakeAccounts: update.stakeAccounts);

    _updateCalledTime = 0; //reset timeout
    return Ok(changed);
  }

  @override
  Duration get loadingTime => _updateCalledTime == 0
      ? Duration.zero
      : Duration(
          milliseconds:
              DateTime.now().millisecondsSinceEpoch - _updateCalledTime);
}
