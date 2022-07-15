import 'dart:typed_data';

class BcPointer {
  final int slot; //long
  final int txIndex; //int
  final int certIndex; //int

  const BcPointer(
      {required this.slot, required this.txIndex, required this.certIndex});

  Uint8List get hash => Uint8List.fromList(
      _natEncode(slot) + _natEncode(txIndex) + _natEncode(certIndex));

  List<int> _natEncode(int num) {
    List<int> result = [];
    result.add(num & 0x7f);
    num = num ~/ 128;
    while (num > 0) {
      result.add(num & 0x7f | 0x80);
      num = num ~/ 128;
    }
    return result.reversed.toList();
  }
  //   private byte[] variableNatEncode(long num) {
  //     List<Byte> output = new ArrayList<>();
  //     output.add((byte)(num & 0x7F));

  //     num /= 128;
  //     while(num > 0) {
  //         output.add((byte)((num & 0x7F) | 0x80));
  //         num /= 128;
  //     }
  //     Collections.reverse(output);

  //     return Bytes.toArray(output);
  // }
}
