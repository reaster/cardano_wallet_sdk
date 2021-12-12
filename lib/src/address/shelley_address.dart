// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:bip32_ed25519/bip32_ed25519.dart';
import 'package:quiver/core.dart';
import '../network/network_id.dart';
import '../util/blake2bhash.dart';

///
/// Encapsulates Shelley address types. Handles proper bech32 encoding and decoding mainnet and testnet addresses.
///
/// Note: Currently only supports Base addresses and Key credentials.
/// TODO: Subclass ShelleyAddress into BaseAddress, EnterpriseAddress, PointerAddress and RewardsAddress to support
/// different behaviors.
///
/// [reference](https://cips.cardano.org/cips/cip19/)
/// [reference](https://hydra.iohk.io/build/6141104/download/1/delegation_design_spec.pdf)
///
enum AddressType { base, pointer, enterprise, reward }
enum CredentialType { key, script }

const String defaultAddrHrp = 'addr';
const String defaultRewardHrp = 'stake';
const String testnetHrpSuffix = '_test';
const int baseDiscrim = 0x00; //0b0000_0000
const int pointerDiscrim = 0x40; //0b0100_0000
const int enterpriseDiscrim = 0x60; // 0b0110_0000
const int rewardDiscrim = 0xe0; //0b1110_0000

class ShelleyAddress extends ByteList {
  final String hrp;
  // final bool isChange;
  ShelleyAddress(List<int> bytes, {this.hrp = defaultAddrHrp}) : super(bytes);
  //  {  assert(addressType == AddressType.Base || !isChange); } //change addresses must be base addresses

  factory ShelleyAddress.toBaseAddress({
    required Bip32PublicKey spend,
    required Bip32PublicKey stake,
    NetworkId networkId = NetworkId.testnet,
    String hrp = defaultAddrHrp,
    CredentialType paymentType = CredentialType.key,
    CredentialType stakeType = CredentialType.key,
  }) =>
      ShelleyAddress(
        [
              (stakeType.index << 5) |
                  (paymentType.index << 4) |
                  (networkId.index & 0x0f)
            ] +
            blake2bHash224(spend.rawKey) +
            blake2bHash224(stake.rawKey),
        hrp: _computeHrp(networkId, hrp),
      );

  factory ShelleyAddress.toRewardAddress({
    required Bip32PublicKey spend,
    NetworkId networkId = NetworkId.testnet,
    String hrp = defaultRewardHrp,
    CredentialType paymentType = CredentialType.key,
  }) =>
      ShelleyAddress(
        [rewardDiscrim | (paymentType.index << 4) | (networkId.index & 0x0f)] +
            blake2bHash224(spend.rawKey),
        hrp: _computeHrp(networkId, hrp),
      );

  factory ShelleyAddress.fromBech32(String address) {
    final decoded = bech32.decode(address, 256);
    final hrp = decoded.hrp;
    final bytes = Bech32Coder(hrp: hrp).decode(address);
    return ShelleyAddress(bytes, hrp: hrp);
  }

  String toBech32({String? prefix}) {
    prefix ??= _computeHrp(networkId, hrp);
    return encode(Bech32Coder(hrp: prefix));
  }

  NetworkId get networkId => NetworkId.testnet.index == this[0] & 0x0f
      ? NetworkId.testnet
      : NetworkId.mainnet;

  AddressType get addressType {
    final addrType = (this[0] & 0xf0) >> 4;
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
      case 14:
      case 15:
        return AddressType.reward;
      default:
        throw InvalidAddressTypeError(
            "addressType: $addressType is not defined. Containing address ${toBech32()}");
    }
  }

  CredentialType get paymentCredentialType =>
      (this[0] & 0x10) >> 4 == 0 ? CredentialType.key : CredentialType.script;

  @override
  String toString() => toBech32();
  // "${_enumSuffix(addressType.toString())} ${_enumSuffix(networkId.toString())} ${_enumSuffix(paymentCredentialType.toString())} ${toBech32()}";

  @override
  int get hashCode => hashObjects(this);

  @override
  bool operator ==(Object other) {
    final isEqual = identical(this, other) ||
        other is ShelleyAddress &&
            runtimeType == other.runtimeType &&
            length == other.length;
    if (!isEqual || hrp != (other as ShelleyAddress).hrp) return false;
    for (var i = 0; i < length; i++) {
      if (this[i] != other[i]) return false;
    }
    return true;
  }

  //static String _enumSuffix(String enumString) => enumString.substring(enumString.lastIndexOf('.') + 1);

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
}

class InvalidAddressTypeError extends Error {
  final String message;
  InvalidAddressTypeError(this.message);
  @override
  String toString() => message;
}

/// [github source](https://github.com/ilap/bip32-ed25519-dart)
///
// enum AddressType { Base, Pointer, Enterprise, Reward }
// enum CredentialType { Key, Script }

// String credentialString(CredentialType type) => type == CredentialType.Key ? 'key' : 'script';
// String networkIdString(NetworkId id) => id == NetworkId.mainnet ? 'mainnet' : 'testnet';
// String addressTypeString(AddressType type) {
//   final s = type.toString();
//   return s.substring(s.lastIndexOf('.') + 1);
// }

// abstract class CredentialHash28 extends ByteList {
//   int get kind;
//   CredentialType get type => kind == CredentialType.Key.index ? CredentialType.Key : CredentialType.Script;
//   static const hashLength = 28;
//   CredentialHash28(List<int> bytes) : super(bytes, hashLength);
// }

// class KeyHash28 extends CredentialHash28 {
//   KeyHash28(List<int> bytes) : super(bytes);

//   @override
//   int get kind => CredentialType.Key.index;
// }

// class ScriptHash28 extends CredentialHash28 {
//   ScriptHash28(List<int> bytes) : super(bytes);

//   @override
//   int get kind => CredentialType.Script.index;
// }

// abstract class ShelleyAddress extends ByteList {
//   static const defaultPrefix = 'addr';
//   static const defaultTail = '_test';

//   final NetworkId networkId;

//   ShelleyAddress(this.networkId, List<int> bytes) : super(bytes);

//   AddressType get addressType;

//   CredentialType get credentialType => _isScript(super[0], bit: 4) ? CredentialType.Script : CredentialType.Key;

//   static String _computeHrp(NetworkId id, String prefix) {
//     return id == NetworkId.testnet ? prefix + ShelleyAddress.defaultTail : prefix;
//   }

//   String toBech32({String? prefix}) {
//     prefix ??= _computeHrp(networkId, defaultPrefix);

//     return this.encode(Bech32Coder(hrp: prefix));
//   }

//   @override
//   String toString() {
//     return "${addressTypeString(addressType)} ${networkIdString(networkId)} ${credentialString(credentialType)} ${toBech32()}";
//   }

//   static ShelleyAddress fromBech32(String address) {
//     final decoded = bech32.decode(address, 256);
//     final hrp = decoded.hrp;

//     final bytes = Bech32Coder(hrp: hrp).decode(address);
//     return fromBytes(bytes);
//   }

//   static ShelleyAddress fromBytes(List<int> bytes) {
//     final header = bytes[0];
//     final networkId = NetworkId.values[header & 0x0f];

//     final addrType = (header & 0xf0) >> 4;
//     switch (addrType) {
//       // Base Address
//       case 0:
//       case 1:
//       case 2:
//       case 3:
//         if (bytes.length != 1 + CredentialHash28.hashLength * 2) {
//           // FIXME: Create proper error classes
//           throw Error();
//         }
//         return BaseAddress(networkId, _getCredentialType(header, bytes.getRange(1, 29).toList(), bit: 4),
//             _getCredentialType(header, bytes.skip(1 + CredentialHash28.hashLength).toList(), bit: 5));

//       // Pointer Address
//       case 4:
//       case 5:
//         break;

//       // Enterprise Address
//       case 6:
//       case 7:
//         if (bytes.length != 1 + CredentialHash28.hashLength) {
//           // FIXME: Create proper error classes
//           throw Error();
//         }
//         return EnterpriseAddress(networkId, _getCredentialType(header, bytes.skip(1).toList(), bit: 4));

//       // Stake (chmeric) Address
//       case 14:
//       case 15:
//         if (bytes.length != 1 + CredentialHash28.hashLength) {
//           // FIXME: Create proper error classes
//           throw Error();
//         }
//         return RewardAddress(networkId, _getCredentialType(header, bytes.skip(1).toList(), bit: 4));

//       default:
//         throw Exception('Unsupported Cardano Address, type: $header');
//     }

//     throw Error();
//   }

//   static CredentialHash28 _getCredentialType(int header, List<int> bytes, {required int bit}) {
//     return _isScript(header, bit: bit) ? ScriptHash28(bytes) : KeyHash28(bytes);
//   }

//   /// If the nth bit is 0 that means it's a key hash, otherwise it's script hash.
//   ///
//   static bool _isScript(int header, {required int bit}) => header & (1 << bit) != 0;

//   static List<int> _computeBytes(NetworkId networkId, AddressType addresType, CredentialHash28 paymentBytes,
//       {CredentialHash28? stakeBytes}) {
//     //int header = networkId.index & 0x0f;

//     switch (addresType) {
//       case AddressType.Base:
//         if (stakeBytes == null) {
//           throw Exception('Base address requires Stake credential');
//         }
//         final header = (networkId.index & 0x0f) | (paymentBytes.kind << 4) | (stakeBytes.kind << 5);
//         return [header] + paymentBytes + stakeBytes;
//       case AddressType.Enterprise:
//         final header = 0x60 | (networkId.index & 0x0f) | (paymentBytes.kind << 4);
//         return [header] + paymentBytes;
//       //case AddressType.Pointer:
//       case AddressType.Reward:
//         final header = 0xe0 | (networkId.index & 0x0f) | (paymentBytes.kind << 4);
//         return [header] + paymentBytes;
//       default:
//         throw Exception('Unsupported address header');
//     }
//   }
// }

// class BaseAddress extends ShelleyAddress {
//   BaseAddress(
//     NetworkId networkId,
//     CredentialHash28 paymentBytes,
//     CredentialHash28 stakeBytes,
//   ) : super(networkId, ShelleyAddress._computeBytes(networkId, AddressType.Base, paymentBytes, stakeBytes: stakeBytes));
//   BaseAddress.fromKeys(
//     NetworkId networkId,
//     Bip32Key paymentKey,
//     Bip32Key stakeKey,
//   ) : this(networkId, _toHash(paymentKey), _toHash(stakeKey));
//   AddressType get addressType => AddressType.Base;
//   static CredentialHash28 _toHash(Bip32Key key) {
//     return KeyHash28(key.buffer.asInt32List());
//   } //TODO just a hack
// }

// class EnterpriseAddress extends ShelleyAddress {
//   EnterpriseAddress(NetworkId networkId, CredentialHash28 bytes)
//       : super(networkId, ShelleyAddress._computeBytes(networkId, AddressType.Enterprise, bytes));
//   AddressType get addressType => AddressType.Enterprise;
// }

// class PointerAddress extends ShelleyAddress {
//   PointerAddress(NetworkId networkId, CredentialHash28 bytes)
//       : super(networkId, ShelleyAddress._computeBytes(networkId, AddressType.Pointer, bytes));
//   AddressType get addressType => AddressType.Pointer;
// }

// class RewardAddress extends ShelleyAddress {
//   RewardAddress(NetworkId networkId, CredentialHash28 bytes)
//       : super(networkId, ShelleyAddress._computeBytes(networkId, AddressType.Reward, bytes));
//   AddressType get addressType => AddressType.Reward;
// }

// void main() {
//   const seed = '475083b81730de275969b1f18db34b7fb4ef79c66aa8efdd7742f1bcfe204097';
//   const addressPath = "m/1852'/1815'/0'/0/0";
//   const rewardAddressPath = "m/1852'/1815'/0'/2/0";

//   final icarusKeyTree = CardanoKeyIcarus.seed(seed);

//   // final Bip32Key addressKey = icarusKeyTree.forPath(addressPath);
//   // logger.i(addressKey);
//   // final Bip32Key rewardKey = icarusKeyTree.forPath(rewardAddressPath);
//   // logger.i(rewardKey);

//   final addressKey = icarusKeyTree.pathToKey(addressPath);
//   logger.i(addressKey);
//   final rewardKey = icarusKeyTree.pathToKey(rewardAddressPath);
//   logger.i(rewardKey);
//   final addr1 = BaseAddress.fromKeys(NetworkId.testnet, addressKey, rewardKey);
//   logger.i(addr1);

//   var address = ShelleyAddress.fromBech32(
//       'addr_test1qz2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3jcu5d8ps7zex2k2xt3uqxgjqnnj83ws8lhrn648jjxtwq2ytjqp');
//   logger.i(address);

//   address =
//       ShelleyAddress.fromBech32('addr1qx2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3jcu5d8ps7zex2k2xt3uqxgjqnnj83ws8lhrn648jjxtwqfjkjv7');
//   logger.i(address);

//   address = ShelleyAddress.fromBech32('addr_test1vz2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzerspjrlsz');
//   logger.i(address);

//   address = ShelleyAddress.fromBech32('addr1vx2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzers66hrl8');
//   logger.i(address);

//   address = ShelleyAddress.fromBech32(
//       'addr_test1qpu5vlrf4xkxv2qpwngf6cjhtw542ayty80v8dyr49rf5ewvxwdrt70qlcpeeagscasafhffqsxy36t90ldv06wqrk2qum8x5w');
//   logger.i(address);

//   address =
//       ShelleyAddress.fromBech32('addr1q9u5vlrf4xkxv2qpwngf6cjhtw542ayty80v8dyr49rf5ewvxwdrt70qlcpeeagscasafhffqsxy36t90ldv06wqrk2qld6xc3');
//   logger.i(address);
// }
