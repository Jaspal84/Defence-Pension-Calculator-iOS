# Benefit-calculator rule audit — blocked pending source access

Base: `feat/ios-pro-design`, commit `9cdb34c942ecfa051fac9638523a4573ac6ec054`.
Feature branch: `feat/verified-benefit-calculators`.
Audit date: 3 November 2026. Creator: Jaspal Singh.

**No new calculator formula has been activated.** All six official URLs supplied in the task were requested through the configured HTTPS proxy with TLS verification enabled. Every request was denied with HTTP 403 before an origin response was received. The running environment's enforced custom allowlist is empty. Previously saved DESW additions are in the editable draft, not the running policy. This is an environment access blocker, not proof that a government site or document is unavailable.

## Recorded evidence and data

- `source-access-evidence.json` preserves each exact URL, curl exit code and error. Curl's origin status `000` means no origin response; it is not a government HTTP status.
- `Data/Resources/BenefitRuleAudit.json` is versioned (`2026-11-03.audit-1`), machine-readable **audit-only provenance**, not an executable rule table. It distinguishes six decisions: retirement gratuity, death gratuity, military leave encashment, Agniveer Seva Nidhi, NPS and UPS.
- All enabled-rule IDs are empty. Document title/authority/number, publication/effective dates, rule numbers and source-content hashes remain null because the documents were not inspected. Requested labels identify the user's references without pretending to be verified document titles.
- The typed Foundation repository loads the catalog and rejects invalid/orphan source references or attempts to enable benefits through this audit-only schema. Existing dashboard destinations remain disabled. This work is not delivery of four verified calculators.

## Verification still required

| Benefit | Missing authoritative findings |
| --- | --- |
| Retirement gratuity | Army/Navy/Air Force and personnel-category applicability; retirement versus invalidment; eligible pay/DA; completed service periods; service boundaries; defence-specific ceilings and amendments; rounding |
| Death gratuity | Separate military death-benefit slabs, service boundaries, emoluments, effective dates, ceilings and rounding |
| Leave encashment | Service-specific leave orders, eligible leave categories, authorized balances, pay/DA definitions, ceilings and restrictions. The supplied civilian CAG booklet cannot establish military entitlement. |
| Agniveer Seva Nidhi | Inspect the original table and applicable amendments; verify four-year terms and exclusions; authoritative interest rules if available. The schedule and INR 11.71 lakh quoted in the request have not been independently verified here and are not installed as an official rule or guaranteed payout. |
| NPS | Separate applicable subscriber rules/notifications, eligibility, contributions, withdrawals and annuitisation. No regular-Armed-Forces applicability, fixed investment return or annuity rate is assumed. |
| UPS | Operative notification and amendments, eligible civilian categories, service/payout/minimum conditions, individual and benchmark corpus adjustment, final withdrawal and family provisions. Not automatically applicable to regular Armed Forces. |

Once sources can be inspected, record the actual issuing authority, document/order number, rule/paragraph, publication/effective dates, amendment history, precise population/benefit scope and a content hash. Derive independent expected arithmetic and boundary cases before implementing and activating each supported formula. Partial verification must not enable an entire service or scheme indiscriminately. An original press release does not alone establish currently operative amendments. Unknown interest rates and investment assumptions must be explicitly user supplied only after the applicable calculation method is verified.

No Hindi or Punjabi regulatory translations have been introduced without a verified rule text and accurate translation review. Existing English UI remains intact. No unverifiable PDF source references are shown as official.

## Network changes saved, not applied

The configuration draft preserves all earlier custom domains and adds the PIB, PFRDA and CAG aliases. Required source hosts saved are:

- `desw.gov.in`, `www.desw.gov.in`
- `pib.gov.in`, `www.pib.gov.in`
- `pfrda.org.in`, `www.pfrda.org.in`
- `cag.gov.in`, `www.cag.gov.in`

Earlier PCDA, pensionersportal and Swift domains are preserved. The draft save succeeded and reports publication required. Review and save it in environment settings, then publish/apply it through the supported product workflow. Saving a draft alone neither applies runtime egress nor verifies a document. If an official page redirects to another government host, inspect the redirect and add only the actual needed destination through the supported settings flow. Do not bypass the proxy or disable TLS. Alternatively, original official PDF files can be supplied for inspection, with amendment/current-applicability verification still required.

## Validation and unaffected changes

- **64 Foundation XCTest tests executed: 64 passed, 0 failed** (57 existing + 7 audit-provenance/integrity tests). Output: `validation/benefit-audit-tests.txt`.
- New tests verify that unsupported benefits remain disabled, no missing official metadata is invented, proxy denial is not an origin response, civilian references do not establish military authority, and sources resolve without orphan records. These are safety/provenance tests, **not tests of unimplemented benefit formulas**.
- Existing financial engines, validators, UI routes, calculation tests and reference tables are unchanged. The new audit resource and repository are registered in both the package and Xcode project.
- PDF footer now explicitly reads “Developed by Jaspal Singh | Page …”. A new PDFKit test checks the footer region on every page. It has not run on Linux.
- Resource integrity and Xcode plist checks passed. PDF/test sources passed Swift syntax parsing. Xcode/UIKit/PDFKit/simulator execution remains unavailable in this Linux environment. No iOS build, formula verification, translation validation or signed IPA is claimed.

Next work remains blocked on official-document access. After applying the network settings, retry the same URLs and resume the regulatory audit before entering formula code or changing dashboard availability. No merge into main is authorized or performed.
