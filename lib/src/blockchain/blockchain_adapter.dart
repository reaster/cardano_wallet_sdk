import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:cardano_wallet_sdk/src/address/shelley_address.dart';
import 'package:cardano_wallet_sdk/src/blockchain/blockchain_cache.dart';
import 'package:cardano_wallet_sdk/src/wallet/wallet_factory.dart';
import 'package:oxidized/oxidized.dart';

///
/// High-level abstraction to blockchain tailored towards balences and transactions.
///
abstract class BlockchainAdapter extends BlockchainCache {
  Future<Result<WalletUpdate, String>> updateWallet({required ShelleyAddress stakeAddress});
  Future<Result<Block, String>> latestBlock();
  Future<Result<String, String>> submitTransaction(List<int> cborTransaction);
}
