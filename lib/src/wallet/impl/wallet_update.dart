// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/src/address/shelley_address.dart';
import 'package:cardano_wallet_sdk/src/stake/stake_account.dart';
import 'package:cardano_wallet_sdk/src/transaction/transaction.dart';
import 'package:cardano_wallet_sdk/src/asset/asset.dart';
import 'package:cardano_wallet_sdk/src/util/ada_types.dart';

///
/// Pass-back object used to update existing or new wallets.
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
