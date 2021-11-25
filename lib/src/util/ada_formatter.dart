// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:intl/intl.dart';

///
/// ADA-specific currency formatter that expects all curreny to be in lovelace and
/// converts it to ADA (1 ADA = 1,000,000 lovelace). Compact formatters replace groups of
/// zeros with quantity abbreviation suffixes (i.e. K=thousond, M=million, B=billion & T=trillion).
/// The simple formatters group zeros into threes.
/// Decimal digits defaults to 6 places.
/// The currency factory method allows complete customization.
///
class AdaFormattter {
  static const symbol =
      '₳'; // https://github.com/yonilevy/crypto-currency-symbols
  static const ada = 'ADA ';
  final NumberFormat formatter;

  AdaFormattter({required this.formatter});

  /// Create a [NumberFormat] that formats using the locale's CURRENCY_PATTERN.
  ///
  /// If [locale] is not specified, it will use the current default locale.
  ///
  /// If [name] is specified, the currency with that ISO 4217 name will be used.
  /// Otherwise we will use the default currency name for the current locale. If
  /// no [symbol] is specified, we will use the currency name in the formatted
  /// result. e.g.
  ///       var f = NumberFormat.currency(locale: 'en_US', name: 'EUR')
  /// will format currency like "EUR1.23". If we did not specify the name, it
  /// would format like "USD1.23".
  ///
  /// If [symbol] is used, then that symbol will be used in formatting instead
  /// of the name. e.g.
  ///       var eurosInCurrentLocale = NumberFormat.currency(symbol: "€");
  /// will format like "€1.23". Otherwise it will use the currency name.
  /// If this is not explicitly specified in the constructor, then for
  /// currencies we use the default value for the currency if the name is given,
  /// otherwise we use the value from the pattern for the locale.
  ///
  /// If [decimalDigits] is specified, numbers will format with that many digits
  /// after the decimal place. If it's not, they will use the default for the
  /// currency in [name], and the default currency for [locale] if the currency
  /// name is not specified. e.g.
  ///       NumberFormat.currency(name: 'USD', decimalDigits: 7)
  /// will format with 7 decimal digits, because that's what we asked for. But
  ///       NumberFormat.currency(locale: 'en_US', name: 'JPY')
  /// will format with zero, because that's the default for JPY, and the
  /// currency's default takes priority over the locale's default.
  ///       NumberFormat.currency(locale: 'en_US')
  /// will format with two, which is the default for that locale.
  ///
  /// The [customPattern] parameter can be used to specify a particular
  /// format. This is useful if you have your own locale data which includes
  /// unsupported formats (e.g. accounting format for currencies.)
  // TODO(alanknight): Should we allow decimalDigits on other numbers.
  factory AdaFormattter.currency(
          {String? locale = 'en',
          String? name = ada,
          String? symbol = symbol,
          int? decimalDigits = 6,
          String? customPattern}) =>
      AdaFormattter(
          formatter: NumberFormat.currency(
              locale: locale,
              name: name,
              symbol: symbol,
              decimalDigits: decimalDigits,
              customPattern: customPattern));

  /// A number format for compact currency representations, e.g. "₳1.2M" instead of "₳1,200,000".
  factory AdaFormattter.compactCurrency(
          {String? locale = 'en',
          String? name = ada,
          String? symbol = symbol,
          int? decimalDigits = 6}) =>
      AdaFormattter(
          formatter: NumberFormat.compactCurrency(
              locale: locale,
              name: name,
              symbol: symbol,
              decimalDigits: decimalDigits));

  /// Creates a [NumberFormat] for currencies, using the simple symbol for the
  /// currency if one is available (e.g. $, €), so it should only be used if the
  /// short currency symbol will be unambiguous.
  ///
  /// If [locale] is not specified, it will use the current default locale.
  ///
  /// If [name] is specified, the currency with that ISO 4217 name will be used.
  /// Otherwise we will use the default currency name for the current locale. We
  /// will assume that the symbol for this is well known in the locale and
  /// unambiguous. If you format CAD in an en_US locale using this format it
  /// will display as "$", which may be confusing to the user.
  ///
  /// If [decimalDigits] is specified, numbers will format with that many digits
  /// after the decimal place. If it's not, they will use the default for the
  /// currency in [name], and the default currency for [locale] if the currency
  /// name is not specified. e.g.
  ///       NumberFormat.simpleCurrency(name: 'USD', decimalDigits: 7)
  /// will format with 7 decimal digits, because that's what we asked for. But
  ///       NumberFormat.simpleCurrency(locale: 'en_US', name: 'JPY')
  /// will format with zero, because that's the default for JPY, and the
  /// currency's default takes priority over the locale's default.
  ///       NumberFormat.simpleCurrency(locale: 'en_US')
  /// will format with two, which is the default for that locale.
  factory AdaFormattter.simpleCurrency(
          {String? locale = 'en',
          String? name = ada,
          int? decimalDigits = 6}) =>
      AdaFormattter(
          formatter: NumberFormat.simpleCurrency(
              locale: locale, name: name, decimalDigits: decimalDigits));

  /// A number format for compact currency representations, e.g. "$1.2M" instead
  /// of "$1,200,000", and which will automatically determine a currency symbol
  /// based on the currency name or the locale. See
  /// [NumberFormat.simpleCurrency].
  factory AdaFormattter.compactSimpleCurrency(
          {String? locale = 'en',
          String? name = ada,
          int? decimalDigits = 6}) =>
      AdaFormattter(
          formatter: NumberFormat.compactSimpleCurrency(
              locale: locale, name: name, decimalDigits: decimalDigits));

  /// Convert lovelace to ADA and format [number] according to our pattern and return the formatted string.
  String format(lovelace) => formatter.format(lovelace / 1000000.0);
}
