const log = require('../utils/logger')('http');

class HttpError extends Error {
  constructor(status, message) { super(message); this.status = status; }
}
const notFound = (req, res) => res.status(404).json({ error: 'Not found' });
// eslint-disable-next-line no-unused-vars
const errorHandler = (err, req, res, next) => {
  const status = err.status || 500;
  if (status >= 500) log.error(`${req.method} ${req.originalUrl} failed`, err);
  res.status(status).json({ error: status >= 500 ? 'Internal server error' : err.message });
};
const asyncHandler = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

module.exports = { HttpError, notFound, errorHandler, asyncHandler };
