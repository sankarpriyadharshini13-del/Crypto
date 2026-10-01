# Crypto Pulse

Crypto Pulse is a real-time crypto market monitoring app that streams live price data from Binance, processes it in a Node.js backend, stores market data in Redis and PostgreSQL, and displays it in a modern Flutter UI.

## Overview

This project collects live cryptocurrency ticker data from Binance, processes it on the backend, stores it in Redis and PostgreSQL, and exposes the data through both REST and WebSocket APIs. The Flutter mobile app consumes those APIs to display a modern live market dashboard with search, filters, watchlist support, and chart history.

## Architecture

```text
Binance WS (!ticker@arr)
        |
 Node.js binanceService  --validate-->  marketService
                                            |
                          +-----------------+------------------+
                          v                                    v
                 Redis: hash cache + Pub/Sub          PostgreSQL: batched upserts
                          |                           (tickers + 1m candles)
                          v
                 wsServer (/ws) subscribes to the Redis channel and fans out to Flutter
REST /api/*: Redis first, PostgreSQL fallback; history from PostgreSQL
```

## Project structure

```text
backend/
  .env.example
  src/
    config/index.js            env-driven config
    db/schema.sql, pool.js, migrate.js
    services/binanceService.js reconnect/backoff, stale watchdog, single-connection guard
    services/marketService.js  validate, cache, publish, batched persistence, reads
    services/redisService.js   cache + Pub/Sub, auto-reconnect
    services/wsServer.js       backend WebSocket for the app
    controllers/, routes/, middleware/, utils/logger.js
    app.js, server.js          graceful shutdown
  scripts/mockBinance.js       offline test stand-in for Binance
mobile/
  pubspec.yaml, setup_platforms.sh
  lib/ main.dart, config/, theme/, models/, services/, state/, screens/, widgets/, utils/
docker-compose.yml             optional PostgreSQL + Redis
```

## Features

- Live crypto market stream from Binance
- Real-time WebSocket updates for app clients
- Redis-powered fast cache and pub/sub updates
- PostgreSQL persistence for ticker and candle history
- REST API for market stats and chart data
- Search, sorting, filtering, and watchlist functionality
- Modern Flutter dashboard UI

## Dependencies

Backend: express, ws, pg, redis, cors, dotenv
Flutter: provider, http, web_socket_channel, fl_chart, shared_preferences, intl

## Setup and run

```bash
# 1. PostgreSQL + Redis (Docker option)
docker compose up -d
# or natively: createuser crypto -P (password crypto_password); createdb -O crypto crypto_pulse

# 2. Backend
cd backend
cp .env.example .env
npm install
npm run db:migrate     # optional: schema is also applied on startup
npm start

# 3. Flutter
cd ../mobile
./setup_platforms.sh   # generates android/ios, enables cleartext HTTP for dev

# Browser / web
flutter run -d chrome

# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000

# Physical device / iOS simulator
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000
# replace with your machine's LAN IP
```

> The Flutter app automatically uses `http://localhost:3000` in web builds and `http://10.0.2.2:3000` for Android emulators. You can override this with `API_BASE_URL` whenever needed.

## API endpoints

| Endpoint | Notes |
|---|---|
| `GET /api/health` | Postgres/Redis/Binance state and live counters |
| `GET /api/market/tickers` | Live market list with search, filters, and sorting |
| `GET /api/market/tickers/:symbol` | One ticker by symbol |
| `GET /api/market/stats` | Market summary stats and top movers |
| `GET /api/market/history/:symbol?range=1h|24h|7d|30d` | Candlestick history for charting |

## WebSocket

Backend WebSocket: `ws://HOST:3000/ws`

- Server-to-client: ticker updates and status messages
- Client-to-server: optional symbol subscription

## Verify the data flow

```bash
curl localhost:3000/api/health
redis-cli hlen market:tickers
redis-cli subscribe market:updates
psql postgres://crypto:crypto_password@localhost/crypto_pulse -c "select count(*) from tickers" -c "select count(*) from price_candles"
curl "localhost:3000/api/market/tickers?search=btc&sort=volume"
curl "localhost:3000/api/market/history/BTCUSDT?range=1h"
npx wscat -c ws://localhost:3000/ws
```

Offline test without Binance: `npm run mock:binance`, then set `BINANCE_WS_URL=ws://localhost:9443/ws/!ticker@arr`.
