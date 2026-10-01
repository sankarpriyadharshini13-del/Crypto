const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
const config = require('../config');
const log = require('../utils/logger')('postgres');

const pool = new Pool({ connectionString: config.databaseUrl, max: 10, idleTimeoutMillis: 30000, connectionTimeoutMillis: 5000 });
let healthy = false;

pool.on('error', (err) => { healthy = false; log.error('idle client error', err); });

const query = (text, params) => pool.query(text, params);

async function ping() {
  try { await pool.query('SELECT 1'); if (!healthy) log.info('connected'); healthy = true; }
  catch (e) { if (healthy) log.error('connection lost', e); healthy = false; }
  return healthy;
}

async function ensureSchema() {
  const sql = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
  await pool.query(sql);
  healthy = true;
  log.info('schema ready');
}

// Retry in the background until PostgreSQL is reachable.
async function ensureSchemaWithRetry() {
  for (;;) {
    try { await ensureSchema(); return; }
    catch (e) { healthy = false; log.error('schema setup failed, retrying in 5s', e); await new Promise((r) => setTimeout(r, 5000)); }
  }
}

module.exports = { pool, query, ping, ensureSchema, ensureSchemaWithRetry, isHealthy: () => healthy, close: () => pool.end() };
