# Free-tier deployment and merchant configuration

## Hosting

The configuration targets **Cloudflare Workers Static Assets + a Worker API + D1**, all on one HTTPS origin. Static assets and a small backend can fit the free tiers, subject to the provider's current requests, CPU, database/storage and egress limits. A free tier is not an uptime or unlimited-capacity guarantee. The compact server PDF renderer avoids external fonts and a large runtime PDF dependency, but load-test representative long arrears reports on the actual deployed free plan. No paid hosting plan or custom domain has been purchased.

Prerequisites still needed: your Cloudflare account, an actual D1 database UUID, production origin, and your own approved merchant account. No credentials are preconfigured. Use secure environment settings/CLI secret prompts; never paste secret values into chat or tracked files. Do not set any `VITE_*` payment secret.

```sh
cd web
npm ci
npm run build
npx wrangler login
npx wrangler d1 create pension-payments
```

Replace the top-level placeholder `database_id` in `wrangler.toml` with the returned UUID. Keep `PAYMENTS_MODE = "disabled"`. Use a separate D1 database and Worker for staging before any live account is connected. The `local` environment is for local emulation only.

```sh
npx wrangler d1 migrations apply pension-payments --remote --env=""
npm run deploy:check
npm run deploy
```

Set `APP_ORIGIN` to the exact deployed HTTPS origin, without a trailing slash, and redeploy. Confirm the free calculator, install/offline behavior, security headers, `/api/config` disabled state, scheduled cleanup and errors for unconfigured payment routes. The database binding is a prerequisite: a dry-run can validate packaging with the placeholder but cannot validate a real database or publish a working payment service. The daily cron purges expired report contents, old payment records/events and rate-limit buckets.

`npm run deploy` publishes your Worker; no deployment has been performed by this task. The CI workflow validates builds/tests without deploying or requiring merchant credentials. In this managed cloud instance, registry/Git operations require the configured proxy, and live Razorpay/Cloudflare API access may require explicit network-domain additions. Do not bypass policy or TLS verification.

## Backend configuration

| Setting | Purpose | Browser visibility |
| --- | --- | --- |
| `PAYMENTS_MODE` | `disabled` (shipped default), `test`, or `live`; unknown values fail closed | Mode only |
| `APP_ORIGIN` | Exact allowed HTTPS browser origin; localhost HTTP only for development | Public origin |
| `MERCHANT_NAME` | Your real merchant display/legal identity | Displayed at checkout |
| `SUPPORT_EMAIL` | Real operational merchant support address; required for live mode | Public support contact |
| `RAZORPAY_KEY_ID` | Merchant test/live key ID matching the mode | Sent only when checkout creates an order; not secret |
| `RAZORPAY_KEY_SECRET` | Razorpay API and checkout HMAC secret | Server secret only |
| `RAZORPAY_WEBHOOK_SECRET` | Separate chosen secret registered on the Razorpay webhook | Server secret only |
| `LIVE_PAYMENTS_CONFIRMED` | Must equal `merchant-owned-account-verified` for live mode | Server configuration only |

Set secret values using `npx wrangler secret put NAME --env=""`. These commands prompt securely; do not put values in shell history. For local test development, use an ignored `.dev.vars.local` file appropriate to Wrangler's local environment, and never commit it. D1 stores only the hashed session ID, order/payment IDs, verification flags and computed report, not API credentials.

## Razorpay test-mode setup (before any real payment)

1. Create your own Razorpay merchant account and complete required business/KYC checks. Confirm this product/use case and the ₹5 minimum order are accepted. Availability of UPI/payment methods, fees, taxes and settlement terms depend on your merchant agreement and current provider policy.
2. Add test credentials as backend secrets and set `PAYMENTS_MODE="test"`; use only `rzp_test_...` keys. Configure your real merchant name/support details. Set automatic capture in the merchant dashboard or complete the provider's supported capture flow: an authorized-only payment never unlocks a report.
3. Create an HTTPS webhook at `https://YOUR_ORIGIN/api/webhooks/razorpay`, with the independently configured webhook secret. Subscribe to **`payment.captured`** and **`refund.processed`**. Preserve the exact raw request body for signature verification; do not put another middleware in front that rewrites JSON. Razorpay must be able to reach this URL. Inspect failed deliveries and retries in your own dashboard.
4. Make a supported synthetic estimate. Confirm the server order amount is 500 paise and currency INR. Exercise successful test checkout, UPI availability where supported by the sandbox, a dismissed checkout, failed/authorized-only payment, delayed webhook, repeated delivery, refund and retry. A test receipt, checkout callback, static QR scan or screenshot is never treated as proof of capture.
5. Verify browser A cannot access browser B's report, that expired sessions cannot download, provider outages do not unlock reports, and refunded orders cannot regain access after a delayed captured event. Confirm seven-day expiry and scheduled cleanup. The provided tests use synthetic HTTP responses and do not certify your real merchant integration.

The callback verifies `order_id|payment_id` with the server API secret and fetches payment details. The webhook verifies raw-body HMAC with the separate webhook secret, fetches payment details itself and checks payment/order IDs, 500 paise, INR, captured status and no refund. A PDF requires both server and webhook flags; download fetches provider state again. Duplicate event IDs and checkout request keys are durable in D1; state transitions cannot undo a refund. Gateway failure responses never include secrets in application error text.

## Where proceeds reach your bank

The application **does not collect or store your bank account or redirect funds to a personal UPI QR**. Razorpay collects the customer's payment into your verified merchant balance and settles eligible proceeds to the bank account you register and verify in your merchant dashboard, according to its settlement schedule and deductions. Configure and verify that bank account with Razorpay itself. Reconcile order/payment IDs in D1 with Razorpay's payments/settlements dashboard. Keep the displayed report/payment reference for support and refunds. Test-mode transactions do not move money or settle to a bank.

₹5 is the **total server-enforced report price**, not a promised net payout. Gateway charges, applicable taxes, reserves, refund deductions and settlement minimums can reduce or delay proceeds. Confirm the economics and tax/invoice obligations for such small transactions with the provider and your adviser. No particular fee or zero-fee UPI treatment is assumed.

## Live launch remains disabled

Only the owner should enable live mode after configuring their own verified merchant account and completing test-mode acceptance. Use matching `rzp_live_...` credentials and a separate live webhook secret. Explicitly set the activation acknowledgement only then. Publish real merchant identity, support, privacy, delivery, cancellation and refund terms with actual response/refund timelines; the current explanatory policy text does not invent those commitments. Confirm regulatory/provider approval, tax treatment, accessibility/manual testing, monitoring, free-tier limits, backup/recovery, data-processing/retention obligations and production security headers. Do not describe the app as an official pension authority.

A random anonymous cookie is the report access credential; no account/email recovery is implemented. Document this for buyers and establish a secure manual support procedure for lost cookies or charged-but-undelivered orders before live launch. Do not grant access based on screenshots. Verify disputed payments with your merchant dashboard/server API. Do not log full calculation payloads, secrets, cookies or card/UPI credentials. Configure provider/hosting log retention separately from the app's seven/90-day database retention.
