require('dotenv').config();

const int = (v, d) => {
  const n = parseInt(v, 10);
  return Number.isFinite(n) ? n : d;
};

module.exports = {
  env: process.env.NODE_ENV || 'development',
  port: int(process.env.PORT, 3000),
  logLevel: process.env.LOG_LEVEL || 'info',
  corsOrigin: process.env.CORS_ORIGIN || '*',
  databaseUrl: process.env.DATABASE_URL || 'postgres://crypto:crypto_password@localhost:5432/crypto_pulse',
  redisUrl: process.env.REDIS_URL || 'redis://localhost:6379',
  binance: {
    wsUrl: process.env.BINANCE_WS_URL || 'wss://stream.binance.com:9443/ws/!ticker@arr',
    quoteAsset: (process.env.QUOTE_ASSET || 'USDT').toUpperCase(),
    staleAfterMs: 30000,
    backoffMinMs: 1000,
    backoffMaxMs: 30000,
  },
  persistIntervalMs: int(process.env.PERSIST_INTERVAL_MS, 5000),
  candleRetentionDays: int(process.env.CANDLE_RETENTION_DAYS, 90),
  channels: { updates: 'market:updates', status: 'market:status' },
  keys: { tickers: 'market:tickers' },
};
