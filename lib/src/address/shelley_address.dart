// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

// ignore_for_file: constant_identifier_names

import 'package:bip32_ed25519/bip32_ed25519.dart';
import 'package:quiver/core.dart';
import '../transaction/model/bc_abstract.dart';
import '../transaction/model/bc_pointer.dart';
import '../transaction/model/bc_scripts.dart';
import '../network/network_id.dart';
import '../util/blake2bhash.dart';
import '../util/codec.dart';

///
/// Encapsulates Shelley address types. Handles proper bech32 encoding and decoding mainnet and testnet addresses.
///
/// Note: Currently only supports Base addresses and Key credentials.
/// TODO: Subclass ShelleyAddress into BaseAddress, EnterpriseAddress, PointerAddress and RewardsAddress to support
/// different behaviors.
///
/// [reference](https://cips.cardano.org/cips/cip19/) - Cardano Addresses
/// [reference](https://hydra.iohk.io/build/6141104/download/1/delegation_design_spec.pdf)
///
/// https://docs.rs/cardano-sdk/0.1.0/src/cardano_sdk/wallet/address.rs.html
/// As defined in the CDDL:
///
/// address format:
/// [ 8 bit header | payload ];
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
/// 0000: base address: keyhash28,keyhash28
/// 0001: base address: scripthash28,keyhash28
/// 0010: base address: keyhash28,scripthash28
/// 0011: base address: scripthash28,scripthash28
/// 0100: pointer address: keyhash28, 3 variable length uint
/// 0101: pointer address: scripthash28, 3 variable length uint
/// 0110: enterprise address: keyhash28
/// 0111: enterprise address: scripthash28
/// 1000: byron address
/// 1001: <future use>
/// 1010: <future use>
/// 1011: <future use>
/// 1100: <future use>
/// 1101: <future use>
/// 1110: reward account: keyhash28
/// 1111: reward account: scripthash28
///
abstract class AbstractAddress {
  Uint8List get bytes;
  AddressType get addressType => addressTypeFromHeader(bytes[0]);
  NetworkId get networkId;

  static AddressType addressTypeFromHeader(int header) {
    final addrType = (header & 0xf0) >> 4;
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

class ByronAddress extends AbstractAddress {
  @override
  final Uint8List bytes;
  final Uint8List? derivationPath;
  final int? protocolMagic;

  static const attributeNameTagDerivation = 1;
  static const attributeNameTagProtocolMagic = 2;
  static const extendedAddrLen = 28;

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
  NetworkId get networkId =>
      protocolMagic == null || protocolMagic == NetworkId.mainnet.protocolMagic
          ? NetworkId.mainnet
          : NetworkId.testnet;

  @override
  String toString() => toBase58;
}

class ShelleyAddress extends AbstractAddress {
  @override
  final Uint8List bytes;
  final String hrp;

  // final bool isChange;
  ShelleyAddress(List<int> bytes, {this.hrp = defaultAddrHrp})
      : bytes = Uint8List.fromList(bytes);
  //  {  assert(addressType == AddressType.Base || !isChange); } //change addresses must be base addresses

  factory ShelleyAddress.toBaseAddress({
    required Bip32PublicKey spend,
    required Bip32PublicKey stake,
    NetworkId networkId = NetworkId.mainnet,
    String hrp = defaultAddrHrp,
    // CredentialType paymentType = CredentialType.key,
    // CredentialType stakeType = CredentialType.key,
  }) =>
      ShelleyAddress(
        [
          ...[
            (CredentialType.key.index << 5) |
                (CredentialType.key.index << 4) |
                (networkId.index & 0x0f)
          ],
          ...blake2bHash224(spend.rawKey),
          ...blake2bHash224(stake.rawKey),
        ],
        hrp: _computeHrp(networkId, hrp),
      );

  factory ShelleyAddress.toBaseScriptAddress({
    required BcAbstractScript script,
    required Bip32PublicKey stake,
    NetworkId networkId = NetworkId.mainnet,
    String hrp = defaultAddrHrp,
    // CredentialType paymentType = CredentialType.key,
    // CredentialType stakeType = CredentialType.script,
  }) =>
      ShelleyAddress(
        [
          ...[
            (CredentialType.script.index << 5) |
                (CredentialType.key.index << 4) |
                (networkId.index & 0x0f)
          ],
          ...blake2bHash224(script.serialize),
          ...blake2bHash224(stake.rawKey),
        ],
        hrp: _computeHrp(networkId, hrp),
      );

  factory ShelleyAddress.toRewardAddress({
    required Bip32PublicKey spend,
    NetworkId networkId = NetworkId.mainnet,
    String hrp = defaultRewardHrp,
  }) =>
      ShelleyAddress(
        [
          ...[
            rewardDiscrim |
                (CredentialType.key.index << 4) |
                (networkId.index & 0x0f)
          ],
          ...blake2bHash224(spend.rawKey),
        ],
        hrp: _computeHrp(networkId, hrp),
      );

  factory ShelleyAddress.rewardAddress({
    required VerifyKey stakeKey,
    NetworkId networkId = NetworkId.mainnet,
    String hrp = defaultRewardHrp,
  }) =>
      ShelleyAddress(
        [
          ...[
            rewardDiscrim |
                (CredentialType.key.index << 4) |
                (networkId.index & 0x0f)
          ],
          ...blake2bHash224(stakeKey)
        ],
        hrp: _computeHrp(networkId, hrp),
      );

  factory ShelleyAddress.enterpriseScriptAddress({
    required BcAbstractScript script,
    NetworkId networkId = NetworkId.mainnet,
    String hrp = defaultAddrHrp,
  }) =>
      ShelleyAddress(
        [
          ...[
            enterpriseScriptDiscrim | //0b0111_0000;
                (CredentialType.script.index << 4) |
                (networkId.index & 0x0f)
          ],
          ...script.scriptHash,
        ],
        hrp: _computeHrp(networkId, hrp),
      );

  factory ShelleyAddress.enterprisePlutusScriptAddress({
    required BcPlutusScript script,
    NetworkId networkId = NetworkId.mainnet,
    String hrp = defaultAddrHrp,
    CredentialType paymentType = CredentialType.key,
  }) =>
      ShelleyAddress(
        [
          ...[
            enterpriseScriptDiscrim | //0b0111_0000;
                (paymentType.index << 4) |
                (networkId.index & 0x0f)
          ],
          ...blake2bHash224(script.serialize),
        ],
        hrp: _computeHrp(networkId, hrp),
      );

  factory ShelleyAddress.enterpriseAddress({
    required Bip32PublicKey spend,
    NetworkId networkId = NetworkId.mainnet,
    String hrp = defaultAddrHrp,
    CredentialType paymentType = CredentialType.key,
  }) =>
      ShelleyAddress(
        [
          ...[
            enterpriseDiscrim | //0b0110_0000;
                (paymentType.index << 4) |
                (networkId.index & 0x0f) //& 0b0000_1111;
          ],
          ...blake2bHash224(spend.rawKey),
        ],
        hrp: _computeHrp(networkId, hrp),
      );

  // //header: 0110....
  // public Address getEntAddress(HdPublicKey paymentKey, Network networkInfo)  {
  //     if (paymentKey == null)
  //         throw new AddressRuntimeException("paymentkey cannot be null");

  //     byte[] paymentKeyHash = paymentKey.getKeyHash();

  //     byte headerType = 0b0110_0000;

  //     return getAddress(paymentKeyHash, null, headerType, networkInfo, AddressType.Enterprise);
  // }

  factory ShelleyAddress.pointerAddress({
    required VerifyKey verifyKey,
    required BcPointer pointer,
    NetworkId networkId = NetworkId.mainnet,
    String hrp = defaultAddrHrp,
    // CredentialType paymentType = CredentialType.key,
  }) =>
      ShelleyAddress(
        [
          ...[
            pointerDiscrim |
                (CredentialType.key.index << 4) |
                (networkId.index & 0x0f)
          ],
          ...blake2bHash224(verifyKey),
          ...pointer.hash,
        ],
        hrp: _computeHrp(networkId, hrp),
      );

  factory ShelleyAddress.pointerScriptAddress({
    required BcNativeScript script,
    required BcPointer pointer,
    NetworkId networkId = NetworkId.mainnet,
    String hrp = defaultAddrHrp,
  }) =>
      ShelleyAddress(
        [
          ...[
            pointerScriptDiscrim |
                (CredentialType.script.index << 4) |
                (networkId.index & 0x0f)
          ],
          ...script.scriptHash,
          ...pointer.hash,
        ],
        hrp: _computeHrp(networkId, hrp),
      );

  // factory ShelleyAddress.pointerAddress({
  //   required Bip32PublicKey spend,
  //   required BcPointer pointer,
  //   NetworkId networkId = NetworkId.mainnet,
  //   String hrp = defaultAddrHrp,
  //   CredentialType paymentType = CredentialType.key,
  // }) =>
  //     ShelleyAddress(
  //       [pointerDiscrim | (paymentType.index << 4) | (networkId.index & 0x0f)] +
  //           blake2bHash224(spend.rawKey) +
  //           pointer.hash,
  //       hrp: _computeHrp(networkId, hrp),
  //     );

  //   public Address getPointerAddress(HdPublicKey paymentKey, Pointer delegationPointer, Network networkInfo) {
  //     if (paymentKey == null || delegationPointer == null)
  //         throw new AddressRuntimeException("paymentkey and delegationKey cannot be null");

  //     byte[] paymentKeyHash = paymentKey.getKeyHash();
  //     byte[] delegationPointerHash = BytesUtil.merge(variableNatEncode(delegationPointer.slot),
  //             variableNatEncode(delegationPointer.txIndex), variableNatEncode(delegationPointer.certIndex));

  //     byte headerType = 0b0100_0000;
  //     return getAddress(paymentKeyHash, delegationPointerHash, headerType, networkInfo, AddressType.Ptr);
  // }

  factory ShelleyAddress.fromBech32(String address) {
    final decoded = bech32.decode(address, 256);
    final hrp = decoded.hrp;
    final bytes = Bech32Coder(hrp: hrp).decode(address);
    return ShelleyAddress(bytes, hrp: hrp);
  }

  String toBech32({String? prefix}) {
    prefix ??= _computeHrp(networkId, hrp);
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
  NetworkId get networkId => NetworkId.testnet.networkId == bytes[0] & 0x0f
      ? NetworkId.testnet
      : NetworkId.mainnet;

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
  // "${_enumSuffix(addressType.toString())} ${_enumSuffix(networkId.toString())} ${_enumSuffix(paymentCredentialType.toString())} ${toBech32()}";

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

  static String _computeHrp(NetworkId id, String prefix) => id ==
          NetworkId.testnet
      ? (prefix.endsWith(testnetHrpSuffix) ? prefix : prefix + testnetHrpSuffix)
      : prefix;

  static final List<int> _addressTypeValues = [
    baseDiscrim,
    pointerDiscrim,
    enterpriseDiscrim,
    rewardDiscrim
  ];

  static int addressTypeValue(AddressType addressType) =>
      _addressTypeValues[addressType.index];

  static const Bech32Coder mainNetEncoder = Bech32Coder(hrp: defaultAddrHrp);
  static const Bech32Coder testNetEncoder =
      Bech32Coder(hrp: defaultAddrHrp + testnetHrpSuffix);
  static const Bech32Coder mainNetRewardEncoder =
      Bech32Coder(hrp: defaultRewardHrp);
  static const Bech32Coder testNetRewardEncoder =
      Bech32Coder(hrp: defaultRewardHrp + testnetHrpSuffix);
}

enum AddressType { base, pointer, enterprise, reward, byron }

enum CredentialType { key, script }

const String defaultAddrHrp = 'addr';
const String defaultRewardHrp = 'stake';
const String testnetHrpSuffix = '_test';
const int baseDiscrim = 0x00; //0b0000_0000
const int pointerDiscrim = 0x40; //0b0100_0000
const int pointerScriptDiscrim = 0x50; //0b0101_0000
const int enterpriseDiscrim = 0x60; // 0b0110_0000
const int enterpriseScriptDiscrim = 0x70; //  = 0b0111_0000;
const int byronDiscrim = 0x80; //0b1000_0000
const int rewardDiscrim = 0xe0; //0b1110_0000

///
/// return either a ShelleyAddress or a ByronAddress
/// throws InvalidAddressError if invalid input
///
AbstractAddress stringToAddress(String address) {
  if (address.startsWith("addr") || address.startsWith("stake")) {
    return ShelleyAddress.fromBech32(address); //Shelley address
  } else {
    return ByronAddress.fromBase58(address); //Try for byron address
  }
}

// @Deprecated('use BcPointer')
// class DelegationPointer {
//   final int slot;
//   final int txIndex;
//   final int certIndex;

//   DelegationPointer(
//       {required this.slot, required this.txIndex, required this.certIndex});

//   Uint8List get hash => Uint8List.fromList(
//       _natEncode(slot) + _natEncode(txIndex) + _natEncode(certIndex));

//   List<int> _natEncode(int num) {
//     List<int> result = [];
//     result.add(num & 0x7f);
//     num = num ~/ 128;
//     while (num > 0) {
//       result.add(num & 0x7f | 0x80);
//       num = num ~/ 128;
//     }
//     return result.reversed.toList();
//   }
//   private byte[] variableNatEncode(long num) {
//     List<Byte> output = new ArrayList<>();
//     output.add((byte)(num & 0x7F));

//     num /= 128;
//     while(num > 0) {
//         output.add((byte)((num & 0x7F) | 0x80));
//         num /= 128;
//     }
//     Collections.reverse(output);

//     return Bytes.toArray(output);
// }
// }

class InvalidAddressError extends Error {
  final String message;
  InvalidAddressError(this.message);
  @override
  String toString() => message;
}
