// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

///
/// The Cardano testnet and mainnet are two independent blockchains and this value
/// determines which one your code will run on.
///
enum NetworkId {
  testnet(0, 1097911063),
  mainnet(1, 764824073);

  const NetworkId(this.networkId, this.protocolMagic);
  final int networkId;
  final int protocolMagic;
}



//rust:
// pub fn testnet() -> NetworkInfo {
//     NetworkInfo {
//         network_id: 0b0000,
//         protocol_magic: 1097911063
//     }
// }
// pub fn mainnet() -> NetworkInfo {
//     NetworkInfo {
//         network_id: 0b0001,
//         protocol_magic: 764824073
