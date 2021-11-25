// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

///
/// Represents ADA amount in lovelace.
///
/// TODO migrate to BigInt in future release.
///
typedef Coin = int;

/// placeholder for future BigInt.zero
const Coin coinZero = 0;

/// Native Token policyId appended to hex encoded coin name. ADA has no policyId
/// so its assetId is just 'lovelace' in hex: '6c6f76656c616365'. Simalur to 'unit'
/// but 'lovelace' is not hex encoded.
typedef AssetId = String;

/// String representation of bech32 address
typedef Bech32Address = String;

/// Hex encoded transaction hash ID
typedef TxIdHex = String;

/// Hex encoded block hash ID
typedef BlockHashHex = String;

/// Wallet ID - stakingPublicKey for Shelley wallets
typedef WalletId = String;
