-- Idempotent schema. Safe to run on every start.

CREATE TABLE IF NOT EXISTS symbols (
  symbol       TEXT PRIMARY KEY,
  base_asset   TEXT NOT NULL,
  quote_asset  TEXT NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Latest 24h snapshot per symbol (one row per symbol, upserted).
CREATE TABLE IF NOT EXISTS tickers (
  symbol                TEXT PRIMARY KEY REFERENCES symbols(symbol) ON DELETE CASCADE,
  last_price            NUMERIC NOT NULL,
  price_change          NUMERIC NOT NULL,
  price_change_percent  NUMERIC NOT NULL,
  open_price            NUMERIC NOT NULL,
  high_price            NUMERIC NOT NULL,
  low_price             NUMERIC NOT NULL,
  volume                NUMERIC NOT NULL,
  quote_volume          NUMERIC NOT NULL,
  trade_count           BIGINT  NOT NULL DEFAULT 0,
  event_time            TIMESTAMPTZ NOT NULL,
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_tickers_quote_volume ON tickers (quote_volume DESC);
CREATE INDEX IF NOT EXISTS idx_tickers_change_pct   ON tickers (price_change_percent DESC);

-- 1-minute OHLC candles built from the live ticker stream (history for charts).
CREATE TABLE IF NOT EXISTS price_candles (
  symbol      TEXT NOT NULL REFERENCES symbols(symbol) ON DELETE CASCADE,
  bucket      TIMESTAMPTZ NOT NULL,
  open        NUMERIC NOT NULL,
  high        NUMERIC NOT NULL,
  low         NUMERIC NOT NULL,
  close       NUMERIC NOT NULL,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (symbol, bucket)
);
CREATE INDEX IF NOT EXISTS idx_candles_bucket ON price_candles (bucket);
