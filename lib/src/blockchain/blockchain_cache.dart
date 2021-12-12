// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:blockfrost/blockfrost.dart';
import '../asset/asset.dart';
import '../transaction/transaction.dart';
import '../util/ada_types.dart';

///
/// The cache holds invariant block chain data.
///
abstract class BlockchainCache {
  RawTransaction? cachedTransaction(TxIdHex txId);
  Block? cachedBlock(BlockHashHex blockId);
  AccountContent? cachedAccountContent(
      Bech32Address stakeAddress); // TODO define AccountContent locally
  CurrencyAsset? cachedCurrencyAsset(String assetId);
}
