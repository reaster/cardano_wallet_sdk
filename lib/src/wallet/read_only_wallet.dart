// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:oxidized/oxidized.dart';
import '../address/shelley_address.dart';
import '../asset/asset.dart';
import '../blockchain/blockchain_adapter.dart';
import '../network/network_id.dart';
import '../stake/stake_account.dart';
import '../transaction/transaction.dart';
import '../util/ada_types.dart';

///
/// Cardano read-only wallet that holds transactions, staking rewards and their associated
/// addresses.  A public, read-ony wallet can be built given a stakingAddress and a networkId.
/// All blockchain data retrieval is delegated to the BlockchainAdapter.
///
abstract class ReadOnlyWallet {
  /// Return walletId. ID is public staking address for Shelley wallets.
  WalletId get walletId;

  /// networkId is either mainnet or nestnet
  NetworkId get networkId;

  /// return true if this is read-only wallet that can't sign transactions and send funds.
  bool get readOnly;

  /// name of wallet
  String get walletName;

  /// balance of wallet in lovelace
  Coin get balance;

  /// calculate balance from transactions and rewards
  Coin get calculatedBalance;

  /// balances of native tokens indexed by assetId
  Map<AssetId, Coin> get currencies;

  /// optional stake pool details
  List<StakeAccount> get stakeAccounts;

  /// staking address
  ShelleyAddress get stakeAddress;

  /// access to the bockchain
  BlockchainAdapter get blockchainAdapter;

  /// assets present in this wallet indexed by assetId
  Map<AssetId, CurrencyAsset> get assets;
  List<WalletTransaction> get transactions;
  List<WalletTransaction> get unspentTransactions;
  List<WalletTransaction> filterTransactions({required AssetId assetId});
  List<ShelleyAddress> get addresses;
  bool refresh(
      {required int balance,
      required List<RawTransaction> transactions,
      required List<ShelleyAddress> usedAddresses,
      required Map<String, CurrencyAsset> assets,
      required List<StakeAccount> stakeAccounts});

  CurrencyAsset? findAssetWhere(bool Function(CurrencyAsset asset) matcher);
  CurrencyAsset? findAssetByTicker(String ticker);

  /// Duration since update was called. Set to zero when update completes.
  Duration get loadingTime;

  /// Update or sync wallet transactions with blockchain. Return true if data changed.
  /// Is ignored if loadingTime is not zero.
  Future<Result<bool, String>> update();
}
