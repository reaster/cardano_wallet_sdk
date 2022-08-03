// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import '../address/shelley_address.dart';

///
/// Provides a type-safe, abstract representation of BIP-44 tree path chain.
///
/// BIP-44 path:
///     m / purpose' / coin_type' / account_ix' / change_chain / address_ix
///
/// BIP32-ED25519 Cardano adoption:
///     m / 1852' / 1851' / account' / role / index
///
class HdDerivationChain {
  final String key;
  final List<HdSegment> segments;

  const HdDerivationChain._({required this.key, required this.segments})
      : assert(key == 'm' || key == 'M');

  /// Private key tree chain constructor
  const HdDerivationChain.m({required List<HdSegment> segments})
      : this._(key: 'm', segments: segments);

  /// Public key tree chain constructor
  const HdDerivationChain.M({required List<HdSegment> segments})
      : this._(key: 'M', segments: segments);

  factory HdDerivationChain.fromPath(String path, {int? segmentLength}) =>
      path.startsWith('m')
          ? HdDerivationChain.m(
              segments: parsePath(path, segmentLength: segmentLength))
          : path.startsWith('M')
              ? HdDerivationChain.M(
                  segments: parsePath(path, segmentLength: segmentLength))
              : throw InvalidChainError(
                  "DerivationChain ($path) must start with 'm' or 'M'");

  static List<HdSegment> parsePath(String path, {int? segmentLength}) {
    List<HdSegment> segments = [];
    final tokens = path.split('/');
    segmentLength ??= tokens.length - 1;
    if (segmentLength != tokens.length - 1) {
      throw InvalidChainError(
          "path ($path) must have $segmentLength segments, not ${tokens.length - 1}");
    }
    for (int i = 0; i < tokens.length; i++) {
      if (i > 0) {
        //ignore 0 key segment
        final harden = tokens[i].endsWith('\'');
        final seg =
            tokens[i].substring(0, tokens[i].length + (harden ? -1 : 0));
        final depth = HdSegment.checkDepthBounds(int.parse(seg));
        segments.add(HdSegment(depth: depth, harden: harden));
      }
    }
    return segments;
  }

  HdDerivationChain append(HdSegment tail) =>
      HdDerivationChain._(key: key, segments: [...segments, tail]);

  HdDerivationChain append2(HdSegment tail1, HdSegment tail2) =>
      HdDerivationChain._(key: key, segments: [...segments, tail1, tail2]);

  HdDerivationChain swapTail(HdSegment tail) => HdDerivationChain._(
      key: key, segments: [...segments.take(segments.length - 1), tail]);

  /// increment the last value in the chain by one.
  HdDerivationChain inc() => HdDerivationChain._(
      key: key,
      segments: segments.isEmpty
          ? []
          : [...segments.take(segments.length - 1), segments.last.inc()]);

  /// return BIP32 path string representation
  String toPath() => "$key/${segments.join('/')}";

  @override
  String toString() => toPath();

  @override
  int get hashCode => toPath().hashCode;

  @override
  bool operator ==(Object other) {
    bool isEq = identical(this, other) ||
        other is HdDerivationChain && runtimeType == other.runtimeType;
    if (!isEq) return false;
    return toString() == other.toString();
  }

  bool get isPrivateRoot => key == _privateKeyPrefix;
  bool get isPublicRoot => key == _publicKeyPrefix;

  /// number of segments not incuding key
  int get length => segments.length;

  static const _privateKeyPrefix = 'm';
  static const _publicKeyPrefix = 'M';
  // static const _legalPrefixes = [_privateKeyPrefix, _publicKeyPrefix];
}

class InvalidChainError extends Error {
  final String message;
  InvalidChainError(this.message);
  @override
  String toString() => message;
}

/// BIP32-ED25519 tree level segment
class HdSegment {
  /// The maximum BIP32-ED25519 depth of zero-based tree is 2^20 -1 or 1048576 - 1.
  static const int maxDepth = 1048576 - 1;

  /// zero-based tree depth
  final int depth;

  /// true if is a hardened value
  final bool harden;

  const HdSegment({required this.depth, this.harden = false});

  /// check valid bounds, throw InvalidChainError on failure.
  static int checkDepthBounds(int depth) {
    if (depth < 0 || depth > maxDepth) {
      throw InvalidChainError(
          "depth outside valid range [0..$maxDepth]: $depth");
    }
    return depth;
  }

  /// return depth, adding hardenedOffset if applicable
  int get value => harden ? depth | hardenedOffset : depth;
  @override
  String toString() => "$depth${harden ? '\'' : ''}";
  HdSegment inc() => HdSegment(depth: depth + 1, harden: harden);
}

const cip1852 = HdSegment(depth: 1852, harden: true);
const cip1815 = HdSegment(depth: 1815, harden: true);
const spendRole = HdSegment(depth: 0); //external
const changeRole = HdSegment(depth: 1); //internal
const stakeRole = HdSegment(depth: 2); //reward
const zeroSoft = HdSegment(depth: 0); //generic zero index not hardened
const zeroHard =
    HdSegment(depth: 0, harden: true); //generic zero index hardened

/// Cardano adoption of BIP-44 path:
///     m / 1852' / 1851' / account' / role / index
// not sure this is needed or useful
// class CIP1852Path extends DerivationChain {
//   CIP1852Path({
//     required key,
//     required Segment purpose,
//     required Segment coinType,
//     required Segment account,
//     required Segment role,
//     required Segment index,
//   }) : super(key: key, segments: [purpose, coinType, account, role, index]);

//   factory CIP1852Path.fromPath(String path) =>
//       DerivationChain.fromPath(path, segmentLength: 5) as CIP1852Path;
//   Segment get purpose => segments[0];
//   Segment get coinType => segments[1];
//   Segment get account => segments[2];
//   Segment get role => segments[3];
//   Segment get index => segments[4];
// }

/// Hardended chain values should not have public keys.
/// They are denoted by a single quote in chain values.
const int hardenedOffset = 0x80000000;

/// Default purpose. The year Ada Lovelace passed away.
/// Reference: [CIP-1852](https://github.com/cardano-foundation/CIPs/blob/master/CIP-1852/CIP-1852.md)
// const int defaultPurpose = 1852 | hardenedOffset;

/// Coin-type for Cardano ADA. Ada Lovelace's year of birth.
// const int defaultCoinType = 1815 | hardenedOffset;

/// Is zero. This returns the base account address.
// const int defaultAccountIndex = 0 | hardenedOffset;

/// role 0=external/payments
//const int paymentRole = 0;

/// role 1=internal/change
//const int changeRole = 1;

/// role 2=staking
//const int stakingRoleIndex = 2;
//const int defaultAddressIndex = 0;

/// Extended private key size in bytes
const cip16ExtendedSigningKeySize = 96;

/// Extended public key size in bytes
const cip16ExtendedVerificationgKeySize = 64;

/// Hardens index, meaning it won't have a public key
int harden(int index) => index | hardenedOffset;

/// Returns true if index is hardened.
bool isHardened(int index) => index & hardenedOffset != 0;

/// Function used to test address usage. Returns true if it has been used in a transaction.
typedef UsedAddressFunction = bool Function(ShelleyAddress address);

/// UsedAddressFunction that will always return false (i.e. You'll always get the base spend/change address).
bool alwaysUsed(_) => false;
