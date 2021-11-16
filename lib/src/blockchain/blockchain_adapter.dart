// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/src/address/shelley_address.dart';
import 'package:cardano_wallet_sdk/src/blockchain/blockchain_cache.dart';
import 'package:cardano_wallet_sdk/src/transaction/min_fee_function.dart';
import 'package:cardano_wallet_sdk/src/transaction/transaction.dart';
import 'package:cardano_wallet_sdk/src/wallet/impl/wallet_update.dart';
import 'package:oxidized/oxidized.dart';
import 'dart:typed_data';

///
/// High-level abstraction to blockchain tailored towards balences and transactions.
///
abstract class BlockchainAdapter extends BlockchainCache {
  /// Collects the latest transactions for the wallet given it's staking address.
  Future<Result<WalletUpdate, String>> updateWallet(
      {required ShelleyAddress stakeAddress});

  /// Returns last latest Block instance from blockchain if successful.
  Future<Result<Block, String>> latestBlock();

  /// Submit ShelleyTransaction encoded as CBOR. Returns hex transaction ID if successful.
  Future<Result<String, String>> submitTransaction(Uint8List cborTransaction);

  /// Return the fee parameters for the given epoch number or the latest epoch if no number supplied.
  Future<Result<LinearFee, String>> latestEpochParameters(
      {int epochNumber = 0});
}
