import 'package:cardano_wallet_sdk/src/address/shelley_address.dart';
import 'package:cardano_wallet_sdk/src/network/cardano_network.dart';
import 'package:cardano_wallet_sdk/src/stake/stake_account.dart';
import 'package:cardano_wallet_sdk/src/transaction/transaction.dart';
import 'package:cardano_wallet_sdk/src/wallet/impl/read_only_wallet_impl.dart';
import 'package:cardano_wallet_sdk/src/wallet/read_only_wallet.dart';
import 'package:oxidized/oxidized.dart';
import 'package:cardano_wallet_sdk/src/asset/asset.dart';

///
/// Creates wallets from keys.
///
/// Wallets arc cached and can be looked up from their stakingAddress.
///
///
abstract class WalletFactory {
  ///create Cardano wallet given a stakeAddress, networkId and optional wallet name.
  Future<Result<ReadOnlyWallet, String>> createReadOnlyWallet(
      {required ShelleyAddress stakeAddress, String? walletName});

  ///update existing wallet
  Future<Result<bool, String>> updateWallet({required ReadOnlyWalletImpl wallet});

  ///lookup cached wallet by stakingAddress
  ReadOnlyWallet? byStakeAddress(String stakeAddress);

  ///lookup CardanoNetwork metadata given NetworkId.
  Map<NetworkId, CardanoNetwork> get networkMap;
}

///
/// data object allowing existing or new wallet to be updated
///
class WalletUpdate {
  final int balance;
  final List<Transaction> transactions;
  final List<ShelleyAddress> addresses;
  final Map<String, CurrencyAsset> assets;
  final List<StakeAccount> stakeAccounts;
  WalletUpdate({
    required this.balance,
    required this.transactions,
    required this.addresses,
    required this.assets,
    required this.stakeAccounts,
  });
}

///
/// Binds a data API to wallet model
///
abstract class WalletServiceAdapter {
  Future<Result<WalletUpdate, String>> updateWallet({required ShelleyAddress stakeAddress});
}
