# Swift source audit and port decisions

Source: `b9d452cb640aa639506386860ade39f7bef7a853`. Native files, tests, Xcode settings and original workflows are unchanged on the PWA branch.

| Swift implementation | TypeScript implementation | Preserved behavior |
| --- | --- | --- |
| PensionCalculationEngine | `src/core/engine.ts:service` | 50% selected emoluments, synthetic INR 9,000 minimum, officer 20-year / other personnel 15-year gate, MSP switch, explicit classification/other pay inclusion, user DR |
| DisabilityPensionEngine | `disability` | attributable/aggravated only; positive disability; optional invalidment broad-banding boundaries; separate synthetic war injury rates and category gate |
| FamilyPensionEngine | `family` | beneficiary confirmation; 30/50/60/100 synthetic rates; inclusive enhanced end date; separate special/liberalized circumstance gates |
| CommutationEngine | `commutation` | service-only synthetic 50% limit; age 20–100; explicit factor; DR on original basic; explicit confirmed commencement + 15 years; leap-day restoration |
| ArrearsCalculationEngine | `arrears` | inclusive month/day boundaries; sorted/unique DR changes; partial calendar months; paise rounding per component; previous payments; negative recoveries |
| OROPCalculationEngine/repository | `orop` and copied JSON | exact missing-data message, no generated official entries |
| Validator/Money/DateUtilities | schemas/Decimal/civil dates | pay bounds 0–1e9, percentages 0–100, rank/branch/category match, age/service consistency, integer service periods, half-up rounding, Indian grouping |

The audited source is not a verified pension-law implementation. All formulas and thresholds are carried over as visibly synthetic assumptions; the port does not elevate them to official rules. Empty official factor/OROP/pay-matrix resources remain empty and unverified. Additional benefit schemes have not been invented.

Every one of the 44 core XCTest cases has a named counterpart in `tests/calculations.test.ts`; suite counts are 12 service, 8 disability, 5 family, 8 commutation, 6 arrears and 5 repository cases. The original iOS-only PDF test is represented by web PDF parse/content/multi-page tests. The TypeScript API takes a complete input object rather than Swift's three-argument convenience method; missing commencement/factor context is still rejected. JSON round-trip/resource tests are adapted to TypeScript schemas and bundled imports.

Boundary adapters are intentionally stricter than raw Swift memory values: money is decimal text with up to 20 fractional places, dates are valid ISO calendar days from 1900 to 2200, and DR schedules have at most 256 entries. This avoids binary floating-point conversion, timezone-dependent dates and unbounded requests. Internal arithmetic has 38 significant digits; displayed monetary components round half up to paise. Qualifying-service half-years remain validated but do not silently change the source formula. A calendar-date input represents the whole Indian civil day; enhanced duration does not expire at the user's local midnight.

The port retains the Swift app's limitations: no verified alternative emolument bases, invalidment concessions, category-specific family duration adjudication, apportionment, statutory caps, changing commutation adjustments, tax or interest. Correctness claims cover the audited synthetic model, not a person's legal pension entitlement.
