///
/// Represents ADA amount in lovelace.
///
/// TODO migrate to BigInt in second beta release.
///
typedef Coin = int;

const Coin coinZero = 0;

/// Native Token policyId+coinName all in hex. Alternatly called 'unit'.
typedef AssetId = String;

/// String representation of bech32 address
typedef Bech32Address = String;

/// Hex encoded transaction hash ID
typedef TxIdHex = String;

/// Hex encoded block hash ID
typedef BlockHashHex = String;
