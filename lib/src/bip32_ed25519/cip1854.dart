part of bip32_ed25519.api;

///
/// `m / purpose' / coin_type' / account' / role / index`
/// Reference: [CIP-1854](https://github.com/cardano-foundation/CIPs/blob/master/CIP-1854/CIP-1854.md)
///
abstract class Cip1854KeyTree extends Cip1852KeyTree {
  static final int stakingKey = 2;

  @override
  final int purpose = Bip32KeyTree.hardenedIndex | 0x1854;
}
