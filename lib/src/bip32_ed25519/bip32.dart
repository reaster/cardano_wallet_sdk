part of bip32_ed25519.api;

class ChainCode extends ByteList {
  ChainCode(ByteList bytes) : super(bytes, chainCodeLength);
  static const int chainCodeLength = 32;
}

mixin Bip32Key on AsymmetricKey {
  ChainCode get chainCode;
  ByteList get rawKey;
  Bip32Key derive(int index);
}

mixin Bip32PrivateKey on AsymmetricPrivateKey implements Bip32Key {
  final int depth = 0;
}

mixin Bip32PublicKey on AsymmetricPublicKey implements Bip32Key {}

mixin Bip32 implements Bip32ChildKeyDerivaton, Bip32KeyTree {}

abstract class Bip32ChildKeyDerivaton {
  /// Private parent key to private child key
  Bip32PrivateKey ckdPriv(Bip32PrivateKey parentSecret, int index);

  /// Public parent key to public child key
  Bip32PublicKey ckdPub(Bip32PublicKey parentSecret, int index);

  /// Private parent key to public Child key
  Bip32PublicKey neuterPriv(Bip32PrivateKey parentSecret);

  /// Public parent key to private child key
  /// It is imposibble

}

/// Key Tree
///
/// Each leaf node in the tree corresponds to an actual key, while the
/// internal nodes correspond to the collections of keys that descend from
/// them. The chain codes of the leaf nodes are ignored, and only their
/// embedded private or public key is relevant. Because of this construction,
/// knowing an extended private key allows reconstruction of all descendant
/// private keys and public keys, and knowing an extended public keys allows
/// reconstruction of all descendant non-hardened public keys
/// Source: [BIP-0032](https://en.bitcoin.it/wiki/BIP_0032#The_key_tree)
///
abstract class Bip32KeyTree {
  late final Bip32Key root;

  static const int maxIndex = 0xFFFFFFFF;
  static const int hardenedIndex = 0x80000000;
  static const String _hardenedSuffix = "'";
  static const String _privateKeyPrefix = 'm';
  static const String _publicKeyPrefix = 'M';

  bool get isPrivate => root is Bip32PrivateKey;

  Bip32Key master(Uint8List seed);
  Bip32Key doImport(String key);

  Bip32Key pathToKey(String path) {
    final kind = path.split('/').removeAt(0);

    if (![_privateKeyPrefix, _publicKeyPrefix].contains(kind)) {
      throw Exception("Path needs to start with 'm' or 'M'");
    }

    if (kind == _privateKeyPrefix && root is Bip32PublicKey) {
      throw Exception('Cannot derive private key from public master');
    }

    final wantsPrivate = kind == _privateKeyPrefix;
    final children = _parseChildren(path);

    if (children.isEmpty) {
      if (wantsPrivate) {
        return root;
      }
      return root.publicKey as Bip32Key;
    }

    return children.fold(root, (previousKey, childNumber) {
      return previousKey.derive(childNumber);
    });
  }

  static String indexToPathNotation(int index) {
    // TODO: create proper error class
    if (index >= maxIndex) {
      throw Error();
    }

    return index < hardenedIndex
        ? index.toString()
        : '${index - hardenedIndex}\'';
  }

  Iterable<int> _parseChildren(String path) {
    final explodedList = path.split('/')
      ..removeAt(0)
      ..removeWhere((child) => child == '');

    return explodedList.map((pathFragment) {
      if (pathFragment.endsWith(_hardenedSuffix)) {
        pathFragment = pathFragment.substring(0, pathFragment.length - 1);
        return int.parse(pathFragment) + hardenedIndex;
      } else {
        return int.parse(pathFragment);
      }
    });
  }
}
