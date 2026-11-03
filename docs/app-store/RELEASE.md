# App Store preparation — owner review required

This is release preparation, not a claim of App Store readiness or approval. The app is an independent illustrative calculator. Verified rule data, macOS builds, simulator tests and manual device validation remain launch prerequisites. No live payment or App Store Connect change has been made.

## Identity and listing draft

In-app name: **Defence Pension Calculator Pro – India**. Creator: **Jaspal Singh**. App Store names are limited to 30 characters; a compatible proposed store name is **Defence Pension Pro – India**. Confirm name availability and your legal seller identity in App Store Connect. The full in-app name remains visible in Welcome/About/report content. Display version/build comes from `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`; increment them as appropriate for the actual release.

Proposed subtitle (30-character budget): **Pension estimates, explained**

Proposed keywords (review Apple's current limit and localize):
`defence,pension,India,veteran,commutation,family,disability,arrears,OROP,calculator`

Description draft:

> Understand the components behind an illustrative defence pension estimate. Defence Pension Calculator Pro – India provides offline service pension, disability/war injury, family pension, commutation and arrears arithmetic with visible assumptions, user-entered DR rates and itemized reports.
>
> Choose your armed forces branch and rank, inspect the calculation breakdown, and create an offline PDF to retain or share. No account is required. Calculation inputs remain on your device; only a branch preference and welcome-screen setting are persisted.
>
> This release does not contain verified OROP, official commutation factor or 7th CPC pay-matrix tables. Unsupported regimes and additional benefit schemes are clearly marked unavailable. No missing official pension amounts or current DR rates are generated.
>
> Important: estimates are illustrative and do not establish entitlement. Final decisions and payments are determined by the competent sanctioning authority and official PPO/SPARSH records. Independent application; not affiliated with or endorsed by the Government of India, Ministry of Defence, PCDA or SPARSH.
>
> Created and developed by Jaspal Singh.

Do not advertise gratuity, leave encashment, Seva Nidhi, NPS/UPS or official OROP as functioning calculators while they remain unavailable. Do not describe synthetic assumptions as authenticated law or label this an official government app. Consider whether the unavailable routes and incomplete verified data meet the App Store's minimum-functionality/accuracy expectations before submitting.

## Icon and screenshots

The asset catalogue includes an original 1024×1024 opaque RGB app icon with a generic shield/financial motif. There are no government or military-service insignia. Verify the compiled iOS 16+ app-icon output with the current Xcode asset validator. Avoid alpha, pre-rounded corners, illegible small text and claims of official endorsement. The static launch mark is a separate image asset, not a stretched full-screen reference image.

Capture real simulator/device screenshots for the required App Store Connect iPhone and iPad size classes; use its current accepted resolutions rather than upscaling mockups. Suggested screens: Welcome, Home (all service categories), a clearly labeled **synthetic** service result, About Developer, Reports/PDF preview, References showing incomplete data. Use the same synthetic inputs across screenshots and keep disclaimers visible. Do not copy the reference image's demonstration amounts as real outcomes. Capture light and dark modes and large text for internal QA. Never upload images containing a real PPO, Aadhaar, PAN or bank details. The reference image is a design guide, not a captured app screenshot.

## Privacy and review

- Supply real public support and privacy-policy URLs controlled by the owner; none have been invented or published. Configure optional contact bundle keys only with real owner-provided details.
- The included `PrivacyInfo.xcprivacy` declares no tracking, no collected data and the UserDefaults required-reason category for own-app preferences (`CA92.1`). Confirm the current Apple reason wording matches the actual release. Audit any future SDKs before adding them.
- Answer App Store privacy questions based on the final shipped binary and its actual sharing/analytics/network behavior. The present native app makes no calculation-network requests, has no login/analytics, and does not send user inputs to a developer server. User-initiated exports go to destinations the user selects. PDF temporary files persist until system cleanup and shared copies remain with recipients; explain this in the public policy.
- Complete age-rating, financial-content, encryption/export-compliance, accessibility and regional availability questionnaires accurately. Do not assume a certification that has not been obtained.
- Review note draft: “Independent illustrative calculator. All unverified rules are explicitly labeled. No official government affiliation, guaranteed entitlement or current DR rate is claimed. Additional unverified schemes and missing OROP data show unavailable states. No login or purchase is required. PDF export is offline. Developer: Jaspal Singh.”
- Test accessibility with VoiceOver, Voice Control, Switch Control, bold text, maximum Dynamic Type, landscape, iPad multitasking and increased contrast. Check that colour alone never conveys branch selection/status, labels wrap, hit areas remain usable and both UI/PDF content are readable. PDF/UA compliance is not claimed.
- Validate the archive with current Xcode, run both test targets, verify signing/provisioning, test on a physical iPhone/iPad and conduct TestFlight review. No device testing, signed IPA or archive validation has been performed here.

## Optional premium reports — StoreKit 2 integration plan only

PDF export remains usable in the current app. No StoreKit products, prices, live transactions or payment secrets are activated. Digital reports sold inside iOS must use the payment mechanism required by Apple's applicable storefront rules. A personal UPI QR code, external web checkout or screenshot is not a substitute for an in-app digital-purchase entitlement.

1. Decide the product model: a non-consumable permanent premium exporter, subscription with genuine ongoing value, or a consumable report credit. Match the implementation and App Store disclosure to the actual value provided. Confirm available price points in App Store Connect; do not assume a custom INR 5 price is supported.
2. Configure owner-owned product identifiers, tax/banking agreements and localized disclosures in App Store Connect. Never embed App Store server keys in the client.
3. Use StoreKit 2 `Product` lookup and `purchase()`; handle verified success, pending, cancellation and unverified transactions separately. Unlock only after `.verified` transaction validation and a durable entitlement/credit grant. Finish a transaction only after its grant is recorded, and make transaction-ID processing idempotent.
4. Observe `Transaction.updates`. Use current entitlements and a visible restore mechanism for restorable product types. Consumables are not automatically restored by `currentEntitlements`: they need a durable, reconciled credit ledger and a defined recovery/support policy. Do not grant a credit from a screenshot or cached UI state.
5. Decide offline entitlement behavior and cross-device recovery without collecting unnecessary identifiers. If a server ledger is used, verify signed App Store transaction data/server notifications, handle refunds/revocations/retries and document retention/security.
6. Add StoreKit configuration tests for purchased/pending/cancelled/unverified results, interrupted purchases, duplicate notifications, restore, refunds and consumable credit exhaustion. Run sandbox/TestFlight purchase tests with the owner's configured account before enabling paid UI.

The PWA's Razorpay implementation lives on a separate branch and is not included or invoked by this native app.
