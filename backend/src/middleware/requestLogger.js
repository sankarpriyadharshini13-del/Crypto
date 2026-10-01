const log = require('../utils/logger')('http');
module.exports = (req, res, next) => {
  const start = Date.now();
  res.on('finish', () => log.debug(`${req.method} ${req.originalUrl} ${res.statusCode} ${Date.now() - start}ms`));
  next();
};
