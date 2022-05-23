// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pinenacl/key_derivation.dart';
import 'package:hex/hex.dart';
import 'package:crypto/crypto.dart' show sha256;
// import 'utils/pbkdf2.dart';

/// symbolic typedef for a validated mnemonic phrase
typedef ValidMnemonicPhrase = List<String>;

/// supported mnemonic languages
enum MnemonicLang { english, french, italian, japanese, korean, spanish }

/// function loads mnemonic dictionary for the specified langauge.
/// This abstaction enables multi-language support.
typedef LoadMnemonicWordsFunction = List<String> Function(
    {required MnemonicLang lang});

/// Generate a unique (default: 24-word) mnumonic phrase which can be used to create a
/// new wallet.
ValidMnemonicPhrase generateNewMnemonic(
        {int strength = 256,
        required LoadMnemonicWordsFunction loadWordsFunction,
        RandomBytes randomBytes = _randomBytes,
        MnemonicLang lang = MnemonicLang.english}) =>
    (_generateMnemonic(
        strength: strength,
        loadWordsFunction: loadWordsFunction,
        lang: lang,
        randomBytes: randomBytes));

/// return hex encoded entropy form mnemonic
String mnemonicToEntropyHex(
        {required ValidMnemonicPhrase mnemonic,
        required LoadMnemonicWordsFunction loadWordsFunction,
        MnemonicLang lang = MnemonicLang.english}) =>
    _toHex(mnemonicWordsToEntropyBytes(
        mnemonic: mnemonic, loadWordsFunction: loadWordsFunction, lang: lang));

/// translate a hex entropy back to mnemonic phrase
ValidMnemonicPhrase entropyHexToMnemonic(
        {required String entropyHex,
        required LoadMnemonicWordsFunction loadWordsFunction,
        MnemonicLang lang = MnemonicLang.english}) =>
    entropyBytesToMnemonic(
        entropyBytes: Uint8List.fromList(HEX.decode(entropyHex)),
        loadWordsFunction: loadWordsFunction,
        lang: lang);

/// return raw seed form mnemonic - NOT USED BY CARDANO!
Uint8List mnemonicToSeed(ValidMnemonicPhrase mnemonic,
        {String passphrase = ''}) =>
    _mnemonicToSeed(mnemonic.join(' '), passphrase: passphrase);

/// return seed in hex form mnemonic - NOT USED BY CARDANO!
String mnemonicToSeedHex(ValidMnemonicPhrase mnemonic,
        {String passphrase = ''}) =>
    _toHex(_mnemonicToSeed(mnemonic.join(' '), passphrase: passphrase));

/// Loads mnemonic words for given language.
/// Throws ArgumentError for unsuported languages.
/// This is a slow synchronous call, cache results for multiple access.
/// use await rootBundle.loadString(path)?
// List<String> loadMnemonicWordsSync({required MnemonicLang lang}) {
//   switch (lang) {
//     case MnemonicLang.english:
//       return _englishWordList;
//     default:
//       throw ArgumentError("${lang.name} mnemonic language not supported");
//   }
// }

const int _sizeByte = 255;
const _invalidMnemonic = 'Invalid mnemonic';
const _invalidEntropy = 'Invalid entropy';
const _invalidChecksum = 'Invalid mnemonic checksum';

typedef RandomBytes = Uint8List Function(int size);

int _binaryToByte(String binary) {
  return int.parse(binary, radix: 2);
}

String _bytesToBinary(Uint8List bytes) {
  return bytes.map((byte) => byte.toRadixString(2).padLeft(8, '0')).join('');
}

String _toHex(Uint8List bytes) => bytes.map((byte) {
      return byte.toRadixString(16).padLeft(2, '0');
    }).join('');

//Uint8List _createUint8ListFromString( String s ) {
//  var ret = new Uint8List(s.length);
//  for( var i=0 ; i<s.length ; i++ ) {
//    ret[i] = s.codeUnitAt(i);
//  }
//  return ret;
//}

String _deriveChecksumBits(Uint8List entropy) {
  final ent = entropy.length * 8;
  final cs = ent ~/ 32;
  final hash = sha256.convert(entropy);
  return _bytesToBinary(Uint8List.fromList(hash.bytes)).substring(0, cs);
}

Uint8List _randomBytes(int size) {
  final rng = Random.secure();
  final bytes = Uint8List(size);
  for (var i = 0; i < size; i++) {
    bytes[i] = rng.nextInt(_sizeByte);
  }
  return bytes;
}

ValidMnemonicPhrase _generateMnemonic({
  int strength = 128,
  required LoadMnemonicWordsFunction loadWordsFunction,
  MnemonicLang lang = MnemonicLang.english,
  RandomBytes randomBytes = _randomBytes,
}) {
  assert(strength % 32 == 0);
  final entropy = randomBytes(strength ~/ 8);
  return entropyBytesToMnemonic(
      entropyBytes: entropy, loadWordsFunction: loadWordsFunction, lang: lang);
}

ValidMnemonicPhrase entropyBytesToMnemonic(
    {required Uint8List entropyBytes,
    required LoadMnemonicWordsFunction loadWordsFunction,
    MnemonicLang lang = MnemonicLang.english}) {
  //final entropy = Uint8List.fromList(HEX.decode(entropyString));
  if (entropyBytes.length < 16) {
    throw ArgumentError(_invalidEntropy);
  }
  if (entropyBytes.length > 32) {
    throw ArgumentError(_invalidEntropy);
  }
  if (entropyBytes.length % 4 != 0) {
    throw ArgumentError(_invalidEntropy);
  }
  final entropyBits = _bytesToBinary(entropyBytes);
  final checksumBits = _deriveChecksumBits(entropyBytes);
  final bits = entropyBits + checksumBits;
  final regex = RegExp(r".{1,11}", caseSensitive: false, multiLine: false);
  final chunks = regex
      .allMatches(bits)
      .map((match) => match.group(0)!)
      .toList(growable: false);
  List<String> wordlist = loadWordsFunction(lang: lang);
  ValidMnemonicPhrase words =
      chunks.map((binary) => wordlist[_binaryToByte(binary)]).toList();
  return words;
}

/// To create binary seed from mnemonic, we use PBKDF2 function with mnemonic
/// sentence (in UTF-8) used as a password and string "mnemonic" + passphrase
/// (again in UTF-8) used as a salt. Iteration count is set to 2048 and
/// HMAC-SHA512 is used as a pseudo-random function. Desired length of the
/// derived key is 512 bits (= 64 bytes).
/// Note: non-english mnemonics with the same entropy will produce different hashes.
/// NOT USED BY CARDANO!
Uint8List _mnemonicToSeed(String mnemonic, {String passphrase = ""}) {
  //old call to PointyCastle code:
  //  final pbkdf2 = PBKDF2();
  //  return pbkdf2.process(mnemonic, passphrase: passphrase);
  //  new code calls PineNACL:
  //java version:
  //  String pass = Utils.SPACE_JOINER.join(words);
  //  String salt = "mnemonic" + passphrase;
  //  byte[] seed = PBKDF2SHA512.derive(pass, salt, PBKDF2_ROUNDS, 64);
  const iterationCount = 2048;
  const desiredKeyLength = 64;
  final passwordBytes = Uint8List.fromList(mnemonic.codeUnits);
  final saltBytes = Uint8List.fromList(utf8.encode('mnemonic' + passphrase));
  return PBKDF2.hmac_sha512(
      passwordBytes, saltBytes, iterationCount, desiredKeyLength);
}

// String _mnemonicToSeedHex(String mnemonic, {String passphrase = ""}) =>
//     _toHex(_mnemonicToSeed(mnemonic, passphrase: passphrase));

bool validateMnemonic(
    {required ValidMnemonicPhrase mnemonic,
    required LoadMnemonicWordsFunction loadWordsFunction,
    MnemonicLang lang = MnemonicLang.english}) {
  try {
    mnemonicWordsToEntropyBytes(
        mnemonic: mnemonic, loadWordsFunction: loadWordsFunction, lang: lang);
  } catch (e) {
    return false;
  }
  return true;
}

//TODO remove legacy API
// String _mnemonicToEntropy(String mnemonic, {required MnemonicLang lang}) {
//   var words = mnemonic.split(' ');
//   Uint8List entropyBytes = mnemonicWordsToEntropyBytes(words, lang: lang);
//   return _toHex(entropyBytes);
// }

/// Convert mnemonic phrase to entropy bytes for BIP39 defined language dictionary
/// throw StateError for length issues
/// throw ArgumentError for invalid words
Uint8List mnemonicWordsToEntropyBytes(
    {required ValidMnemonicPhrase mnemonic,
    required LoadMnemonicWordsFunction loadWordsFunction,
    MnemonicLang lang = MnemonicLang.english}) {
  final wordlist = loadWordsFunction(lang: lang);
  return mnemonicWordsToEntropyBytesUsingWordList(
      mnemonic: mnemonic, wordList: wordlist);
}

/// Convert mnemonic phrase to entropy bytes using BIP39 defined word list
/// throw StateError for length issues
/// throw ArgumentError for invalid words
Uint8List mnemonicWordsToEntropyBytesUsingWordList({
  required ValidMnemonicPhrase mnemonic,
  required List<String> wordList,
}) {
  if (mnemonic.length % 3 != 0) {
    throw StateError(_invalidMnemonic);
  }
  // convert word indices to 11 bit binary strings
  final bits = mnemonic.map((word) {
    final index = wordList.indexOf(word);
    if (index == -1) {
      throw ArgumentError(_invalidMnemonic);
    }
    return index.toRadixString(2).padLeft(11, '0');
  }).join('');
  // split the binary string into ENT/CS
  final dividerIndex = (bits.length / 33).floor() * 32;
  final entropyBits = bits.substring(0, dividerIndex);
  final checksumBits = bits.substring(dividerIndex);

  // calculate the checksum and compare
  final regex = RegExp(r".{1,8}");
  final entropyBytes = Uint8List.fromList(regex
      .allMatches(entropyBits)
      .map((match) => _binaryToByte(match.group(0)!))
      .toList(growable: false));
  if (entropyBytes.length < 16) {
    throw StateError(_invalidEntropy);
  }
  if (entropyBytes.length > 32) {
    throw StateError(_invalidEntropy);
  }
  if (entropyBytes.length % 4 != 0) {
    throw StateError(_invalidEntropy);
  }
  final newChecksum = _deriveChecksumBits(entropyBytes);
  if (newChecksum != checksumBits) {
    throw StateError(_invalidChecksum);
  }
  return entropyBytes;
}
// List<String>> _loadWordList() {
//   final res = new Resource('package:bip39/src/wordlists/english.json').readAsString();
//   List<String> words = (json.decode(res) as List).map((e) => e.toString()).toList();
//   return words;
// }
//
// static Uint8List hmac_sha512(Uint8List password, Uint8List salt, int count, int key_length)
//
// final int iterationCount = 2048;
// final int = desiredKeyLength = 64
// final passwordBytes = Uint8List.fromList(mnemonic.codeUnits);
// final saltBytes = Uint8List.fromList(utf8.encode('mnemonic'+salt));
// PBKDF2.hmac_sha512(passwordBytes, saltBytes, iterationCount, desiredKeyLength);
//
// class PBKDF2 {
//   final int blockLength;
//   final int iterationCount;
//   final int desiredKeyLength;
//   final String saltPrefix = "mnemonic";

//   PBKDF2KeyDerivator _derivator;

//   PBKDF2({
//     this.blockLength = 128,
//     this.iterationCount = 2048,
//     this.desiredKeyLength = 64,
//   }) : _derivator =
//             new PBKDF2KeyDerivator(new HMac(new SHA512Digest(), blockLength));

//   Uint8List process(String mnemonic, {passphrase: ""}) {
//     final salt = Uint8List.fromList(utf8.encode(saltPrefix + passphrase));
//     _derivator.reset();
//     _derivator
//         .init(new Pbkdf2Parameters(salt, iterationCount, desiredKeyLength));
//     return _derivator.process(new Uint8List.fromList(mnemonic.codeUnits));
//   }
// }
