const router = require('express').Router();
const market = require('../controllers/marketController');
const health = require('../controllers/healthController');

router.get('/health', health.health);
router.get('/market/tickers', market.list);
router.get('/market/tickers/:symbol', market.one);
router.get('/market/stats', market.stats);
router.get('/market/history/:symbol', market.history);

module.exports = router;
