const http = require('http');
const config = require('./config');
const app = require('./app');
const db = require('./db/pool');
const redis = require('./services/redisService');
const market = require('./services/marketService');
const binance = require('./services/binanceService');
const wsServer = require('./services/wsServer');
const log = require('./utils/logger')('server');

async function main() {
  const server = http.createServer(app);
  wsServer.start(server);
  redis.start();                       // non-blocking, auto-reconnects
  db.ensureSchemaWithRetry().then(() => market.startPersistence());
  setInterval(() => db.ping(), 10000).unref();
  binance.start();                     // Binance -> Node -> (PostgreSQL + Redis)

  server.listen(config.port, () => log.info(`API + WebSocket listening on :${config.port}`));

  let closing = false;
  const shutdown = async (sig) => {
    if (closing) return; closing = true;
    log.info(`${sig} received, shutting down`);
    const force = setTimeout(() => { log.error('forced exit'); process.exit(1); }, 10000); force.unref();
    binance.stop();
    await wsServer.stop();
    await new Promise((r) => server.close(r));
    await market.stop();
    await redis.stop();
    await db.close().catch(() => {});
    log.info('bye');
    process.exit(0);
  };
  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('unhandledRejection', (e) => log.error('unhandledRejection', e));
}

main();
