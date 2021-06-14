import 'package:cardano_wallet_sdk/src/util/ada_time.dart';
import 'package:test/test.dart';

void main() {
  group('AdaDateTime -', () {
    test('codec', () {
      final now = DateTime.utc(2017, 9, 7, 17, 30, 59);
      final timestamp = adaDateTime.decode(now);
      final now2 = adaDateTime.encode(timestamp);
      print("$now -> secondsSinceEpoch: $timestamp -> $now2");
      expect(now, equals(now2));
    });
  });
}
