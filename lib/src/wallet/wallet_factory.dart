import 'package:bip32_ed25519/api.dart';
import 'package:cardano_wallet_sdk/src/address/hd_wallet.dart';
import 'package:cardano_wallet_sdk/src/address/shelley_address.dart';
import 'package:cardano_wallet_sdk/src/stake/stake_account.dart';
import 'package:cardano_wallet_sdk/src/transaction/transaction.dart';
import 'package:cardano_wallet_sdk/src/wallet/impl/read_only_wallet_impl.dart';
import 'package:cardano_wallet_sdk/src/wallet/read_only_wallet.dart';
import 'package:cardano_wallet_sdk/src/wallet/wallet.dart';
import 'package:oxidized/oxidized.dart';
import 'package:cardano_wallet_sdk/src/asset/asset.dart';
import 'package:cardano_wallet_sdk/src/util/ada_types.dart';

///
/// Creates wallets from keys.
///
/// Wallets arc cached and can be looked up from their stakingAddress.
///
///
abstract class WalletFactory {
  ///Create Cardano wallet given a 24 word mnemonic and optional wallet name.
  ///If load is true, wallet will sync with blockchain.
  Future<Result<Wallet, String>> createWalletFromMnemonic({
    required List<String> mnemonic,
    String? walletName,
    bool load = true,
  });

  ///create Cardano wallet given a private key and optional wallet name.
  ///If load is true, wallet will sync with blockchain.
  Future<Result<Wallet, String>> createWalletFromPrivateKey({
    required Bip32SigningKey rootSigningKey,
    String? walletName,
    bool load = true,
  });

  ///Create Cardano wallet given a HdWallet instance and optional wallet name.
  ///If load is true, wallet will sync with blockchain.
  Future<Result<Wallet, String>> createWallet({
    required HdWallet hdWallet,
    String? walletName,
    bool load = true,
  });

  ///create Cardano wallet given a stakeAddress, networkId and optional wallet name.
  ///If load is true, wallet will sync with blockchain.
  Future<Result<ReadOnlyWallet, String>> createReadOnlyWallet({
    required ShelleyAddress stakeAddress,
    String? walletName,
    bool load = true,
  });

  ///update existing wallet by syncing with blockchain.
  Future<Result<bool, String>> updateWallet({required ReadOnlyWalletImpl wallet});

  ///lookup cached wallet by stakingAddress
  ReadOnlyWallet? byStakeAddress(String stakeAddress);

  ///generate mnumonic words to be used by new wallet.
  List<String> generateNewMnemonic();
}

///
/// data object allowing existing or new wallet to be updated
///
class WalletUpdate {
  final Coin balance;
  final List<RawTransaction> transactions;
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
