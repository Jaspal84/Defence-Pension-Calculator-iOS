# Validation report — 3 November 2026

Validated locally on Linux, Node 24.19.0. Actual results:

- TypeScript strict compilation and Vite production build passed.
- 80 Vitest tests passed: 54 calculation/resource/web-boundary tests (including named ports of all 44 native XCTest cases), 24 Worker/D1 payment tests and 2 PDF tests.
- PDF tests parse real PDFs, decode page text, verify status/disclaimer/breakdown content, and check multi-page and long-token handling. The runtime writer uses standard fonts with no network access.
- Browser tests exercise mobile layout, service/family/commutation/arrears, unavailable OROP, offline reload/calculation, no API cache entries, WCAG automated checks and a synthetic SDK callback waiting for backend webhook confirmation. All 6 Chromium browser tests passed.
- Dependency audit after upgrading the test runtime: 0 known npm vulnerabilities. No TLS, package-integrity or test assertions were disabled to make the checks pass.
- Wrangler deployment dry-run passed. This validates the bundle/binding declarations, not actual deployment, real Cloudflare authentication, a real database or provider connectivity.
- Native core regression: all 44 XCTest tests passed, 0 failures. The native iOS tree and existing files have no changes relative to the source branch.

Payment tests run the actual Worker handlers and real local D1 SQL, with a strict synthetic provider HTTP boundary that disallows unexpected outbound requests. They cover disabled/live-mode guards, fixed server pricing, server recomputation, CSRF, secure session cookies, ownership, malicious input, forged signatures, wrong amount/currency/order/payment ID, authorized-only status, missing/delayed webhook, duplicate events/orders, refunds, delayed capture after refund, provider outage, request size/rate limits and expiry cleanup. No real merchant account was supplied; live/test-gateway transactions and bank settlements have not been exercised.

Browser SDK tests use a stub checkout script and stub API responses to check the client flow; backend integrity is tested separately against actual Worker/D1 handlers. Automated accessibility checks do not replace manual VoiceOver/TalkBack/keyboard review. Physical iPhone, Android installation, actual UPI app-switching, and real-host offline/update behavior remain launch checks.

No site was published and live payments remain disabled. Official pension-rule correctness is not established: results accurately port the existing illustrative model and transparently reject missing verified data. Free-tier CPU/quota behavior, real merchant callbacks/webhooks/refunds, operational support and public legal policies require owner configuration and deployment acceptance before launch.
