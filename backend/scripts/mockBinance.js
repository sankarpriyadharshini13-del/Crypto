// Local stand-in for the Binance !ticker@arr stream, for offline testing only.
// Run: npm run mock:binance   then set BINANCE_WS_URL=ws://localhost:9443/ws/!ticker@arr
const { WebSocketServer } = require('ws');
const port = Number(process.env.MOCK_PORT || 9443);
const coins = { BTC: 67000, ETH: 3500, BNB: 600, SOL: 150, XRP: 0.52, DOGE: 0.15, ADA: 0.45, AVAX: 35, LINK: 14, PEPE: 0.0000012 };
const state = Object.fromEntries(Object.entries(coins).map(([k, p]) => [k + 'USDT', { open: p, price: p, high: p, low: p, vol: 1e5 / p * 1000 }]));
const wss = new WebSocketServer({ port });
setInterval(() => {
  const E = Date.now();
  const arr = Object.entries(state).map(([s, x]) => {
    x.price *= 1 + (Math.random() - 0.5) * 0.002; x.high = Math.max(x.high, x.price); x.low = Math.min(x.low, x.price); x.vol += Math.random() * 10;
    return { e: '24hrTicker', E, s, p: String(x.price - x.open), P: String(((x.price / x.open) - 1) * 100), w: String(x.price), c: String(x.price), o: String(x.open), h: String(x.high), l: String(x.low), v: String(x.vol), q: String(x.vol * x.price), n: Math.floor(x.vol) };
  });
  arr.push({ s: 'BTCEUR', c: '1' }, { s: 'BAD!!USDT', c: 'x' }, { garbage: true }); // invalid / non-USDT entries to exercise validation
  const msg = JSON.stringify(arr);
  wss.clients.forEach((c) => c.readyState === 1 && c.send(msg));
}, 1000);
console.log(`mock Binance stream on ws://localhost:${port}/ws/!ticker@arr`);
