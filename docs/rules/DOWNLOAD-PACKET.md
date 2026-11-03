# Official document packet needed to resume the calculators

Status checked 3 November 2026: the running environment still reports revision 1, restricted/enforced networking and an empty custom allowlist. Government hosts in the new request are not permitted. The six new targets have **not been retried against this unchanged policy**, consistent with the instruction to retry after publication/application. No new government response is claimed. The earlier HTTP 403 denials came from the environment proxy, not the government websites.

The exact supplied URLs are preserved in `source-download-requests.json`. They are uninspected candidates, not verified rule citations. The newer Agnipath PRID **1834227** is retained separately from the previous request's PRID **1833765**. The new circulars URL uses exactly `desw.gov.in`, as supplied; it is not silently replaced with the prior `www.desw.gov.in` URL. Query parameters and the PFRDA `www`/non-`www` hosts are preserved.

## How to supply documents

Use your separately accessible browser. Open each official landing page below and use its **Download/PDF** link to save the original full document. Include cover/gazette pages, tables, schedules, annexures, amendments and corrigenda. For an HTML-only PIB release, save the full webpage/HTML where possible, or use Print → Save as PDF with the complete contribution table and page header/footer showing its official URL, publisher and publication date. A printed webpage is identified as such; it is not mislabeled an original gazette PDF.

Attach the files here in priority order. Alongside each file, supply its official landing URL and, if available, direct PDF URL and download date. Preserve original filenames. Do not send only screenshots, search snippets, privately rewritten summaries or a first page without annexures. Do not provide personal pension documents or identifiers.

If official rules cross-reference another order that defines eligibility, emoluments, ceilings, rates or payout adjustments, include that order too. Include amendments applicable to the dates you want the calculator to cover; an original announcement alone cannot establish current rules. There is no need to calculate hashes yourself: the original bytes will be hashed with SHA-256 after receipt and inspection. A hash establishes byte identity, not legal authenticity or current applicability.

## 1. Agniveer Seva Nidhi — first packet

Start with the exact Ministry of Defence/PIB announcement supplied:

https://www.pib.gov.in/PressReleasePage.aspx?PRID=1834227&lang=1&reg=1

Please attach:

1. The complete release containing the year-wise package, employee contribution and government matching table, plus its published engagement/exit terms.
2. The operative Ministry of Defence/service scheme or implementation order governing that schedule, and any amendments or corrigenda relevant to the supported engagement dates. If an order applies to only one service, supply the corresponding authority for the others before extending coverage.
3. The official Seva Nidhi fund/interest instructions or notifications, if published: applicable rate periods, contribution timing, compounding/crediting method and treatment at exit. If no authoritative rate is available, say so and provide any published calculation-method instructions; an optional user-entered rate still requires a clearly disclosed calculation method.
4. Any operative provisions needed to distinguish normal four-year completion from early exit, death/disability, or selection for further service. Unsupported exit types will remain disabled.

The indicative exit amount in a press release is not a guaranteed payout or a substitute for the contribution/interest calculation. No particular rate or compounding convention will be invented.

## 2. Military retirement/death gratuity — separate service/category packets

Open the regulations and circulars indexes:

https://desw.gov.in/pension-regulations

https://desw.gov.in/index.php/en/pension-circulars

From their linked documents, attach the operative **pension regulations and gratuity orders** covering:

- Army commissioned officers and Army JCOs/other ranks.
- Navy commissioned officers and the applicable sailor categories.
- Air Force commissioned officers and the applicable airman/warrant-officer categories.

For each population, include retirement gratuity provisions **and separate death gratuity provisions**, with their applicable amendments. The needed pages/orders must establish qualifying-service periods and thresholds, treatment of completed service periods, emolument/DA definitions, multipliers/slabs, ceilings, rounding, effective dates and any relevant invalidment rules. Include definitions and referenced schedules, not isolated formula excerpts.

Also attach the actual **defence authority** extending/revising any gratuity ceiling for these personnel and dates. A civilian ceiling announcement or its press summary does not by itself establish a military ceiling. Exact operative order numbers cannot responsibly be supplied before these indexes/documents are inspected; they must be taken from the official document cover and amendment chain, not guessed.

## 3. Military leave encashment — service-specific authority

Use the DESW indexes above and the official service publications they reference to obtain the operative Army, Navy and Air Force **leave/leave-encashment regulations or implementation orders**, with amendments for each personnel category and exit date to be supported.

The packet must establish eligible leave types, authorized leave balance, applicable day limits, lifetime/prior-encashment restrictions where relevant, pay components, DA, treatment of other allowances, divisor/calculation method, retirement/death/other exit distinctions and rounding. Include any separate service/category order needed to establish these facts.

The previously supplied civilian CAG/CCS booklet may be attached as a separately labeled civilian reference, but it will not authorize military results. If a military order cannot be located for a service/category, that selection will stay unavailable.

## 4. NPS and UPS — distinct subscriber and regulatory packets

Official overview:

https://www.pfrda.org.in/en/web/pfrda/schemes/national-pension-system/unified-pension-scheme

Download the full gazette document linked on the **UPS Regulations 2025** page:

https://www.pfrda.org.in/w/regulatory-framework/regulations/31-pension-fund-regulatory-and-development-authority-operationalisation-of-unified-pension-scheme-under-national-pension-system-regulation-2025

Download the full document linked on the **Central Civil Services UPS Rules 2025** page:

https://pfrda.org.in/w/regulatory-framework/notifications/the-central-civil-services-implementation-of-the-unified-pension-scheme-under-the-national-pension-system-rules-2025

Include all linked schedules/annexures, amendments/corrigenda and operative government notifications/implementation orders these documents rely on. The packet needs to establish eligible subscriber categories, option/effective dates, qualifying service, employee/employer contributions, assured/minimum payout conditions, relevant pay basis, individual versus benchmark corpus, final-withdrawal adjustments, exit timing and family payout provisions.

For **NPS**, also supply the operative subscriber-category contribution and exit/withdrawal/annuitisation regulations and applicable government orders. UPS material alone does not establish all NPS rules. Identify the intended subscriber category and provide its official authority; do not infer that either scheme applies to regular Armed Forces. Future investment returns or an annuity quotation are assumptions, not guaranteed government benefits.

## What happens after receipt or network application

1. Recheck observed runtime network policy before any retry. Publication/save is not assumed to have applied until observed.
2. Retrieve the six exact targets if access permits, or inspect the attached original files; follow official referenced documents without bypassing restrictions.
3. Record inspected source title/authority, actual document and rule numbers, publication/effective dates, applicability, amendments and content hash in the rule audit. Keep unknown values null.
4. Activate only the complete verified service/category/date/exit scope. Derive independent expected values and boundary tests first. Preserve all existing 64 tests, add formula tests only for inspected rules, and run iOS tests where supported.

No formula or confirmed-source hash has been added to `BenefitRuleAudit.json` during this blocked checkpoint. No payments or main-branch merge are involved.

Validation at this checkpoint: all 64 Foundation XCTest tests passed, 0 failed; resource-integrity checks passed. No new formula tests can be justified before inspecting the operative rules. Xcode/UIKit/PDFKit/simulator tests remain unavailable on this Linux host.
