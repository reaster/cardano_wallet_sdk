import 'dart:convert';

///
/// Convert Cardano block time (secondsSinceEpoch in UTC) to DateTime and back.
///
class AdaDateTime extends Codec<int, DateTime> {
  const AdaDateTime();
  final encoder = const AdaDateTimeEncoder();
  final decoder = const AdaDateTimeDecoder();
  DateTime encode(int secondsSinceEpoch) => encoder.convert(secondsSinceEpoch);
  int decode(DateTime dateTime) => decoder.convert(dateTime);
}

class AdaDateTimeEncoder extends Converter<int, DateTime> {
  const AdaDateTimeEncoder();
  @override
  DateTime convert(int secondsSinceEpoch) => DateTime.fromMillisecondsSinceEpoch(secondsSinceEpoch * 1000, isUtc: true);
}

class AdaDateTimeDecoder extends Converter<DateTime, int> {
  const AdaDateTimeDecoder();
  @override
  int convert(DateTime dateTime) => (dateTime.millisecondsSinceEpoch / 1000).round();
}

final adaDateTime = AdaDateTime();
