// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import '../../address/shelley_address.dart';
import '../../stake/stake_account.dart';
import '../../transaction/transaction.dart';
import '../../asset/asset.dart';
import '../../util/ada_types.dart';

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
