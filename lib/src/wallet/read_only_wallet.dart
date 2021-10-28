import 'package:cardano_wallet_sdk/src/address/shelley_address.dart';
import 'package:cardano_wallet_sdk/src/asset/asset.dart';
import 'package:cardano_wallet_sdk/src/network/network_id.dart';
import 'package:cardano_wallet_sdk/src/stake/stake_account.dart';
import 'package:cardano_wallet_sdk/src/transaction/transaction.dart';
import 'package:cardano_wallet_sdk/src/util/ada_types.dart';

enum TransactionQueryType { all, used, unused }

///
/// public Cardano wallet holding stakingAddress and associated public tranaction addresses.
///
abstract class ReadOnlyWallet {
  /// networkId is either mainnet or nestnet
  NetworkId get networkId;

  /// name of wallet
  String get walletName;

  /// balance of wallet in lovelace
  Coin get balance;

  /// calculate balance from transactions and rewards
  Coin get calculatedBalance;

  /// balances of native tokens indexed by assetId
  Map<String, Coin> get currencies;

  /// optional stake pool details
  List<StakeAccount> get stakeAccounts;

  /// staking address
  ShelleyAddress get stakeAddress;

  /// assets present in this wallet indexed by assetId
  Map<String, CurrencyAsset> get assets;
  List<WalletTransaction> get transactions;
  List<WalletTransaction> get unspentTransactions;
  List<WalletTransaction> filterTransactions({required String assetId});
  List<ShelleyAddress> get addresses;
  bool refresh(
      {required int balance,
      required List<RawTransaction> transactions,
      required List<ShelleyAddress> usedAddresses,
      required Map<String, CurrencyAsset> assets,
      required List<StakeAccount> stakeAccounts});

  CurrencyAsset? findAssetWhere(bool Function(CurrencyAsset asset) matcher);
  CurrencyAsset? findAssetByTicker(String ticker);
}
