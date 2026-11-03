# Defence Pension Calculator PWA

React + TypeScript + Vite frontend, decimal calculation library, and a same-origin Cloudflare Worker + D1 payment backend. The native iOS project is unchanged. Source audited: `feat/offline-pension-calculator`, commit `b9d452cb640aa639506386860ade39f7bef7a853`.

**All supported calculations remain illustrative.** No official PCDA, SPARSH, OROP, pay matrix or age-factor data has been invented. Unsupported verified regimes return explicit errors. Free calculations work offline after the first successful application-shell download. The optional ₹5 PDF buys report formatting, not verified pension entitlement.

## Develop and test

Node.js 24 LTS is the validated runtime; use `npm ci` with the lockfile.

```sh
cd web
npm ci
npm test
npm run build
npx playwright install chromium
npm run test:e2e
npm run deploy:check   # local packaging only; does not publish or activate payments
```

In the restricted cloud machine use writable Wrangler config and the installed Chromium:

```sh
export XDG_CONFIG_HOME=/workspace/scratch/pension-wrangler
export WRANGLER_SEND_METRICS=false
export PENSION_CHROMIUM=/usr/bin/chromium
npm test
npm run test:e2e
```

To develop both layers: run `npm run build`, then `npm run db:local` and `npm run worker:dev` in one terminal; run `npm run dev` in another. Browse the Vite localhost URL (default `http://localhost:5173`), whose `/api` requests proxy to Wrangler on 8787. Basic calculations do not need the backend. A production-like local preview is available through Wrangler's local port after building. Browser payment POSTs require the exact configured `APP_ORIGIN`. Use HTTPS in deployed environments; loopback HTTP is a development-only exception. A fresh build regenerates `dist/sw.js` with the exact public asset list and version hash.

## Architecture

- `src/core`: string monetary inputs, 38-digit Decimal arithmetic, half-up paise rounding, civil India-calendar dates, schema validation, exact copies of the Swift JSON resources.
- `src/components`: accessible forms and optional Razorpay checkout. No gateway secrets or PDF-unlock authority in browser code.
- `worker`: independently recomputes results, fixes price to **500 paise / INR**, creates provider orders, validates signatures and captured payment using the server API, processes signed raw-body webhooks, and serves paid PDFs.
- `migrations`: durable D1 orders, idempotency keys, webhook deduplication and request limits. No in-memory payment entitlements.
- `tests`: ports of all 44 native core XCTest cases plus decimal/web boundaries, actual local Worker/D1 integration with synthetic provider HTTP, PDF parsing/content/pagination, mobile/offline/accessibility and browser checkout tests.

See [source audit](docs/AUDIT.md), [deployment and merchant setup](docs/DEPLOYMENT.md), and [validation](docs/VALIDATION.md).

## Purchase and privacy model

The ₹5 report belongs to the immutable calculation sent at checkout. The server computes and stores its own report; it never accepts browser-computed amounts or PDF content. A random HttpOnly, Secure, SameSite=Strict host-only cookie binds the order to its originating browser. The database stores only a digest of the cookie. URLs/order references alone cannot download reports. Sessions expire after seven days. Clearing cookies loses automatic retrieval; retain the order/payment reference for merchant support. There is no email/account recovery system in this release.

A checkout signature or screenshot never unlocks a PDF. An authenticated `payment.captured` webhook **and** an independently fetched matching INR 500-paise captured payment are required. The webhook can complete verification if checkout closes. The download rechecks the payment provider to catch refunds before a refund webhook arrives. Refund events revoke future downloads; previously downloaded files cannot be retracted. Pending verification is shown explicitly; do not pay again while waiting.

Only public application assets are precached. API responses, provider SDKs, payment callbacks and PDFs are never cached by the service worker. Basic inputs stay in memory. Premium reports are retained for seven days, minimal payment metadata for 90 days, and rate-limit records briefly. The daily scheduled cleanup must remain enabled. Infrastructure/provider logs may have separate retention. No Aadhaar/PAN/PPO/bank details, analytics or advertising are collected by the application. The external checkout SDK loads only after the user chooses premium checkout. Document and publish the merchant's contact, privacy, cancellation/refund and delivery terms before live launch.

Payments ship **disabled**. There is no real merchant account configured and no live charge has been attempted. Free hosting configuration is provided, but no public deployment or new-host restoration is claimed.
