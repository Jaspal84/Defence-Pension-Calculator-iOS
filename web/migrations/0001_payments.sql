CREATE TABLE orders (
  id TEXT PRIMARY KEY, session_hash TEXT NOT NULL, request_key TEXT NOT NULL,
  gateway_order_id TEXT UNIQUE, payment_id TEXT UNIQUE,
  state TEXT NOT NULL DEFAULT 'creating' CHECK(state IN ('creating','pending','paid','revoked','failed')),
  server_verified INTEGER NOT NULL DEFAULT 0, webhook_verified INTEGER NOT NULL DEFAULT 0,
  report TEXT, created_at INTEGER NOT NULL, expires_at INTEGER NOT NULL,
  UNIQUE(session_hash, request_key)
);
CREATE INDEX orders_expiry ON orders(expires_at);
CREATE TABLE webhook_events (id TEXT PRIMARY KEY, received_at INTEGER NOT NULL);
CREATE TABLE rate_limits (bucket TEXT PRIMARY KEY, count INTEGER NOT NULL, expires_at INTEGER NOT NULL);
