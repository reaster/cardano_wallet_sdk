// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

class StakePool {
  /// VRF key hash
  final String vrfKey;

  /// Total minted blocks
  final int blocksMinted;

  final String liveStake;

  final num liveSize;

  final num liveSaturation;

  final num liveDelegators;

  final String activeStake;

  final num activeSize;

  /// Stake pool certificate pledge
  final String declaredPledge;

  /// Stake pool current pledge
  final String livePledge;

  /// Margin tax cost of the stake pool
  final num marginCost;

  /// Fixed tax cost of the stake pool
  final String fixedCost;

  /// Bech32 reward account of the stake pool
  final String rewardAccount;

  final List<String> owners;

  final List<String> registration;

  final List<String> retirement;

  StakePool({
    required this.vrfKey,
    required this.blocksMinted,
    required this.liveStake,
    required this.liveSize,
    required this.liveSaturation,
    required this.liveDelegators,
    required this.activeStake,
    required this.activeSize,
    required this.declaredPledge,
    required this.livePledge,
    required this.marginCost,
    required this.fixedCost,
    required this.rewardAccount,
    required this.owners,
    required this.registration,
    required this.retirement,
  });
}
