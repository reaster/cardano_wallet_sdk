// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import './stake_pool.dart';
import './stake_pool_metadata.dart';

// '["active",true,"active_epoch",135,"controlled_amount","398515694","rewards_sum","690831","withdrawals_sum","0","reserves_sum","0","treasury_sum","0","withdrawable_amount","690831","pool_id","pool14pdhhugxlqp9vta49pyfu5e2d5s82zmtukcy9x5ylukpkekqk8l"]',

class StakeAccount {
  /// Registration state of an account
  final bool active;

  /// Epoch of the most recent action - registration or deregistration
  final int? activeEpoch;

  /// Balance of the account in Lovelaces
  final int controlledAmount;

  /// Sum of all rewards for the account in the Lovelaces
  final int rewardsSum;

  /// Sum of all the withdrawals for the account in Lovelaces
  final int withdrawalsSum;

  /// Sum of all funds from reserves for the account in the Lovelaces
  final int reservesSum;

  /// Sum of all funds from treasury for the account in the Lovelaces
  final int treasurySum;

  /// Sum of available rewards that haven't been withdrawn yet for the account in the Lovelaces
  final int withdrawableAmount;

  /// Bech32 pool ID that owns the account
  final String? poolId;

  /// name, url, ticker, etc.
  final StakePoolMetadata? poolMetadata;

  /// stake pool details
  final StakePool? stakePool;

  final List<StakeReward> rewards;

  StakeAccount({
    required this.active,
    this.activeEpoch,
    required this.controlledAmount,
    required this.rewardsSum,
    required this.withdrawalsSum,
    required this.reservesSum,
    required this.treasurySum,
    required this.withdrawableAmount,
    this.poolId,
    this.poolMetadata,
    this.stakePool,
    required this.rewards,
  });

  // Account({
  //   required this.policyId,
  //   required this.assetName,
  //   String? fingerprint,
  //   required this.quantity,
  //   required this.initialMintTxHash,
  //   this.metadata,
  // })  : this.assetId = '$policyId$assetName',
  //       this.name = hex2str.encode(assetName), //if assetName is not hex, this will usualy fail
  //       this.fingerprint = fingerprint ?? calculateFingerlogger.i(policyId: policyId, assetNameHex: assetName);

}

class StakeReward {
  /// epoch reward was paid in
  final int epoch;

  /// amount of reward in lovelace
  final int amount;

  /// stake pool ID
  final String poolId;

  StakeReward(
      {required this.epoch, required this.amount, required this.poolId});
}
