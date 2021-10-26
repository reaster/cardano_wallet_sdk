///
/// Represents ADA amount in lovelace.
///
/// TODO migrate to BigInt in second beta release.
///
typedef Coin = int;

const Coin coinZero = 0;

/// Native Token policyId+coinName. Alternatly called 'unit'.
typedef AssetId = String;
