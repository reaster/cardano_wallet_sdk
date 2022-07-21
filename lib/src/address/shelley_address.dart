// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

// ignore_for_file: constant_identifier_names

import 'package:bip32_ed25519/bip32_ed25519.dart';
import 'package:quiver/core.dart';
import '../transaction/model/bc_pointer.dart';
import '../transaction/model/bc_scripts.dart';
import '../network/network_id.dart';
import '../util/blake2bhash.dart';
import '../util/codec.dart';

///
/// Encapsulates Shelley and Byron address types. Handles proper bech32 encoding and decoding mainnet and testnet addresses.
///
/// Address format: [ 8 bit header | payload ];
///
/// references:
/// [Cardano Addresses](https://cips.cardano.org/cips/cip19/)
/// [Delegation Design Spec](https://hydra.iohk.io/build/6141104/download/1/delegation_design_spec.pdf)
/// [Rust implementation](https://docs.rs/cardano-sdk/0.1.0/src/cardano_sdk/wallet/address.rs.html)
///
abstract class AbstractAddress {
  ///
  /// Raw bytes of address.
  /// Format [ 8 bit header | payload ]
  ///
  Uint8List get bytes;

  ///
  /// Returns high-level grouping of address type: base, pointer, enterprise, byron or reward.
  ///
  AddressType get addressType => addressTypeFromHeader(bytes[0]);

  ///
  /// Returns Network (mainnet or testnet) that this address is bound to.
  ///
  Networks get network;

  ///
  /// returns the 8 bit header of the address.
  ///
  /// throws InvalidAddressError if not defined
  ///
  /// shelley payment addresses:
  /// bit 7: 0
  /// bit 6: base/other
  /// bit 5: pointer/enterprise [for base: stake cred is keyhash/scripthash]
  /// bit 4: payment cred is keyhash/scripthash
  /// bits 3-0: network id
  ///
  /// reward addresses:
  /// bits 7-5: 111
  /// bit 4: credential is keyhash/scripthash
  /// bits 3-0: network id
  ///
  /// byron addresses:
  /// bits 7-4: 1000
  ///
  /// 0000_0000: base address: keyhash28,keyhash28
  /// 0001_0000: base address: scripthash28,keyhash28
  /// 0010_0000: base address: keyhash28,scripthash28
  /// 0011_0000: base address: scripthash28,scripthash28
  /// 0100_0000: pointer address: keyhash28, 3 variable length uint
  /// 0101_0000: pointer address: scripthash28, 3 variable length uint
  /// 0110_0000: enterprise address: keyhash28
  /// 0111_0000: enterprise address: scripthash28
  /// 1000_0000: byron address
  /// 1001_0000: <future use>
  /// 1010_0000: <future use>
  /// 1011_0000: <future use>
  /// 1100_0000: <future use>
  /// 1101_0000: <future use>
  /// 1110_0000: reward account: keyhash28
  /// 1111_0000: reward account: scripthash28
  ///
  int get header => bytes[0];

  static AddressType addressTypeFromHeader(int header) {
    final addrType = (header & 0xf0) >> 4; //just look at 7-4 bits, ignore 3-0
    switch (addrType) {
      // Base Address
      case 0:
      case 1:
      case 2:
      case 3:
        return AddressType.base;
      case 4:
      case 5:
        return AddressType.pointer;
      case 6:
      case 7:
        return AddressType.enterprise;
      case 8:
        return AddressType.byron;
      //case 9,10,11,12,13: future specs
      case 14:
      case 15:
        return AddressType.reward;
      default:
        throw InvalidAddressError("addressType: $addrType is not defined.");
    }
  }
}

///
/// ByronAddress allows Byron or bootstrap addresses to be writen and read as base58
/// strings (but not currently parsed) in a way that allows them to co-exist with
/// ShelleyAddresses.
///
class ByronAddress extends AbstractAddress {
  @override
  final Uint8List bytes;
  final Uint8List? derivationPath;
  final int? protocolMagic;

  static const attributeNameTagDerivation = 1;
  static const attributeNameTagProtocolMagic = 2;
  static const extendedAddrLen = 28;

  /// Construct byron address. Currently derivationPath and protocolMagic are ignored.
  /// throws InvalidAddressError if not a Byron address or length is below 28 bytes.
  ByronAddress(this.bytes, {this.derivationPath, this.protocolMagic}) {
    if (addressType != AddressType.byron) {
      throw InvalidAddressError(
          "Invalid AddressType: ${addressType.index}, expected byron(${AddressType.byron.index}) in $toBase58");
    }
    if (bytes.length < extendedAddrLen) {
      throw InvalidAddressError(
          "Invalid byte length: ${bytes.length}, expected at least $extendedAddrLen in $toBase58");
    }
  }

  /// Construct byron address from a base58 encoded string.
  /// throws InvalidAddressError if not a Byron address or length is below 28 bytes.
  factory ByronAddress.fromBase58(String base58) {
    try {
      return ByronAddress(base58Codec.decode(base58));
    } on InvalidAddressError {
      rethrow;
    } catch (e) {
      throw InvalidAddressError(
          "$base58 is not a valid byron base58 address: ${e.toString()}");
    }
  }

  String get toBase58 => base58Codec.encode(bytes);

  @override
  Networks get network =>
      protocolMagic == null || protocolMagic == Networks.mainnet.protocolMagic
          ? Networks.mainnet
          : Networks.testnet;

  @override
  String toString() => toBase58;
}

///
/// ShelleyAddress supports base, pointer, enterprise and rewards address types documented in CIP19.
///
class ShelleyAddress extends AbstractAddress {
  @override
  final Uint8List bytes;
  final String hrp;

  // final bool isChange;
  ShelleyAddress(List<int> bytes, {this.hrp = defaultAddrHrp})
      : bytes = Uint8List.fromList(bytes);
  //  {  assert(addressType == AddressType.Base || !isChange); } //change addresses must be base addresses

  factory ShelleyAddress.baseAddress({
    required VerifyKey spend,
    required VerifyKey stake,
    Networks network = Networks.mainnet,
    String hrp = defaultAddrHrp,
  }) =>
      ShelleyAddress(
        [
          ...[
            AddressType.base.header |
                CredentialType.key.header1 |
                CredentialType.key.header2 |
                network.networkId
          ],
          ...blake2bHash224(_stripChain(spend)),
          ...blake2bHash224(_stripChain(stake)),
        ],
        hrp: _computeHrp(network, hrp),
      );

  factory ShelleyAddress.baseScriptStakeAddress({
    required BcAbstractScript script,
    required VerifyKey stake,
    Networks network = Networks.mainnet,
    String hrp = defaultAddrHrp,
  }) =>
      ShelleyAddress(
        [
          ...[
            AddressType.base.header |
                CredentialType.script.header1 |
                CredentialType.key.header2 |
                network.networkId
          ],
          ...script.scriptHash,
          ...blake2bHash224(_stripChain(stake)),
        ],
        hrp: _computeHrp(network, hrp),
      );

  factory ShelleyAddress.baseKeyScriptAddress({
    required VerifyKey spend,
    required BcAbstractScript script,
    Networks network = Networks.mainnet,
    String hrp = defaultAddrHrp,
  }) =>
      ShelleyAddress(
        [
          ...[
            AddressType.base.header |
                CredentialType.key.header1 |
                CredentialType.script.header2 |
                network.networkId
          ],
          ...blake2bHash224(_stripChain(spend)),
          ...script.scriptHash,
        ],
        hrp: _computeHrp(network, hrp),
      );

  factory ShelleyAddress.baseScriptScriptAddress({
    required BcAbstractScript script1,
    required BcAbstractScript script2,
    Networks network = Networks.mainnet,
    String hrp = defaultAddrHrp,
  }) =>
      ShelleyAddress(
        [
          ...[
            AddressType.base.header |
                CredentialType.script.header1 |
                CredentialType.script.header2 |
                network.networkId
          ],
          ...script1.scriptHash,
          ...script2.scriptHash,
        ],
        hrp: _computeHrp(network, hrp),
      );

  factory ShelleyAddress.pointerAddress({
    required VerifyKey verifyKey,
    required BcPointer pointer,
    Networks network = Networks.mainnet,
    String hrp = defaultAddrHrp,
    // CredentialType paymentType = CredentialType.key,
  }) =>
      ShelleyAddress(
        [
          ...[
            AddressType.pointer.header |
                CredentialType.key.header1 |
                network.networkId
          ],
          ...blake2bHash224(_stripChain(verifyKey)),
          ...pointer.hash,
        ],
        hrp: _computeHrp(network, hrp),
      );

  factory ShelleyAddress.pointerScriptAddress({
    required BcAbstractScript script,
    required BcPointer pointer,
    Networks network = Networks.mainnet,
    String hrp = defaultAddrHrp,
  }) =>
      ShelleyAddress(
        [
          ...[
            AddressType.pointer.header |
                CredentialType.script.header1 |
                network.networkId
          ],
          ...script.scriptHash,
          ...pointer.hash,
        ],
        hrp: _computeHrp(network, hrp),
      );

  factory ShelleyAddress.enterpriseAddress({
    required VerifyKey spend,
    Networks network = Networks.mainnet,
    String hrp = defaultAddrHrp,
    CredentialType paymentType = CredentialType.key,
  }) =>
      ShelleyAddress(
        [
          ...[
            AddressType.enterprise.header |
                CredentialType.key.header1 |
                network.networkId
          ],
          ...blake2bHash224(_stripChain(spend)),
        ],
        hrp: _computeHrp(network, hrp),
      );

  factory ShelleyAddress.enterpriseScriptAddress({
    required BcAbstractScript script,
    Networks network = Networks.mainnet,
    String hrp = defaultAddrHrp,
  }) =>
      ShelleyAddress(
        [
          ...[
            AddressType.enterprise.header |
                CredentialType.script.header1 |
                network.networkId
          ],
          ...script.scriptHash,
        ],
        hrp: _computeHrp(network, hrp),
      );

  // factory ShelleyAddress.enterprisePlutusScriptAddress({
  //   required BcPlutusScript script,
  //   Networks network = Networks.mainnet,
  //   String hrp = defaultAddrHrp,
  // }) =>
  //     ShelleyAddress(
  //       [
  //         ...[
  //           AddressType.enterprise.header |
  //               CredentialType.script.header1 |
  //               network.networkId
  //         ],
  //         ...script.scriptHash,
  //       ],
  //       hrp: _computeHrp(network, hrp),
  //     );

  // factory ShelleyAddress.toRewardAddress({
  //   required Bip32PublicKey spend,
  //   Networks network = Networks.mainnet,
  //   String hrp = defaultRewardHrp,
  // }) =>
  //     ShelleyAddress(
  //       [
  //         ...[
  //           AddressType.reward.header |
  //               CredentialType.key.header1 |
  //               network.networkId
  //         ],
  //         ...blake2bHash224(spend.rawKey),
  //       ],
  //       hrp: _computeHrp(network, hrp),
  //     );

  factory ShelleyAddress.rewardAddress({
    required VerifyKey stakeKey,
    Networks network = Networks.mainnet,
    String hrp = defaultRewardHrp,
  }) =>
      ShelleyAddress(
        [
          ...[
            AddressType.reward.header |
                CredentialType.key.header1 |
                network.networkId
          ],
          ...blake2bHash224(_stripChain(stakeKey))
        ],
        hrp: _computeHrp(network, hrp),
      );

  factory ShelleyAddress.rewardScriptAddress({
    // required Bip32PublicKey spend,
    required BcAbstractScript script,
    Networks network = Networks.mainnet,
    String hrp = defaultRewardHrp,
  }) =>
      ShelleyAddress(
        [
          ...[
            AddressType.reward.header |
                CredentialType.script.header1 |
                network.networkId
          ],
          ...script.scriptHash,
        ],
        hrp: _computeHrp(network, hrp),
      );

  factory ShelleyAddress.fromBech32(String address) {
    final decoded = bech32.decode(address, 256);
    final hrp = decoded.hrp;
    final bytes = Bech32Coder(hrp: hrp).decode(address);
    return ShelleyAddress(bytes, hrp: hrp);
  }

  String toBech32({String? prefix}) {
    prefix ??= _computeHrp(network, hrp);
    switch (prefix) {
      case defaultAddrHrp:
        return mainNetEncoder.encode(bytes);
      case defaultAddrHrp + testnetHrpSuffix:
        return testNetEncoder.encode(bytes);
      case defaultRewardHrp:
        return mainNetRewardEncoder.encode(bytes);
      case defaultRewardHrp + testnetHrpSuffix:
        return testNetRewardEncoder.encode(bytes);
    }
    return Bech32Coder(hrp: prefix).encode(bytes);
  }

  @override
  Networks get network => Networks.testnet.networkId == bytes[0] & 0x0f
      ? Networks.testnet
      : Networks.mainnet;

  // @override
  // AddressType get addressType {
  //   final addrType = (bytes[0] & 0xf0) >> 4;
  //   switch (addrType) {
  //     // Base Address
  //     case 0:
  //     case 1:
  //     case 2:
  //     case 3:
  //       return AddressType.base;
  //     case 4:
  //     case 5:
  //       return AddressType.pointer;
  //     case 6:
  //     case 7:
  //       return AddressType.enterprise;
  //     case 8:
  //       return AddressType.byron;
  //     //case 9,10,11,12,13 future specs
  //     case 14:
  //     case 15:
  //       return AddressType.reward;
  //     default:
  //       throw InvalidAddressTypeError(
  //           "addressType: $addressType is not defined. Containing address ${toBech32()}");
  //   }
  // }

  CredentialType get paymentCredentialType =>
      (bytes[0] & 0x10) >> 4 == 0 ? CredentialType.key : CredentialType.script;

  @override
  String toString() => toBech32();

  String bytesToString() => "[${bytes.join(',')}]";

  @override
  int get hashCode => hashObjects(bytes);

  @override
  bool operator ==(Object other) {
    final isEqual = identical(this, other) ||
        other is ShelleyAddress &&
            runtimeType == other.runtimeType &&
            bytes.length == other.bytes.length;
    if (!isEqual || hrp != (other as ShelleyAddress).hrp) return false;
    for (var i = 0; i < bytes.length; i++) {
      if (bytes[i] != other.bytes[i]) return false;
    }
    return true;
  }

  static String _computeHrp(Networks id, String prefix) => id ==
          Networks.testnet
      ? (prefix.endsWith(testnetHrpSuffix) ? prefix : prefix + testnetHrpSuffix)
      : prefix;

  static VerifyKey _stripChain(VerifyKey vk) =>
      vk is Bip32VerifyKey ? VerifyKey(Uint8List.fromList(vk.prefix)) : vk;

  static const Bech32Coder mainNetEncoder = Bech32Coder(hrp: defaultAddrHrp);
  static const Bech32Coder testNetEncoder =
      Bech32Coder(hrp: defaultAddrHrp + testnetHrpSuffix);
  static const Bech32Coder mainNetRewardEncoder =
      Bech32Coder(hrp: defaultRewardHrp);
  static const Bech32Coder testNetRewardEncoder =
      Bech32Coder(hrp: defaultRewardHrp + testnetHrpSuffix);
}

//enum AddressType { base, pointer, enterprise, byron, reward }
/// byron addresses:
/// bits 7-4: 1000
///
/// 0000_0000: base address: keyhash28,keyhash28
/// 0001_0000: base address: scripthash28,keyhash28
/// 0010_0000: base address: keyhash28,scripthash28
/// 0011_0000: base address: scripthash28,scripthash28
/// 0100_0000: pointer address: keyhash28, 3 variable length uint
/// 0101_0000: pointer address: scripthash28, 3 variable length uint
/// 0110_0000: enterprise address: keyhash28
/// 0111_0000: enterprise address: scripthash28
/// 1000_0000: byron address
/// 1001_0000: <future use>
/// 1010_0000: <future use>
/// 1011_0000: <future use>
/// 1100_0000: <future use>
/// 1101_0000: <future use>
/// 1110_0000: reward account: keyhash28
/// 1111_0000: reward account: scripthash28
///
enum AddressType {
  base(0 << 7), // 0b0000_0000
  pointer(1 << 6), // 0b0100_0000
  enterprise(1 << 6 | 1 << 5), // 0b0110_0000
  byron(1 << 7), // 0b1000_0000
  reward(1 << 7 | 1 << 6 | 1 << 5); // 0b1110_0000

  final int header;
  const AddressType(this.header);
}

enum CredentialType {
  key(0 << 4, 0 << 5), // 0b0000_0000, 0b0000_0000
  script(1 << 4, 1 << 5); // 0b0001_0000, 0b0010_0000

  final int header1;
  final int header2;
  const CredentialType(this.header1, this.header2);
}

const String defaultAddrHrp = 'addr';
const String defaultRewardHrp = 'stake';
const String testnetHrpSuffix = '_test';

///
/// return either a ShelleyAddress or a ByronAddress
/// throws InvalidAddressError if invalid input
///
AbstractAddress parseAddress(String address) {
  if (address.startsWith("addr") || address.startsWith("stake")) {
    return ShelleyAddress.fromBech32(address); //Shelley address
  } else {
    return ByronAddress.fromBase58(address); //Try for byron address
  }
}

class InvalidAddressError extends Error {
  final String message;
  InvalidAddressError(this.message);
  @override
  String toString() => message;
}
