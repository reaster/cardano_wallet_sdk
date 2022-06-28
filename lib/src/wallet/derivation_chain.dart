import '../address/shelley_address.dart';

class DerivationChain {
  final String key;
  final List<Segment> segments;

  const DerivationChain({required this.key, required this.segments});

  DerivationChain.segments(this.key, Segment? seg1, Segment? seg2,
      Segment? seg3, Segment? seg4, Segment? seg5)
      : segments = [
          if (seg1 != null) seg1,
          if (seg2 != null) seg2,
          if (seg3 != null) seg3,
          if (seg4 != null) seg4,
          if (seg5 != null) seg5
        ];

  factory DerivationChain.fromPath(String path, {int? segmentLength}) =>
      DerivationChain(
          key: parseKey(path),
          segments: parsePath(path, segmentLength: segmentLength));

  static String parseKey(String path) {
    final key = path.substring(0, 1);
    if (!_legalPrefixes.contains(key)) {
      throw ArgumentError("DerivationChain must start with 'm' or 'M'", path);
    }
    return key;
  }

  static List<Segment> parsePath(String path, {int? segmentLength}) {
    List<Segment> segments = [];
    final tokens = path.split('/');
    segmentLength ??= tokens.length - 1;
    if (segmentLength != tokens.length - 1) {
      throw ArgumentError(
          "path must have $segmentLength segments, not ${tokens.length - 1}",
          path);
    }
    for (int i = 0; i < tokens.length; i++) {
      if (i > 0) {
        //ignore 0 key segment
        final harden = tokens[i].endsWith('\'');
        final seg =
            tokens[i].substring(0, tokens[i].length + (harden ? -1 : 0));
        final value = int.parse(seg);
        segments.add(Segment(index: value, harden: harden));
      }
    }
    return segments;
  }

  DerivationChain append(Segment tail) =>
      DerivationChain(key: key, segments: [...segments, tail]);
  DerivationChain append2(Segment tail1, Segment tail2) =>
      DerivationChain(key: key, segments: [...segments, tail1, tail2]);
  DerivationChain swapTail(Segment tail) => DerivationChain(
      key: key, segments: [...segments.take(segments.length - 1), tail]);

  /// increment the last value in the chain by one.
  DerivationChain inc() => DerivationChain(
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
        other is DerivationChain && runtimeType == other.runtimeType;
    if (!isEq) return false;
    return toString() == other.toString();
  }

  bool get isPrivateRoot => key == _privateKeyPrefix;
  bool get isPublicRoot => key == _publicKeyPrefix;

  /// number of segments not incuding key
  int get length => segments.length;

  static const _privateKeyPrefix = 'm';
  static const _publicKeyPrefix = 'M';
  static const _legalPrefixes = [_privateKeyPrefix, _publicKeyPrefix];
}

class Segment {
  final int index;
  final bool harden;
  const Segment({required this.index, this.harden = false});
  int get value => harden ? index | hardenedOffset : index;
  @override
  String toString() => "$index${harden ? '\'' : ''}";
  Segment inc() => Segment(index: index + 1, harden: harden);
}

const cip1852 = Segment(index: 1852, harden: true);
const cip1815 = Segment(index: 1815, harden: true);
const spendRole = Segment(index: 0); //external
const changeRole = Segment(index: 1); //internal
const stakeRole = Segment(index: 2); //reward
const zeroSoft = Segment(index: 0); //generic zero index not hardened
const zeroHard = Segment(index: 0, harden: true); //generic zero index hardened

/// Cardano adoption of BIP-44 path:
///     m / 1852' / 1851' / account' / role / index
// @Deprecated('not sure this is needed or useful')
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

/// Function used to test address usage. Returns true if it has not been used in a transaction.
typedef UnusedAddressFunction = bool Function(ShelleyAddress address);

/// UnusedAddressFunction that will always return true (i.e. You'll always get the base spend/change address).
bool alwaysUnused(_) => true;
