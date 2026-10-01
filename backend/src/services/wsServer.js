const { WebSocketServer, WebSocket } = require('ws');
const config = require('../config');
const redis = require('./redisService');
const db = require('../db/pool');
const binance = require('./binanceService');
const log = require('../utils/logger')('ws');

// Backend WebSocket for Flutter. Fan-out source is Redis Pub/Sub (not PostgreSQL).
class WsServer {
  constructor() { this.wss = null; this.timers = []; }

  clientCount() { return this.wss ? this.wss.clients.size : 0; }

  start(httpServer) {
    this.wss = new WebSocketServer({ server: httpServer, path: '/ws', maxPayload: 16 * 1024 });

    this.wss.on('connection', (ws) => {
      ws.isAlive = true; ws.filter = null;
      ws.on('pong', () => { ws.isAlive = true; });
      ws.on('error', (e) => log.debug('client error', e));
      ws.on('message', (raw) => this._onClientMessage(ws, raw));
      this._send(ws, this._status());
      log.debug(`client connected (${this.clientCount()})`);
    });

    redis.onMessage(config.channels.updates, (m) => this._broadcastTickers(m));
    redis.onMessage(config.channels.status, () => this._broadcast(this._status()));

    this.timers.push(setInterval(() => this._broadcast(this._status()), 5000));
    this.timers.push(setInterval(() => {
      for (const ws of this.wss.clients) {
        if (!ws.isAlive) { ws.terminate(); continue; }
        ws.isAlive = false; ws.ping();
      }
    }, 30000));
  }

  _status() { return { type: 'status', binance: binance.connected, redis: redis.isReady(), postgres: db.isHealthy(), ts: Date.now() }; }

  // Client may send {"action":"subscribe","symbols":["BTCUSDT"]} to receive only those; empty list = all.
  _onClientMessage(ws, raw) {
    let msg; try { msg = JSON.parse(raw.toString()); } catch { return; }
    if (msg && msg.action === 'subscribe' && Array.isArray(msg.symbols)) {
      const syms = msg.symbols.filter((s) => typeof s === 'string').slice(0, 1000).map((s) => s.toUpperCase());
      ws.filter = syms.length ? new Set(syms) : null;
    }
  }

  _broadcastTickers(message) {
    let parsed = null;
    for (const ws of this.wss.clients) {
      if (ws.readyState !== WebSocket.OPEN || ws.bufferedAmount > 1_000_000) continue; // skip slow clients
      if (!ws.filter) { ws.send(message); continue; }
      parsed = parsed || JSON.parse(message);
      const data = parsed.data.filter((t) => ws.filter.has(t.symbol));
      if (data.length) ws.send(JSON.stringify({ ...parsed, data }));
    }
  }

  _send(ws, obj) { if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(obj)); }
  _broadcast(obj) { const s = JSON.stringify(obj); for (const ws of this.wss.clients) if (ws.readyState === WebSocket.OPEN) ws.send(s); }

  stop() {
    this.timers.forEach(clearInterval);
    if (!this.wss) return Promise.resolve();
    for (const ws of this.wss.clients) ws.close(1001, 'server shutting down');
    return new Promise((r) => this.wss.close(r));
  }
}

module.exports = new WsServer();
