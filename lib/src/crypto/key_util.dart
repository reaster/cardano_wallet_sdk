import 'package:cardano_wallet_sdk/src/util/blake2bhash.dart';
import 'package:hex/hex.dart';
import 'package:pinenacl/ed25519.dart';

class KeyUtil {
  static SigningKey generateSigningKey() => SigningKey.generate();

  static VerifyKey verifyKey({required SigningKey signingKey}) =>
      signingKey.verifyKey;

  static String keyHash({required VerifyKey verifyKey}) =>
      HEX.encode(blake2bHash224(verifyKey));
}
