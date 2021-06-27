part of bip32_ed25519.api;

///
/// `m / purpose' / coin_type' / account' / change / address_index`
/// Reference: [BIP-0044](https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki)
///
abstract class Bip44KeyTree extends Bip43KeyTree {
  /// Purpose, defaults to Bip44 i.e. 44'
  @override
  final int purpose = Bip32KeyTree.hardenedIndex | 44;

  /// Coin Type, defaults to 0' the Bitcoin. Not used in Cardano
  final int coinType = Bip32KeyTree.hardenedIndex;

  /// Account,  defaults to 0' the first account index
  final int account = Bip32KeyTree.hardenedIndex;

  static final int external = 0;
  static final int internal = 1;

  /// Change, defaults to the external keys
  final int change = external;

  /// Address Index, defaults to the first address key
  final int addressIndex = 0;
}
