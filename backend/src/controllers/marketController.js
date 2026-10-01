const market = require('../services/marketService');
const db = require('../db/pool');
const { HttpError, asyncHandler } = require('../middleware/errorHandler');

const SORTS = {
  name: (t) => t.baseAsset, price: (t) => t.price, change: (t) => t.changePercent,
  volume: (t) => t.quoteVolume, trades: (t) => t.trades, high: (t) => t.high, low: (t) => t.low,
};
const SYMBOL_RE = /^[A-Za-z0-9]{3,20}$/;

exports.list = asyncHandler(async (req, res) => {
  const { search = '', sort = 'volume', order = 'desc' } = req.query;
  const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 500, 1), 1000);
  const offset = Math.max(parseInt(req.query.offset, 10) || 0, 0);
  if (!SORTS[sort]) throw new HttpError(400, `sort must be one of: ${Object.keys(SORTS).join(', ')}`);
  if (!['asc', 'desc'].includes(order)) throw new HttpError(400, 'order must be asc or desc');

  const { source, data } = await market.getTickers();
  const q = String(search).trim().toUpperCase();
  let rows = q ? data.filter((t) => t.symbol.includes(q) || t.baseAsset.includes(q)) : data;
  const key = SORTS[sort]; const dir = order === 'asc' ? 1 : -1;
  rows = [...rows].sort((a, b) => (key(a) > key(b) ? 1 : key(a) < key(b) ? -1 : 0) * dir);
  res.json({ source, total: rows.length, ts: Date.now(), data: rows.slice(offset, offset + limit) });
});

exports.one = asyncHandler(async (req, res) => {
  const symbol = req.params.symbol.toUpperCase();
  if (!SYMBOL_RE.test(symbol)) throw new HttpError(400, 'Invalid symbol');
  const r = await market.getTicker(symbol);
  if (!r) throw new HttpError(404, `Unknown symbol ${symbol}`);
  res.json({ source: r.source, data: r.data });
});

exports.stats = asyncHandler(async (req, res) => {
  const { source, data } = await market.getTickers();
  const liquid = data.filter((t) => t.quoteVolume >= 1_000_000);
  const top = (arr, f, n = 5) => [...arr].sort((a, b) => f(b) - f(a)).slice(0, n);
  res.json({
    source, ts: Date.now(),
    data: {
      pairs: data.length,
      totalQuoteVolume: data.reduce((s, t) => s + t.quoteVolume, 0),
      gainers: data.filter((t) => t.changePercent > 0).length,
      losers: data.filter((t) => t.changePercent < 0).length,
      avgChangePercent: data.length ? data.reduce((s, t) => s + t.changePercent, 0) / data.length : 0,
      topGainers: top(liquid, (t) => t.changePercent),
      topLosers: top(liquid, (t) => -t.changePercent),
      topVolume: top(data, (t) => t.quoteVolume),
    },
  });
});

exports.history = asyncHandler(async (req, res) => {
  const symbol = req.params.symbol.toUpperCase();
  const range = req.query.range || '24h';
  if (!SYMBOL_RE.test(symbol)) throw new HttpError(400, 'Invalid symbol');
  if (!market.HISTORY_RANGES[range]) throw new HttpError(400, `range must be one of: ${Object.keys(market.HISTORY_RANGES).join(', ')}`);
  if (!db.isHealthy()) throw new HttpError(503, 'History is temporarily unavailable');
  const candles = await market.getHistory(symbol, range);
  res.json({ symbol, range, count: candles.length, data: candles });
});
