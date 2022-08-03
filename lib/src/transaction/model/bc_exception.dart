// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

class BcCborDeserializationException implements Exception {
  final String? message;
  BcCborDeserializationException([this.message]);
}
