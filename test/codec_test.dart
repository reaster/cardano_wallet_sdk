// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
import 'package:test/test.dart';

///
/// various encoders, decoders and type converters.
///
void main() {
  test('hexFromShelleyAddress', () {
    const addr =
        'addr_test1qqy3df0763vfmygxjxu94h0kprwwaexe6cx5exjd92f9qfkry2djz2a8a7ry8nv00cudvfunxmtp5sxj9zcrdaq0amtqmflh6v';
    const addrHexExpected =
        '000916A5FED4589D910691B85ADDF608DCEEE4D9D60D4C9A4D2A925026C3229B212BA7EF8643CD8F7E38D6279336D61A40D228B036F40FEED6';
    final addrHex = hexFromShelleyAddress(addr, uppercase: true);
    print(addrHex);
    expect(addrHex, addrHexExpected);
  });
  test('bech32ShelleyAddressFromBytes', () {
    const hex =
        '000916A5FED4589D910691B85ADDF608DCEEE4D9D60D4C9A4D2A925026C3229B212BA7EF8643CD8F7E38D6279336D61A40D228B036F40FEED6';
    final bytes = uint8BufferFromHex(hex);
    final addr = bech32ShelleyAddressFromBytes(bytes);
    const addrExpected =
        'addr_test1qqy3df0763vfmygxjxu94h0kprwwaexe6cx5exjd92f9qfkry2djz2a8a7ry8nv00cudvfunxmtp5sxj9zcrdaq0amtqmflh6v';
    print(addr);
    expect(addr, addrExpected);
  });
}
