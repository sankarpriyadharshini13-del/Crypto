const config = require('../config');
const db = require('../db/pool');
const redis = require('./redisService');
const log = require('../utils/logger')('market');

const SYMBOL_RE = /^[A-Z0-9]{5,20}$/;
const num = (v) => { const n = typeof v === 'string' ? Number(v) : v; return Number.isFinite(n) ? n : null; };

class MarketService {
  constructor() {
    this.latest = new Map();        // symbol -> last accepted ticker
    this.dirty = new Set();         // symbols changed since the last PostgreSQL flush
    this.candles = new Map();       // symbol -> current in-memory 1m candle
    this.finished = [];             // closed candles waiting to be persisted
    this.timer = null;
    this.flushing = false;
    this.counters = { received: 0, invalid: 0, published: 0, flushes: 0, rowsWritten: 0 };
    this.lastRedisWarn = 0;
  }

  // Validate and normalise one raw Binance ticker object. Returns null if invalid.
  normalize(raw) {
    if (!raw || typeof raw !== 'object' || typeof raw.s !== 'string') return null;
    const symbol = raw.s;
    if (!SYMBOL_RE.test(symbol) || !symbol.endsWith(config.binance.quoteAsset)) return null;
    // !miniTicker@arr gives: s, c (last), o (open), h, l, v (base vol), q (quote vol), E (event time).
    // 24h change and percent are derived from open/last; trade count is not part of this stream.
    const price = num(raw.c);
    const open = num(raw.o);
    const change = price !== null && open !== null ? price - open : null;
    const changePercent = change !== null && open > 0 ? (change / open) * 100 : null;
    const t = {
      symbol,
      baseAsset: symbol.slice(0, -config.binance.quoteAsset.length),
      quoteAsset: config.binance.quoteAsset,
      price, change, changePercent, open,
      high: num(raw.h), low: num(raw.l),
      volume: num(raw.v), quoteVolume: num(raw.q), trades: 0, ts: num(raw.E),
    };
    if (!t.baseAsset) return null;
    for (const k of ['price', 'change', 'changePercent', 'open', 'high', 'low', 'volume', 'quoteVolume', 'ts']) if (t[k] === null) return null;
    if (t.price <= 0 || t.volume < 0 || t.quoteVolume < 0) return null;
    t.trades = Math.max(0, Math.trunc(t.trades ?? 0));
    return t;
  }

  async handleBatch(rawList) {
    if (!Array.isArray(rawList)) return;
    const changed = [];
    for (const raw of rawList) {
      this.counters.received++;
      const t = this.normalize(raw);
      if (!t) { this.counters.invalid++; continue; }
      const prev = this.latest.get(t.symbol);
      if (prev && prev.price === t.price && prev.quoteVolume === t.quoteVolume && prev.changePercent === t.changePercent) continue; // nothing new
      this.latest.set(t.symbol, t);
      this.dirty.add(t.symbol);
      this._updateCandle(t);
      changed.push(t);
    }
    if (!changed.length) return;
    try {
      await redis.setTickers(changed);                                                   // cache
      const ok = await redis.publish(config.channels.updates, { type: 'tickers', ts: Date.now(), data: changed }); // pub/sub
      if (ok) this.counters.published += changed.length;
    } catch (e) {
      if (Date.now() - this.lastRedisWarn > 10000) { this.lastRedisWarn = Date.now(); log.warn('redis update failed', e); }
    }
  }

  publishStatus(status) {
    redis.publish(config.channels.status, { type: 'status', ...status, ts: Date.now() }).catch(() => {});
  }

  _updateCandle(t) {
    const bucket = Math.floor(t.ts / 60000) * 60000;
    const c = this.candles.get(t.symbol);
    if (!c || c.bucket !== bucket) {
      if (c && bucket > c.bucket) this.finished.push(c);
      this.candles.set(t.symbol, { symbol: t.symbol, bucket, open: t.price, high: t.price, low: t.price, close: t.price });
    } else {
      c.high = Math.max(c.high, t.price); c.low = Math.min(c.low, t.price); c.close = t.price;
    }
  }

  startPersistence() {
    if (this.timer) return;
    this.timer = setInterval(() => this.flush().catch((e) => log.error('flush error', e)), config.persistIntervalMs);
    this.cleanupTimer = setInterval(() => this.cleanup().catch((e) => log.warn('cleanup error', e)), 3600 * 1000);
  }

  // Batched write: at most one row per symbol per interval (no per-tick writes).
  async flush() {
    if (this.flushing || !db.isHealthy() || (!this.dirty.size && !this.finished.length)) return;
    this.flushing = true;
    const symbols = [...this.dirty];
    const finished = this.finished;
    this.dirty = new Set(); this.finished = [];
    const tickers = symbols.map((s) => this.latest.get(s)).filter(Boolean);
    const candles = [...finished, ...symbols.map((s) => this.candles.get(s)).filter(Boolean)];
    const client = await db.pool.connect().catch(() => null);
    if (!client) { symbols.forEach((s) => this.dirty.add(s)); this.finished = finished.concat(this.finished); this.flushing = false; return; }
    try {
      await client.query('BEGIN');
      await client.query(
        `INSERT INTO symbols (symbol, base_asset, quote_asset)
         SELECT * FROM unnest($1::text[], $2::text[], $3::text[]) ON CONFLICT (symbol) DO NOTHING`,
        [tickers.map((t) => t.symbol), tickers.map((t) => t.baseAsset), tickers.map((t) => t.quoteAsset)]);
      await client.query(
        `INSERT INTO tickers (symbol, last_price, price_change, price_change_percent, open_price, high_price, low_price, volume, quote_volume, trade_count, event_time, updated_at)
         SELECT s, p, c, cp, o, h, l, v, qv, n, to_timestamp(ts / 1000.0), now()
         FROM unnest($1::text[], $2::numeric[], $3::numeric[], $4::numeric[], $5::numeric[], $6::numeric[], $7::numeric[], $8::numeric[], $9::numeric[], $10::bigint[], $11::double precision[])
              AS u(s, p, c, cp, o, h, l, v, qv, n, ts)
         ON CONFLICT (symbol) DO UPDATE SET
           last_price = EXCLUDED.last_price, price_change = EXCLUDED.price_change, price_change_percent = EXCLUDED.price_change_percent,
           open_price = EXCLUDED.open_price, high_price = EXCLUDED.high_price, low_price = EXCLUDED.low_price,
           volume = EXCLUDED.volume, quote_volume = EXCLUDED.quote_volume, trade_count = EXCLUDED.trade_count,
           event_time = EXCLUDED.event_time, updated_at = now()`,
        [tickers.map((t) => t.symbol), tickers.map((t) => t.price), tickers.map((t) => t.change), tickers.map((t) => t.changePercent),
         tickers.map((t) => t.open), tickers.map((t) => t.high), tickers.map((t) => t.low), tickers.map((t) => t.volume),
         tickers.map((t) => t.quoteVolume), tickers.map((t) => t.trades), tickers.map((t) => t.ts)]);
      if (candles.length) {
        await client.query(
          `INSERT INTO price_candles (symbol, bucket, open, high, low, close)
           SELECT s, to_timestamp(b / 1000.0), o, h, l, c
           FROM unnest($1::text[], $2::double precision[], $3::numeric[], $4::numeric[], $5::numeric[], $6::numeric[]) AS u(s, b, o, h, l, c)
           ON CONFLICT (symbol, bucket) DO UPDATE SET
             high = GREATEST(price_candles.high, EXCLUDED.high), low = LEAST(price_candles.low, EXCLUDED.low),
             close = EXCLUDED.close, updated_at = now()`,
          [candles.map((c) => c.symbol), candles.map((c) => c.bucket), candles.map((c) => c.open), candles.map((c) => c.high), candles.map((c) => c.low), candles.map((c) => c.close)]);
      }
      await client.query('COMMIT');
      this.counters.flushes++; this.counters.rowsWritten += tickers.length + candles.length;
      log.debug(`flushed ${tickers.length} tickers, ${candles.length} candles`);
    } catch (e) {
      await client.query('ROLLBACK').catch(() => {});
      symbols.forEach((s) => this.dirty.add(s)); this.finished = finished.concat(this.finished); // retry next interval
      log.error('flush failed, will retry', e);
    } finally { client.release(); this.flushing = false; }
  }

  async cleanup() {
    if (!db.isHealthy()) return;
    const r = await db.query(`DELETE FROM price_candles WHERE bucket < now() - ($1 || ' days')::interval`, [String(config.candleRetentionDays)]);
    if (r.rowCount) log.info(`retention: removed ${r.rowCount} old candles`);
  }

  async stop() {
    clearInterval(this.timer); clearInterval(this.cleanupTimer); this.timer = null;
    await this.flush().catch(() => {});
  }

  // ---- Read side (REST) : Redis first, PostgreSQL fallback ----
  async getTickers() {
    try {
      const fromRedis = await redis.getAllTickers();
      if (fromRedis && fromRedis.length) return { source: 'redis', data: fromRedis };
    } catch (e) { log.warn('redis read failed, falling back to postgres', e); }
    const r = await db.query(`SELECT t.*, s.base_asset FROM tickers t JOIN symbols s USING (symbol)`);
    return { source: 'postgres', data: r.rows.map(rowToTicker) };
  }

  async getTicker(symbol) {
    try { const t = await redis.getTicker(symbol); if (t) return { source: 'redis', data: t }; } catch (e) { log.warn('redis read failed', e); }
    const r = await db.query(`SELECT t.*, s.base_asset FROM tickers t JOIN symbols s USING (symbol) WHERE symbol = $1`, [symbol]);
    return r.rows[0] ? { source: 'postgres', data: rowToTicker(r.rows[0]) } : null;
  }

  async getHistory(symbol, range) {
    const spec = HISTORY_RANGES[range];
    const r = await db.query(
      `SELECT extract(epoch FROM date_bin($3::interval, bucket, TIMESTAMPTZ '2000-01-01')) * 1000 AS t,
              (array_agg(open ORDER BY bucket ASC))[1]::float8 AS open, MAX(high)::float8 AS high, MIN(low)::float8 AS low,
              (array_agg(close ORDER BY bucket DESC))[1]::float8 AS close
       FROM price_candles WHERE symbol = $1 AND bucket >= now() - $2::interval
       GROUP BY 1 ORDER BY 1`, [symbol, spec.window, spec.bin]);
    return r.rows.map((x) => ({ t: Number(x.t), open: x.open, high: x.high, low: x.low, close: x.close }));
  }
}

const HISTORY_RANGES = {
  '1h': { window: '1 hour', bin: '1 minute' },
  '24h': { window: '24 hours', bin: '5 minutes' },
  '7d': { window: '7 days', bin: '30 minutes' },
  '30d': { window: '30 days', bin: '2 hours' },
};

function rowToTicker(r) {
  return {
    symbol: r.symbol, baseAsset: r.base_asset, quoteAsset: 'USDT', price: +r.last_price, change: +r.price_change,
    changePercent: +r.price_change_percent, open: +r.open_price, high: +r.high_price, low: +r.low_price,
    volume: +r.volume, quoteVolume: +r.quote_volume, trades: Number(r.trade_count), ts: new Date(r.event_time).getTime(),
  };
}

const service = new MarketService();
service.HISTORY_RANGES = HISTORY_RANGES;
module.exports = service;