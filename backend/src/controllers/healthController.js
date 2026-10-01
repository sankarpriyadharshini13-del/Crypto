const db = require('../db/pool');
const redis = require('../services/redisService');
const binance = require('../services/binanceService');
const market = require('../services/marketService');
const wsServer = require('../services/wsServer');

exports.health = async (req, res) => {
  await db.ping();
  const status = { postgres: db.isHealthy(), redis: redis.isReady(), binance: binance.connected };
  res.status(status.postgres && status.redis ? 200 : 503).json({
    ok: status.postgres && status.redis, ...status, wsClients: wsServer.clientCount(),
    cachedSymbols: market.latest.size, counters: market.counters, uptimeSec: Math.round(process.uptime()), ts: Date.now(),
  });
};
