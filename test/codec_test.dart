// import 'package:cardano_wallet_sdk/src/transaction/spec/shelley_spec.dart';
import 'package:cardano_wallet_sdk/src/util/codec.dart';
// import 'package:cbor/cbor.dart';
// import 'package:hex/hex.dart';
// import 'package:quiver/iterables.dart';
import 'package:test/test.dart';
// import 'dart:convert';
// import 'package:cbor/cbor.dart' as cbor;

///
/// various encoders, decoders and type converters.
///
void main() {
  test('hexFromShelleyAddress', () {
    final addr = 'addr_test1qqy3df0763vfmygxjxu94h0kprwwaexe6cx5exjd92f9qfkry2djz2a8a7ry8nv00cudvfunxmtp5sxj9zcrdaq0amtqmflh6v';
    final addrHexExpected =
        '000916A5FED4589D910691B85ADDF608DCEEE4D9D60D4C9A4D2A925026C3229B212BA7EF8643CD8F7E38D6279336D61A40D228B036F40FEED6';
    final addrHex = hexFromShelleyAddress(addr, uppercase: true);
    print(addrHex);
    expect(addrHex, addrHexExpected);
  });
  test('bech32ShelleyAddressFromBytes', () {
    final hex = '000916A5FED4589D910691B85ADDF608DCEEE4D9D60D4C9A4D2A925026C3229B212BA7EF8643CD8F7E38D6279336D61A40D228B036F40FEED6';
    final bytes = uint8BufferFromHex(hex);
    final addr = bech32ShelleyAddressFromBytes(bytes);
    final addrExpected = 'addr_test1qqy3df0763vfmygxjxu94h0kprwwaexe6cx5exjd92f9qfkry2djz2a8a7ry8nv00cudvfunxmtp5sxj9zcrdaq0amtqmflh6v';
    print(addr);
    expect(addr, addrExpected);
  });
}
