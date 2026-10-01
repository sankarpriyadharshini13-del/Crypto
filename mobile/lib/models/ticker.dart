double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

class Ticker {
  final String symbol;
  final String baseAsset;
  final String quoteAsset;
  final double price;
  final double change;
  final double changePercent;
  final double open;
  final double high;
  final double low;
  final double volume;
  final double quoteVolume;
  final int trades;
  final int ts;

  const Ticker({
    required this.symbol,
    required this.baseAsset,
    required this.quoteAsset,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
    required this.quoteVolume,
    required this.trades,
    required this.ts,
  });

  factory Ticker.fromJson(Map<String, dynamic> j) => Ticker(
        symbol: j['symbol'] as String,
        baseAsset: (j['baseAsset'] ?? '') as String,
        quoteAsset: (j['quoteAsset'] ?? 'USDT') as String,
        price: _d(j['price']),
        change: _d(j['change']),
        changePercent: _d(j['changePercent']),
        open: _d(j['open']),
        high: _d(j['high']),
        low: _d(j['low']),
        volume: _d(j['volume']),
        quoteVolume: _d(j['quoteVolume']),
        trades: _d(j['trades']).toInt(),
        ts: _d(j['ts']).toInt(),
      );
}

class Candle {
  final DateTime time;
  final double open, high, low, close;
  const Candle(this.time, this.open, this.high, this.low, this.close);

  factory Candle.fromJson(Map<String, dynamic> j) => Candle(
        DateTime.fromMillisecondsSinceEpoch(_d(j['t']).toInt()),
        _d(j['open']),
        _d(j['high']),
        _d(j['low']),
        _d(j['close']),
      );
}

class MarketOverview {
  final int pairs, gainers, losers;
  final double totalQuoteVolume, avgChangePercent;
  final List<Ticker> topGainers, topLosers, topVolume;

  const MarketOverview({
    required this.pairs,
    required this.gainers,
    required this.losers,
    required this.totalQuoteVolume,
    required this.avgChangePercent,
    required this.topGainers,
    required this.topLosers,
    required this.topVolume,
  });

  factory MarketOverview.fromJson(Map<String, dynamic> j) {
    List<Ticker> list(String k) =>
        (j[k] as List).map((e) => Ticker.fromJson(e as Map<String, dynamic>)).toList();
    return MarketOverview(
      pairs: _d(j['pairs']).toInt(),
      gainers: _d(j['gainers']).toInt(),
      losers: _d(j['losers']).toInt(),
      totalQuoteVolume: _d(j['totalQuoteVolume']),
      avgChangePercent: _d(j['avgChangePercent']),
      topGainers: list('topGainers'),
      topLosers: list('topLosers'),
      topVolume: list('topVolume'),
    );
  }
}
