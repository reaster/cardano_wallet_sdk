import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:cardano_wallet_sdk/src/address/hd_wallet.dart';
import 'package:cardano_wallet_sdk/src/address/shelley_address.dart';
import 'package:cardano_wallet_sdk/src/wallet/read_only_wallet.dart';
import 'package:oxidized/oxidized.dart';
import 'package:cardano_wallet_sdk/src/util/ada_types.dart';

///
/// Extend ReadOnlyWallet with transactional capabilities.
///
abstract class Wallet extends ReadOnlyWallet {
  HdWallet get hdWallet;
  Bip32KeyPair get rootKeyPair;
  ShelleyAddress get firstUnusedSpendAddress;
  ShelleyAddress get firstUnusedChangeAddress;
  Future<Result<ShelleyTransaction, String>> sendAda({required ShelleyAddress toAddress, required Coin lovelaceAmount});
}
