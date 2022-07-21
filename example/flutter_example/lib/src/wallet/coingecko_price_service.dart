// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:oxidized/oxidized.dart';
import 'package:coingecko_dart/coingecko_dart.dart';
import 'package:coingecko_dart/dataClasses/coins/Coin.dart';
import 'package:coingecko_dart/dataClasses/coins/PricedCoin.dart';
import './price_service.dart';

///
/// Coin Gecko service to get real-time exchange trading values.
///
/// WARNING This code will eventualy be removed from this project as it's not a core Cardano wallet feature.
///
class CoinGeckoApiFix extends CoinGeckoApi {
  ///
  ///* Coingecko API ( **GET** /ping )
  ///
  ///used to check Coingecko Server API status
  ///
  @override
  Future<CoinGeckoResult<bool>> ping() async {
    Response response = await dio!
        .get("/ping", options: Options(contentType: 'application/json'));
    return CoinGeckoResult(response.statusCode == 200,
        errorCode: response.statusCode ?? -1,
        errorMessage: (response.statusMessage ?? ""),
        isError: response.statusCode != 200);
  }
}

class CoingeckoPriceService extends PriceService {
  final logger = Logger();
  static final Map<String, String> _defaultSymbolToId = {
    'btc': 'bitcoin',
    'eth': 'ethereum',
    'bnb': 'binancecoin',
    'xrp': 'ripple',
    'ada': 'cardano',
    'doge': 'dogecoin',
    'usdt': 'tether',
    'dot': 'polkadot',
    'bch': 'bitcoin-cash',
    'ltc': 'litecoin',
    'uni': 'uniswap',
    'link': 'chainlink',
    'usdc': 'usd-coin',
    'xlm': 'stellar',
    'sol': 'solana',
    'aave': 'aave',
    'dai': 'dai',
    'cel': 'celsius-degree-token',
    'nexo': 'nexo',
    'tusd': 'true-usd',
    'gusd': 'gemini-dollar',
  };

  final CoinGeckoApi coingecko;
  Map<String, String> _symbolToId = _defaultSymbolToId;

  CoingeckoPriceService() : coingecko = CoinGeckoApiFix(); //CoinGeckoApi

  @override
  Future<Result<Price, String>> currentPrice(
      {String from = 'ada', String to = 'usd'}) async {
    final fromId = await _toId(from);
    if (fromId == null) {
      return Err("can't convert symbol($from) to ID");
    }
    final CoinGeckoResult<List<PricedCoin>> list =
        await coingecko.simplePrice(ids: [fromId], vs_currencies: [to]);
    if (list.isError) {
      return Err(list.errorMessage);
    } else if (list.data.isEmpty || list.data.first.data[to] == null) {
      return Err("no data");
    } else {
      PricedCoin pricedCoin = list.data.first;
      final timestamp = DateTime.now()
          .millisecondsSinceEpoch; // pricedCoin.lastUpdatedAtTimeStamp.millisecondsSinceEpoch;
      Map<String, double> pair = pricedCoin.data;
      return Ok(Price(
          fromTicker: from,
          toTicker: to,
          timestamp: timestamp,
          value: pair[to]!));
    }
  }

  @override
  Future<Result<bool, String>> ping() async {
    final CoinGeckoResult<bool> result = await coingecko.ping();
    if (result.isError) {
      return Err(result.errorMessage);
    } else {
      return Ok(result.data);
    }
  }

  @override
  Future<Result<Map<String, String>, String>> list() async {
    final CoinGeckoResult<List<Coin>> result = await coingecko.listCoins();
    if (result.isError) {
      return Err(result.errorMessage);
    } else {
      Map<String, String> map = {for (var c in result.data) c.symbol: c.id};
      return Ok(map);
    }
  }

  Future<String?> _toId(String symbol) async {
    String? id = _symbolToId[symbol];
    if (id == null && _symbolToId == _defaultSymbolToId) {
      //can't find it in default list, then load the full list
      final result = await list();
      result.when(ok: (fullList) {
        _symbolToId = fullList;
        id = _symbolToId[symbol];
      }, err: (err) {
        logger.e(err);
      });
    }
    return id;
  }
}
