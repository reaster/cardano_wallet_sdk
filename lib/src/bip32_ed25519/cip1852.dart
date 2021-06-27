part of bip32_ed25519.api;

///
/// Using 1852' as the purpose field, we defined the following derivation path
/// `m / purpose' / coin_type' / account' / role / index`
/// Reference: [CIP-1852](https://github.com/cardano-foundation/CIPs/blob/master/CIP-1852/CIP-1852.md)
///
abstract class Cip1852KeyTree extends Bip44KeyTree {
  static final int stakingKey = 2;

  // Change is renamed to role.
  int get role => change;
  void set role(int newRole) => change;

  @override
  final int purpose = Bip32KeyTree.hardenedIndex | 0x1852;
}
