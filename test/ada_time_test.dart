// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart';
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
  group('EpochDateTime -', () {
    // test('codec', () {
    //   final slot0DateTime = DateTime(2017, 9, 23, 21, 44, 51).toUtc();
    //   final slot0EpochMsUtc = slot0DateTime.millisecondsSinceEpoch;
    //   final now0 = DateTime.fromMillisecondsSinceEpoch(137 * 432000 * 1000 + 1506203091, isUtc: true);
    //   final now1 = epochDateTime.encode(137);
    //   final epoch = epochDateTime.decode(now1);
    //   final now2 = epochDateTime.encode(epoch);
    //   print("$now1 -> epochDateTime: -> $epoch");
    //   expect(now1, equals(now2));
    // });
    test('epoch to unix time milliseconds', () {
      final _epoch0Slot0Utc = epochToDateTime(epoch: 0);
      expect(_epoch0Slot0Utc, epoch0Slot0Utc);

      //last slot of epoch 207, slot 4492799, block 4490510, 2020/07/29 21:44:31
      final epoch207UtcBase = DateTime(2020, 7, 24, 21, 44, 51).toUtc();
      final epoch207Ut = epochToDateTime(epoch: 207);
      expect(epoch207Ut, epoch207UtcBase);

      //TODO past 207 epochs are off by 1 hour
      //Epoch	Start Date	Stake Snapshot for Epoch	Rewards Paid for Epoch
      //239	Thu 31 Dec 2020 (21:45:00 UTC)	240	237, 2020/12/31 21:44:51
      final epoch239UtcBase = DateTime(2020, 12, 31, 20, 44, 51).toUtc();
      final epoch239Utc = epochToDateTime(epoch: 239);
      expect(epoch239Utc, epoch239UtcBase);

      //Epoch	Start Date	Stake Snapshot for Epoch	Rewards Paid for Epoch
      //309	Thu 16 Dec 2021 (21:45:00 UTC)	310	307
      final epoch309UtcBase = DateTime(2021, 12, 16, 20, 44, 51).toUtc();
      final epoch309Utc = epochToDateTime(epoch: 309);
      expect(epoch309Utc, epoch309UtcBase);
    }, skip: 'this test is off by 1 hour when run on github linux box');
    test('slot to unix time milliseconds', () {
      final epoch0Slot9UtcBase = DateTime(2017, 9, 23, 21, 47, 51).toUtc();
      final epoch0Slot9Utc = slotToDateTime(slot: 9);
      expect(epoch0Slot9Utc, epoch0Slot9UtcBase);

      // https://explorer.cardano.org/en/epoch.html?number=136&page=0&perPage=10
      // 136, 2937600, 2936067, 2019/08/04 21:44:51
      final slot2937600UtcBase = DateTime(2019, 8, 4, 21, 44, 51).toUtc();
      final slot2937600Utc = slotToDateTime(slot: 2937600);
      expect(slot2937600Utc, slot2937600UtcBase);

      // 278, 35164786, 6001557, 2021/07/19 21:44:37
      final slot35164786UtcBase = DateTime(2021, 7, 19, 21, 44, 37).toUtc();
      final slot35164786Utc = slotToDateTime(slot: 35164786);
      expect(slot35164786Utc, slot35164786UtcBase);
    });
  });
}
