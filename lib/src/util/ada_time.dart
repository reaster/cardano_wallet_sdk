import 'dart:convert';

import 'dart:math';

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

//slots per second change: https://explorer.cardano.org/en/browse-epochs.html?perPage=50&page=5
//1 slot = 20sec - epoch 207, slot 4492799, block 4490510, 2020/07/29 21:44:31 UTC
//1 slot = 01sec - epoch 208, slot 4492800, block 4490511, 2020/07/29 21:44:51 UTC
//1 slot per 20 seconds:
final millisecondsPerSlot0_207 = 20 * 1000;
final slotsPerEpoch0_207 = 21600;
final firstOneSecondEpoch = 208;
final millisecondsPerEpoch0_207 = slotsPerEpoch0_207 * millisecondsPerSlot0_207;
// 1 slot per second
final firstSlotOfEpoch208 = 4492800;
final millisecondsPerSlotGt207 = 1 * 1000;
final slotsPerEpochGt207 = 432000; //1 slot per second
final millisecondsPerEpochGt207 = slotsPerEpochGt207 * millisecondsPerSlotGt207;
//https://explorer.cardano.org/en/epoch.html?number=0&page=0perPage=10
final epoch0Slot0Utc = DateTime(2017, 9, 23, 21, 44, 51).toUtc();
final epoch0Slot0UtcMs = epoch0Slot0Utc.millisecondsSinceEpoch;

///
/// convert epoch to unix time in milliseconds
///
int epochToMilliseconds({int epoch = 0}) =>
    min(firstOneSecondEpoch, epoch) * millisecondsPerEpoch0_207 +
    max(0, epoch - firstOneSecondEpoch) * millisecondsPerEpochGt207 +
    epoch0Slot0UtcMs;

///
/// convert epoch to UTC timestamp
///
DateTime epochToDateTime({int epoch = 0}) => DateTime.fromMillisecondsSinceEpoch(epochToMilliseconds(epoch: epoch), isUtc: true);

///
/// convert slot to unix time in milliseconds
///
int slotToMilliseconds({int slot = 0}) =>
    min(firstSlotOfEpoch208, slot) * millisecondsPerSlot0_207 +
    max(0, slot - firstSlotOfEpoch208) * millisecondsPerSlotGt207 +
    epoch0Slot0UtcMs;

///
/// convert slot to UTC timestamp
///
DateTime slotToDateTime({int slot = 0}) => DateTime.fromMillisecondsSinceEpoch(slotToMilliseconds(slot: slot), isUtc: true);

///
/// Convert Cardano epoch (epoch * 432000 + 1506203091 in UTC) to DateTime and back.
/// Unix timestamp (seconds since 1970-01-01)
///
// class EpochDateTime extends Codec<int, DateTime> {
//   const EpochDateTime();
//   final encoder = const EpochDateTimeEncoder();
//   final decoder = const EpochDateTimeDecoder();
//   DateTime encode(int epoch) => encoder.convert(epoch);
//   int decode(DateTime dateTime) => decoder.convert(dateTime);
// }

// class EpochDateTimeEncoder extends Converter<int, DateTime> {
//   const EpochDateTimeEncoder();
//   @override
//   DateTime convert(int epoch) => epochToDateTime(epoch: epoch);
// }

// class EpochDateTimeDecoder extends Converter<DateTime, int> {
//   const EpochDateTimeDecoder();
//   @override
//   TODO int convert(DateTime dateTime) => (dateTime.millisecondsSinceEpoch / 432000).round() - 1506203091;
// }

// final epochDateTime = EpochDateTime();
