// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

/// Dump byte array. Example: bytes[20]: 244,155,227,187,150,186,199,61,202,241,76,208,46,192,219,56,241,103,253,67
String b2s(List<int> bytes, {String prefix = 'bytes'}) =>
    "$prefix[${bytes.length}]: ${bytes.join(',')}";
