import 'package:hex/hex.dart';
import 'dart:convert';

final Codec<String, String> str2hex = utf8.fuse(HEX);
final Codec<String, String> hex2str = str2hex.inverted;
