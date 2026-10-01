const { createClient } = require('redis');
const config = require('../config');
const log = require('../utils/logger')('redis');

const reconnectStrategy = (retries) => Math.min(200 * 2 ** Math.min(retries, 6), 5000);

class RedisService {
  constructor() {
    this.client = null;   // commands + publishing
    this.sub = null;      // dedicated subscriber connection
    this.subscriptions = new Map(); // channel -> handler
    this.subscribed = false;
  }

  start() {
    if (this.client) return; // prevent duplicate connections
    const opts = { url: config.redisUrl, socket: { reconnectStrategy }, disableOfflineQueue: true };
    this.client = createClient(opts);
    this.sub = this.client.duplicate();

    for (const [name, c] of [['client', this.client], ['subscriber', this.sub]]) {
      c.on('error', (e) => log.warn(`${name} error`, e));
      c.on('reconnecting', () => log.warn(`${name} reconnecting`));
      c.on('ready', () => log.info(`${name} ready`));
    }
    this.sub.on('ready', () => this._subscribeAll());
    // Do not block startup if Redis is down; node-redis keeps retrying.
    this.client.connect().catch((e) => log.error('client connect failed', e));
    this.sub.connect().catch((e) => log.error('subscriber connect failed', e));
  }

  isReady() { return !!this.client && this.client.isReady; }

  // Register a Pub/Sub handler. Active as soon as the subscriber is ready (and re-applied after reconnects).
  onMessage(channel, handler) {
    this.subscriptions.set(channel, handler);
    if (this.sub && this.sub.isReady) this.sub.subscribe(channel, handler).catch((e) => log.warn('subscribe failed', e));
  }

  async _subscribeAll() {
    // node-redis restores listeners itself after a reconnect; only do the first subscribe manually.
    if (this.subscribed) return;
    this.subscribed = true;
    for (const [channel, handler] of this.subscriptions) {
      try { await this.sub.subscribe(channel, handler); log.info(`subscribed to ${channel}`); }
      catch (e) { this.subscribed = false; log.warn('subscribe failed', e); }
    }
  }

  async setTickers(tickers) {
    if (!tickers.length || !this.isReady()) return false;
    const fields = {};
    for (const t of tickers) fields[t.symbol] = JSON.stringify(t);
    await this.client.hSet(config.keys.tickers, fields);
    return true;
  }

  async getAllTickers() {
    if (!this.isReady()) return null;
    const raw = await this.client.hGetAll(config.keys.tickers);
    return Object.values(raw).map((s) => JSON.parse(s));
  }

  async getTicker(symbol) {
    if (!this.isReady()) return null;
    const raw = await this.client.hGet(config.keys.tickers, symbol);
    return raw ? JSON.parse(raw) : null;
  }

  async publish(channel, payload) {
    if (!this.isReady()) return false;
    await this.client.publish(channel, typeof payload === 'string' ? payload : JSON.stringify(payload));
    return true;
  }

  async stop() {
    for (const c of [this.client, this.sub]) {
      try { if (c && c.isOpen) await c.quit(); } catch { /* ignore */ }
    }
    this.client = this.sub = null;
  }
}

module.exports = new RedisService();
