import 'package:blockfrost/blockfrost.dart';
import 'package:cardano_wallet_sdk/src/asset/asset.dart';
import 'package:cardano_wallet_sdk/src/transaction/transaction.dart';
import 'package:cardano_wallet_sdk/src/util/ada_types.dart';

///
/// The cache holds invariant block chain data.
///
abstract class BlockchainCache {
  RawTransaction? cachedTransaction(TxIdHex txId);
  Block? cachedBlock(BlockHashHex blockId);
  AccountContent? cachedAccountContent(Bech32Address stakeAddress); // TODO define AccountContent locally
  CurrencyAsset? cachedCurrencyAsset(String assetId);
}
