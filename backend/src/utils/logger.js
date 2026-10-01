const config = require('../config');
const LEVELS = { error: 0, warn: 1, info: 2, debug: 3 };

function log(level, scope, msg, extra) {
  if (LEVELS[level] > (LEVELS[config.logLevel] ?? 2)) return;
  const line = `${new Date().toISOString()} ${level.toUpperCase().padEnd(5)} [${scope}] ${msg}`;
  const out = level === 'error' ? console.error : level === 'warn' ? console.warn : console.log;
    extra === undefined
    ? out(line)
    : out(line, extra instanceof Error
        ? (extra.message || extra.code || (extra.errors || []).map((e) => e.code).join(',') || String(extra))
        : extra);
}

module.exports = (scope) => ({
  error: (m, e) => log('error', scope, m, e),
  warn: (m, e) => log('warn', scope, m, e),
  info: (m, e) => log('info', scope, m, e),
  debug: (m, e) => log('debug', scope, m, e),
});
