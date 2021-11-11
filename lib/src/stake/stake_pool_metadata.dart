// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

class StakePoolMetadata {
  /// URL to the stake pool metadata
  final String? url;

  /// Hash of the metadata file
  final String? hash;

  /// Ticker of the stake pool
  final String? ticker;

  /// Name of the stake pool
  final String? name;

  /// Description of the stake pool
  final String? description;

  /// Home page of the stake pool
  final String? homepage;

  StakePoolMetadata({
    this.url,
    this.hash,
    this.ticker,
    this.name,
    this.description,
    this.homepage,
  });
}
