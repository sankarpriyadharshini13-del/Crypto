const express = require('express');
const cors = require('cors');
const config = require('./config');
const routes = require('./routes');
const requestLogger = require('./middleware/requestLogger');
const { notFound, errorHandler } = require('./middleware/errorHandler');

const app = express();
app.disable('x-powered-by');
app.use(cors({ origin: config.corsOrigin === '*' ? true : config.corsOrigin.split(',') }));
app.use(express.json({ limit: '10kb' }));
app.use(requestLogger);
app.use('/api', routes);
app.use(notFound);
app.use(errorHandler);

module.exports = app;
