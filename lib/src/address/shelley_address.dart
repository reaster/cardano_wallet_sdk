import 'package:bip32_ed25519/api.dart';
import 'package:bip32_ed25519/cardano.dart';
import 'package:cardano_wallet_sdk/src/network/cardano_network.dart';
//import 'package:pinenacl/digests.dart';

///
/// Address format
///
/// [see](https://cips.cardano.org/cips/cip19/)
///
/// [github source](https://github.com/ilap/bip32-ed25519-dart)
///
/// [reference](https://hydra.iohk.io/build/6141104/download/1/delegation_design_spec.pdf)
///
enum AddressType { Base, Pointer, Enterprise, Reward }
enum CredentialType { Key, Script }

String credentialString(CredentialType type) => type == CredentialType.Key ? 'key' : 'script';
String networkIdString(NetworkId id) => id == NetworkId.mainnet ? 'mainnet' : 'testnet';
String addressTypeString(AddressType type) {
  final s = type.toString();
  return s.substring(s.lastIndexOf('.') + 1);
}

abstract class CredentialHash28 extends ByteList {
  int get kind;
  CredentialType get type => kind == CredentialType.Key.index ? CredentialType.Key : CredentialType.Script;
  static const hashLength = 28;
  CredentialHash28(List<int> bytes) : super(bytes, hashLength);
}

class KeyHash28 extends CredentialHash28 {
  KeyHash28(List<int> bytes) : super(bytes);

  @override
  int get kind => CredentialType.Key.index;
}

class ScriptHash28 extends CredentialHash28 {
  ScriptHash28(List<int> bytes) : super(bytes);

  @override
  int get kind => CredentialType.Script.index;
}

abstract class ShelleyAddress extends ByteList {
  static const defaultPrefix = 'addr';
  static const defaultTail = '_test';

  final NetworkId networkId;

  ShelleyAddress(this.networkId, List<int> bytes) : super(bytes);

  AddressType get addressType;

  CredentialType get credentialType => _isScript(super[0], bit: 4) ? CredentialType.Script : CredentialType.Key;

  static String _computeHrp(NetworkId id, String prefix) {
    return id == NetworkId.testnet ? prefix + ShelleyAddress.defaultTail : prefix;
  }

  String toBech32({String? prefix}) {
    prefix ??= _computeHrp(networkId, defaultPrefix);

    return this.encode(Bech32Coder(hrp: prefix));
  }

  @override
  String toString() {
    return "${addressTypeString(addressType)} ${networkIdString(networkId)} ${credentialString(credentialType)} ${toBech32()}";
  }

  static ShelleyAddress fromBech32(String address) {
    final decoded = bech32.decode(address, 256);
    final hrp = decoded.hrp;

    final bytes = Bech32Coder(hrp: hrp).decode(address);
    return fromBytes(bytes);
  }

  static ShelleyAddress fromBytes(List<int> bytes) {
    final header = bytes[0];
    final networkId = NetworkId.values[header & 0x0f];

    final addrType = (header & 0xf0) >> 4;
    switch (addrType) {
      // Base Address
      case 0:
      case 1:
      case 2:
      case 3:
        if (bytes.length != 1 + CredentialHash28.hashLength * 2) {
          // FIXME: Create proper error classes
          throw Error();
        }
        return BaseAddress(networkId, _getCredentialType(header, bytes.getRange(1, 29).toList(), bit: 4),
            _getCredentialType(header, bytes.skip(1 + CredentialHash28.hashLength).toList(), bit: 5));

      // Pointer Address
      case 4:
      case 5:
        break;

      // Enterprise Address
      case 6:
      case 7:
        if (bytes.length != 1 + CredentialHash28.hashLength) {
          // FIXME: Create proper error classes
          throw Error();
        }
        return EnterpriseAddress(networkId, _getCredentialType(header, bytes.skip(1).toList(), bit: 4));

      // Stake (chmeric) Address
      case 14:
      case 15:
        if (bytes.length != 1 + CredentialHash28.hashLength) {
          // FIXME: Create proper error classes
          throw Error();
        }
        return RewardAddress(networkId, _getCredentialType(header, bytes.skip(1).toList(), bit: 4));

      default:
        throw Exception('Unsupported Cardano Address, type: $header');
    }

    throw Error();
  }

  static CredentialHash28 _getCredentialType(int header, List<int> bytes, {required int bit}) {
    return _isScript(header, bit: bit) ? ScriptHash28(bytes) : KeyHash28(bytes);
  }

  /// If the nth bit is 0 that means it's a key hash, otherwise it's script hash.
  ///
  static bool _isScript(int header, {required int bit}) => header & (1 << bit) != 0;

  static List<int> _computeBytes(NetworkId networkId, AddressType addresType, CredentialHash28 paymentBytes,
      {CredentialHash28? stakeBytes}) {
    //int header = networkId.index & 0x0f;

    switch (addresType) {
      case AddressType.Base:
        if (stakeBytes == null) {
          throw Exception('Base address requires Stake credential');
        }
        final header = (networkId.index & 0x0f) | (paymentBytes.kind << 4) | (stakeBytes.kind << 5);
        return [header] + paymentBytes + stakeBytes;
      case AddressType.Enterprise:
        final header = 0x60 | (networkId.index & 0x0f) | (paymentBytes.kind << 4);
        return [header] + paymentBytes;
      //case AddressType.Pointer:
      case AddressType.Reward:
        final header = 0xe0 | (networkId.index & 0x0f) | (paymentBytes.kind << 4);
        return [header] + paymentBytes;
      default:
        throw Exception('Unsupported address header');
    }
  }
}

class BaseAddress extends ShelleyAddress {
  BaseAddress(
    NetworkId networkId,
    CredentialHash28 paymentBytes,
    CredentialHash28 stakeBytes,
  ) : super(networkId, ShelleyAddress._computeBytes(networkId, AddressType.Base, paymentBytes, stakeBytes: stakeBytes));
  BaseAddress.fromKeys(
    NetworkId networkId,
    Bip32Key paymentKey,
    Bip32Key stakeKey,
  ) : this(networkId, _toHash(paymentKey), _toHash(stakeKey));
  AddressType get addressType => AddressType.Base;
  static CredentialHash28 _toHash(Bip32Key key) {
    return KeyHash28(key.buffer.asInt32List());
  } //TODO just a hack
}

class EnterpriseAddress extends ShelleyAddress {
  EnterpriseAddress(NetworkId networkId, CredentialHash28 bytes)
      : super(networkId, ShelleyAddress._computeBytes(networkId, AddressType.Enterprise, bytes));
  AddressType get addressType => AddressType.Enterprise;
}

class PointerAddress extends ShelleyAddress {
  PointerAddress(NetworkId networkId, CredentialHash28 bytes)
      : super(networkId, ShelleyAddress._computeBytes(networkId, AddressType.Pointer, bytes));
  AddressType get addressType => AddressType.Pointer;
}

class RewardAddress extends ShelleyAddress {
  RewardAddress(NetworkId networkId, CredentialHash28 bytes)
      : super(networkId, ShelleyAddress._computeBytes(networkId, AddressType.Reward, bytes));
  AddressType get addressType => AddressType.Reward;
}

void main() {
  const seed = '475083b81730de275969b1f18db34b7fb4ef79c66aa8efdd7742f1bcfe204097';
  const addressPath = "m/1852'/1815'/0'/0/0";
  const rewardAddressPath = "m/1852'/1815'/0'/2/0";

  final icarusKeyTree = CardanoKeyIcarus.seed(seed);

  // final Bip32Key addressKey = icarusKeyTree.forPath(addressPath);
  // print(addressKey);
  // final Bip32Key rewardKey = icarusKeyTree.forPath(rewardAddressPath);
  // print(rewardKey);

  final addressKey = icarusKeyTree.pathToKey(addressPath);
  print(addressKey);
  final rewardKey = icarusKeyTree.pathToKey(rewardAddressPath);
  print(rewardKey);
  final addr1 = BaseAddress.fromKeys(NetworkId.testnet, addressKey, rewardKey);
  print(addr1);

  var address = ShelleyAddress.fromBech32(
      'addr_test1qz2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3jcu5d8ps7zex2k2xt3uqxgjqnnj83ws8lhrn648jjxtwq2ytjqp');
  print(address);

  address =
      ShelleyAddress.fromBech32('addr1qx2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3jcu5d8ps7zex2k2xt3uqxgjqnnj83ws8lhrn648jjxtwqfjkjv7');
  print(address);

  address = ShelleyAddress.fromBech32('addr_test1vz2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzerspjrlsz');
  print(address);

  address = ShelleyAddress.fromBech32('addr1vx2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzers66hrl8');
  print(address);

  address = ShelleyAddress.fromBech32(
      'addr_test1qpu5vlrf4xkxv2qpwngf6cjhtw542ayty80v8dyr49rf5ewvxwdrt70qlcpeeagscasafhffqsxy36t90ldv06wqrk2qum8x5w');
  print(address);

  address =
      ShelleyAddress.fromBech32('addr1q9u5vlrf4xkxv2qpwngf6cjhtw542ayty80v8dyr49rf5ewvxwdrt70qlcpeeagscasafhffqsxy36t90ldv06wqrk2qld6xc3');
  print(address);
}
