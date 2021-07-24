import 'package:cardano_wallet_sdk/src/address/shelley_address.dart';
import 'package:cardano_wallet_sdk/src/asset/asset.dart';
import 'package:cardano_wallet_sdk/src/network/cardano_network.dart';
import 'package:cardano_wallet_sdk/src/stake/stake_account.dart';
import 'package:cardano_wallet_sdk/src/transaction/transaction.dart';
import 'package:quiver/strings.dart';

enum TransactionQueryType { all, used, unused }

///
/// public Cardano wallet holding stakingAddress and associated public tranaction addresses.
///
abstract class PublicWallet {
  /// networkId is either mainnet or nestnet
  NetworkId get networkId;

  /// name of wallet
  String get walletName;

  /// balance of wallet in lovelace
  int get balance;

  /// calculate balance from transactions and rewards
  int get calculatedBalance;

  /// balances of native tokens indexed by assetId
  Map<String, int> get currencies;

  /// optional stake pool details
  List<StakeAccount> get stakeAccounts;

  /// assets present in this wallet indexed by assetId
  Map<String, CurrencyAsset> get assets;
  List<WalletTransaction> get transactions;
  List<WalletTransaction> filterTransactions({required String assetId});
  List<ShelleyAddress> addresses({TransactionQueryType type = TransactionQueryType.all});
  bool refresh(
      {required int balance,
      required List<Transaction> transactions,
      required List<ShelleyAddress> usedAddresses,
      required Map<String, CurrencyAsset> assets,
      required List<StakeAccount> stakeAccounts});

  CurrencyAsset? findAssetWhere(bool Function(CurrencyAsset asset) matcher);
  CurrencyAsset? findAssetByTicker(String ticker);
}

class PublicWalletImpl implements PublicWallet {
  final NetworkId networkId;
  final String stakeAddress;
  final String walletName;
  int _balance = 0;
  List<WalletTransaction> _transactions = [];
  List<ShelleyAddress> _usedAddresses = [];
  Map<String, CurrencyAsset> _assets = {};
  List<StakeAccount> _stakeAccounts = [];

  PublicWalletImpl({required this.stakeAddress, required this.walletName})
      : this.networkId = stakeAddress.startsWith('stake_test') ? NetworkId.testnet : NetworkId.mainnet;

  @override
  Map<String, int> get currencies {
    return transactions
        .map((t) => t.currencies)
        .expand((m) => m.entries)
        .fold(<String, int>{}, (result, entry) => result..[entry.key] = entry.value + (result[entry.key] ?? 0));
  }

  @override
  int get calculatedBalance {
    final int rewardsSum = stakeAccounts.map((s) => s.withdrawalsSum).fold(0, (p, c) => p + c); //TODO figure out the math
    final int lovelaceSum = currencies[lovelaceHex] as int;
    final result = lovelaceSum + rewardsSum;
    return result;
  }

  @override
  bool refresh({
    required int balance,
    required List<ShelleyAddress> usedAddresses,
    required List<Transaction> transactions,
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
      final Set<String> addressSet = usedAddresses.map((a) => a.toBech32()).toSet();
      this._transactions = transactions.map((t) => WalletTransactionImpl(baseTransaction: t, addressSet: addressSet)).toList();
    }
    if (this._stakeAccounts.length != stakeAccounts.length) {
      change = true;
      this._stakeAccounts = stakeAccounts;
    }
    return change;
  }

  @override
  List<ShelleyAddress> addresses({TransactionQueryType type = TransactionQueryType.all}) => _usedAddresses;

  @override
  String toString() => "Wallet(name: $walletName, balance: $balance lovelace)";

  @override
  int get balance => _balance;

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
  CurrencyAsset? findAssetByTicker(String ticker) => findAssetWhere((a) => equalsIgnoreCase(a.metadata?.ticker, ticker));

  @override
  CurrencyAsset? findAssetWhere(bool Function(CurrencyAsset asset) matcher) => _assets.values.firstWhere(matcher);
}
