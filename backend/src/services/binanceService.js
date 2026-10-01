const WebSocket = require('ws');
const { EventEmitter } = require('events');
const config = require('../config');
const market = require('./marketService');
const log = require('../utils/logger')('binance');

// Single connection to the Binance public all-market 24h ticker stream (!ticker@arr, ~1 update/sec).
class BinanceService extends EventEmitter {
  constructor() {
    super();
    this.ws = null;
    this.connected = false;
    this.stopped = true;
    this.attempt = 0;
    this.reconnectTimer = null;
    this.watchdog = null;
    this.lastMessageAt = 0;
  }

  start() {
    if (!this.stopped) return; // guard against duplicate connections
    this.stopped = false;
    this._connect();
  }

  _connect() {
    if (this.ws || this.stopped) return;
    log.info(`connecting to ${config.binance.wsUrl}`);
    const ws = new WebSocket(config.binance.wsUrl, { handshakeTimeout: 10000 });
    this.ws = ws;

    ws.on('open', () => {
      this.attempt = 0;
      this.lastMessageAt = Date.now();
      this._setConnected(true);
      this.watchdog = setInterval(() => {
        if (Date.now() - this.lastMessageAt > config.binance.staleAfterMs) {
          log.warn('stream stale, forcing reconnect');
          ws.terminate();
        }
      }, 5000);
    });

    ws.on('message', (buf) => {
      this.lastMessageAt = Date.now();
      let msg;
      try { msg = JSON.parse(buf.toString()); } catch { return log.warn('dropped non-JSON frame'); }
      const list = Array.isArray(msg) ? msg : Array.isArray(msg && msg.data) ? msg.data : null;
      if (!list) return;
      market.handleBatch(list).catch((e) => log.error('batch handling failed', e));
    });

    ws.on('error', (e) => log.warn('socket error', e));
    ws.on('close', (code) => {
      clearInterval(this.watchdog);
      this.ws = null;
      this._setConnected(false);
      if (!this.stopped) this._scheduleReconnect(code);
    });
  }

  _scheduleReconnect(code) {
    const { backoffMinMs, backoffMaxMs } = config.binance;
    const delay = Math.min(backoffMinMs * 2 ** this.attempt, backoffMaxMs) * (0.8 + Math.random() * 0.4);
    this.attempt++;
    log.warn(`disconnected (code ${code}); reconnecting in ${Math.round(delay)}ms (attempt ${this.attempt})`);
    clearTimeout(this.reconnectTimer);
    this.reconnectTimer = setTimeout(() => { this.reconnectTimer = null; this._connect(); }, delay);
  }

  _setConnected(v) {
    if (this.connected === v) return;
    this.connected = v;
    log.info(v ? 'connected' : 'connection closed');
    market.publishStatus({ binance: v });
  }

  stop() {
    this.stopped = true;
    clearTimeout(this.reconnectTimer);
    clearInterval(this.watchdog);
    if (this.ws) { try { this.ws.close(1000, 'shutdown'); } catch { /* ignore */ } }
  }
}

module.exports = new BinanceService();
