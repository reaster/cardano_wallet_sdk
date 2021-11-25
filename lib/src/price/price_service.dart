// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:oxidized/oxidized.dart';

///
/// Used for tracking currency trading pair prices (i.e. ADA to USD).
///
/// TODO simple ticker names won't work with Cardano Native tokens which use a policyId and coin name.
///
class Price {
  final String fromTicker;
  final String toTicker;
  final int timestamp;
  final double value;

  Price(
      {this.fromTicker = 'ADA',
      this.toTicker = 'USD',
      this.timestamp = 0,
      this.value = 0.0});

  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true);

  @override
  String toString() {
    return 'Price(from: $fromTicker, to: $toTicker, value: $value, timestamp: $dateTime';
  }

  Duration get lastUpdated => DateTime.now().difference(dateTime);

  String get briefLastUpdated {
    final update = lastUpdated;
    if (update.inDays > 1) {
      return "${update.inDays}d ago";
    } else if (update.inHours > 1) {
      return "${update.inHours}h ago";
    } else if (update.inMinutes > 1) {
      return "${update.inMinutes}m ago";
    } else {
      return "${update.inSeconds}s ago";
    }
  }
}

/// not being used at the moment. see price_polling_service
abstract class PriceService {
  ///
  /// retrieve current ratio of to currency to from currency.
  /// example: priceService(from:'BTC', to:'USD') -> 55234.654
  ///
  Future<Result<Price, String>> currentPrice({String from, String to});

  ///
  /// check coingecko service
  ///
  Future<Result<bool, String>> ping();

  ///
  /// list all coins supported by price service
  /// returns map where the key is the ticker and the value is the crypto's name
  Future<Result<Map<String, String>, String>> list();
}
