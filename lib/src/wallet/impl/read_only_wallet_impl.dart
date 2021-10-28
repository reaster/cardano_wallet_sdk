import 'package:cardano_wallet_sdk/src/address/shelley_address.dart';
import 'package:cardano_wallet_sdk/src/asset/asset.dart';
import 'package:cardano_wallet_sdk/src/network/network_id.dart';
import 'package:cardano_wallet_sdk/src/stake/stake_account.dart';
import 'package:cardano_wallet_sdk/src/transaction/transaction.dart';
import 'package:cardano_wallet_sdk/src/blockchain/blockchain_adapter.dart';
import 'package:cardano_wallet_sdk/src/wallet/read_only_wallet.dart';
import 'package:quiver/strings.dart';
import 'package:cardano_wallet_sdk/src/util/ada_types.dart';

///
/// Given a stakingAddress, generate a read-only wallet with balances of all native assets,
/// transaction history, staking and reward history.
///
class ReadOnlyWalletImpl implements ReadOnlyWallet {
  final NetworkId networkId;
  final ShelleyAddress stakeAddress;
  final String walletName;
  final BlockchainAdapter blockchainAdapter;
  int _balance = 0;
  List<WalletTransaction> _transactions = [];
  List<ShelleyAddress> _usedAddresses = [];
  //List<Utxo> utxos = [];
  Map<String, CurrencyAsset> _assets = {};
  List<StakeAccount> _stakeAccounts = [];

  ReadOnlyWalletImpl({required this.blockchainAdapter, required this.stakeAddress, required this.walletName})
      : this.networkId = stakeAddress.toBech32().startsWith('stake_test') ? NetworkId.testnet : NetworkId.mainnet;

  @override
  Map<String, Coin> get currencies {
    return transactions
        .map((t) => t.currencies)
        .expand((m) => m.entries)
        .fold(<String, Coin>{}, (result, entry) => result..[entry.key] = entry.value + (result[entry.key] ?? 0));
  }

  @override
  Coin get calculatedBalance {
    final Coin rewardsSum =
        stakeAccounts.map((s) => s.withdrawalsSum).fold(0, (p, c) => p + c); //TODO figure out the math
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
    if (this._assets.length != assets.length) {
      change = true;
      this._assets = assets;
    }
    if (this._balance != balance) {
      change = true;
      this._balance = balance;
    }
    if (this._usedAddresses.length != usedAddresses.length) {
      change = true;
      this._usedAddresses = usedAddresses;
    }
    if (this._transactions.length != transactions.length) {
      change = true;
      //swap raw transactions for wallet-centric transactions:
      this._transactions = transactions
          .map((t) => WalletTransactionImpl(rawTransaction: t, addressSet: _usedAddresses.toSet()))
          .toList();
    }
    if (this._stakeAccounts.length != stakeAccounts.length) {
      change = true;
      this._stakeAccounts = stakeAccounts;
    }
    return change;
  }

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
  CurrencyAsset? findAssetWhere(bool Function(CurrencyAsset asset) matcher) => _assets.values.firstWhere(matcher);

  @override
  List<WalletTransaction> get unspentTransactions =>
      transactions.where((tx) => tx.status == TransactionStatus.unspent).toList();
}
