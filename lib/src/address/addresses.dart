// import 'package:built_value/built_value.dart';
// import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';

//part 'addresses.g.dart';

///
/// BIP-0044 Multi-Account Hierarchy for Deterministic Wallets is a Bitcoin standard defining a structure
/// and algorithm to build a hierarchy tree of keys from a single root private key. Note that this is the
/// derivation scheme used by Icarus / Yoroi.
///
/// It is built upon BIP-0032 and is a direct application of BIP-0043. It defines a common representation
/// of addresses as a multi-level tree of derivations:
///
///    m / purpose' / coin_type' / account_ix' / change_chain / address_ix
///
/// Where m is the private key, purpose is 1852 for Cardano, coin_type is 1815 for ADA, account_ix is a zero-
/// based index defaulting to 0, change_chain is generaly 1 for change, address_ix is a zero-based index
/// defaulting to 0.
/// see https://docs.cardano.org/projects/cardano-wallet/en/latest/About-Address-Derivation.html
///
abstract class Addresses //implements Built<Addresses, AddressesBuilder>
{
  static final String defaultPurpose = '1852';
  static final String defaultCoinAda = '1815';
  static final int defaultAccountIx = 0;
  String get purrpose;
  String get coinType;
  int get accountIx;
  String get walletPrivateKey;
  String get walletPubliceKey;
  String get purposePrivateKey;
  String get coinTypePrivateKey;
  BuiltList<String> get account;
  BuiltList<String> get change;
  BuiltList<String> get address;
}
