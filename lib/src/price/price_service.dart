import 'package:oxidized/oxidized.dart';

class Price {
  final String fromTicker;
  final String toTicker;
  final int timestamp;
  final double value;

  Price({this.fromTicker = 'ADA', this.toTicker = 'USD', this.timestamp = 0, this.value = 0.0});

  DateTime dateTime() => DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true);
  @override
  String toString() {
    return 'Price(from: $fromTicker, to: $toTicker, value: $value, timestamp: ${dateTime()}';
  }
}

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
