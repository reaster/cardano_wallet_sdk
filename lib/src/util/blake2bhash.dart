// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:pinenacl/digests.dart';
import 'package:pinenacl/encoding.dart';

///
/// Base blake2b hash function can produce hashes of arbirary size.
///
List<int> blake2bHash(List<int> stringBytes, {required int digestSize}) =>
    Hash.blake2b(Uint8List.fromList(stringBytes), digestSize: digestSize);

List<int> blake2bHash160(List<int> stringBytes) =>
    blake2bHash(stringBytes, digestSize: 20);

List<int> blake2bHash224(List<int> stringBytes) =>
    blake2bHash(stringBytes, digestSize: 28);

List<int> blake2bHash256(List<int> stringBytes) =>
    blake2bHash(stringBytes, digestSize: 32);
