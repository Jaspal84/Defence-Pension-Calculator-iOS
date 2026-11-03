# Defence Pension Calculator Pro – India

Created and developed by **Jaspal Singh**. This native redesign adds a navy/gold dashboard, About Developer screen and professional PDF reports while preserving the original financial engines. See [Pro design and M1 build instructions](docs/PRO-DESIGN.md), [current validation](docs/PRO-VALIDATION.md), and [App Store preparation](docs/app-store/RELEASE.md). The separate PWA is on `feat/pension-pwa` and is not included in this native branch.

The current benefit-rule audit is [blocked pending official-source access](docs/rules/BENEFIT-AUDIT.md). The four additional benefit destinations remain disabled; no new verified formulas are claimed. Current audit regression: 64 Foundation tests passed.


Native, offline SwiftUI iOS 16+ application for exploring Indian armed forces pension calculations. Built with Swift 5 language compatibility and tested using Swift 6.0.3 for the platform-independent domain layer. No external package dependencies, login, analytics or calculation networking.

**Current release is an illustrative calculator, not a verified pension entitlement implementation.** Official pension orders and reference tables could not be retrieved under the cloud environment's network policy. No OROP amounts, official commutation factors or pay matrix values have been invented. These datasets are explicitly incomplete. The application blocks verified 7th CPC/OROP calculations and explains missing data rather than returning an alleged official pension.

## Open and run

On macOS with Xcode 15+ and an iOS simulator installed:

```sh
cd DefencePensionCalculator
open DefencePensionCalculator.xcodeproj
xcodebuild -list -project DefencePensionCalculator.xcodeproj
xcodebuild -project DefencePensionCalculator.xcodeproj \
  -scheme DefencePensionCalculator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
xcrun simctl list devices available
# Replace SIMULATOR_UDID with an available iPhone simulator identifier.
xcodebuild -project DefencePensionCalculator.xcodeproj \
  -scheme DefencePensionCalculator \
  -destination 'platform=iOS Simulator,id=SIMULATOR_UDID' \
  CODE_SIGNING_ALLOWED=NO test
```

The shared scheme includes the application and hosted XCTest target. For a physical device, select your development team and signing identity in Xcode. No `.ipa` is included. The project declares iOS 16.0; iOS compilation, UI behavior, accessibility and PDF rendering remain unverified in this Linux environment. The included macOS GitHub Actions workflow runs core tests, simulator compilation and iOS tests when GitHub Actions is available; its results are not asserted here.

## Cloud / Linux development

Use the existing checkout; each cloud task is isolated and does not need a Git worktree. Linux can compile and test the Foundation-only engines, models, repositories and currency/date utilities. It cannot run SwiftUI, UIKit, Xcode or an iOS simulator.

```sh
# Linux x86_64 only; installs under /workspace/toolchains.
./scripts/install-linux-swift.sh
./scripts/test-core.sh
python3 scripts/validate-project.py
```

The installer uses the official Swift 6.0.3 archive and detached signature, imports official signing keys over verified HTTPS from the Swift project repository, and pins the Swift 6 release signing fingerprint. It preserves proxy settings, TLS verification and signature verification. The current image supplies the required runtime libraries; other Linux distributions may need additional Swift prerequisites. Toolchain and build caches live outside this checkout. The test helper redirects caches into writable paths and limits parallelism to four jobs. On a normal macOS terminal, `swift test --jobs 4` from the repository root also runs the core tests.

Required for Linux bootstrap: `download.swift.org` and `raw.githubusercontent.com`. Official data work requires permitted official source hosts, including `pcdapension.nic.in`, `pcdapension.gov.in`, `desw.gov.in`, `www.desw.gov.in` and `pensionersportal.gov.in`. These are source destinations to investigate, not verified document citations. Git uses the platform's existing HTTPS proxy authentication. No additional secrets or service processes are needed.

## Application workflow

- **Pension Calculator (Home / Calculators):** choose branch, personnel category, rank, dates, service duration, pay inclusion assumptions, regime and your own DR rate. View basic pension, DR and monthly estimate.
- **Disability / Family calculators:** separate disability/war injury and family screens. Disability uses the Calculator's service inputs. Eligibility and circumstances are explicit inputs. Special, liberalized and enhanced family modes enforce their respective user-confirmation gates; expired enhanced periods are rejected.
- **Commutation / Arrears calculators:** supply service basic pension, age next birthday, percentage, dates and a factor from your records for illustrative commutation. Without an explicit factor, missing official factors cause an error. Arrears support multiple DR change dates, partial months and previous payments.
- **OROP:** select exact branch, rank, service, cohort, pension category and revision. Until a verified table is supplied, displays “Official OROP table data unavailable for this selection.”
- **Reports:** snapshot of the latest successful calculation, rule identifiers, limitations, text sharing and offline PDF generation. Calculations are independent; commutation is not silently combined with an earlier service result. Recalculate after input changes. A failed calculation clears the summary so it cannot be exported as a successful new result.

Only a branch preference and welcome-screen setting are retained in UserDefaults. Personal identifiers are not requested. PDFs contain only the current summary, use unique temporary file names and may be shared explicitly through the system share sheet.

## Architecture

`Domain` contains typed Codable models, validation and pure engines, along with Foundation-only routing, developer metadata and report models. `Data` decodes bundled JSON and implements the injected rules protocol. `Presentation` uses an iOS 16-compatible `ObservableObject` view model and five navigation tabs. `Utilities` contains Indian currency/date handling and the UIKit PDF renderer. The Swift package shares these same domain sources, not a second implementation. Every application source and JSON resource is registered in the checked-in Xcode project.

Currency calculations use Decimal. Inputs from the required Double convenience interfaces are checked for finiteness before conversion. Illustrative components round half up to two decimal places; this policy is disclosed and must not be confused with statutory rounding rules. India Gregorian calendar days drive arrears and restoration. Dates are inclusive for arrears; the restoration commencement is explicit and never inferred from retirement.

`CommutationEngine.calculateCommutation(basicPension:ageNextBirthday:percentage:)` requires an engine initialized with a confirmed `CommutationInput` context. The shorter interface cannot infer legal commencement or a missing official factor. The full Decimal `calculate(_:)` interface is used by the app.

## Reference data and scope

| Resource | Packaged state |
| --- | --- |
| `RankMapping.json` | Curated branch/category display names; not an official pension equivalence table and not exhaustive |
| `PensionRulesMetadata.json` | Traceable identifier for application illustrative assumptions; no invented government citation |
| `CommutationFactors.json` | Versioned, unverified, empty official dataset |
| `PayMatrix7CPC.json` | Versioned, unverified, empty official dataset; pay entered manually |
| `OROPReferenceTables.json` | Versioned, unverified, empty official dataset |

Illustrative assumptions are deliberately visible: 50% of selected emoluments, ₹9,000 assumed service minimum, 20-year officer / 15-year other personnel service thresholds, user-confirmed pay inclusion, disability rate 30%, war injury rates 100% on invalidment / 60% on retirement at total disability, optional invalidment broad-banding to 50/75/100, family rates 30/50/60/100%, and service-only commutation up to an assumed 50%. **These are synthetic reference assumptions, not verified current law or a comprehensive entitlement model.** They must not be used to decide eligibility or payment. Invalidment service concessions, average-emolument alternatives, exceptional minimum service, caps, category-specific eligibility, family apportionment, automatic enhanced durations, changing commutation adjustments, tax and interest are unsupported. The calculator returns typed errors for unsupported verified regimes and ineligible combinations rather than substituting official-looking answers.

Arrears assume that the DR schedule applies to the difference between the previous and revised basic amounts, with calendar-day proration. It splits on month and DR change boundaries, rounds each basic and DR component to paise, subtracts previously paid arrears and preserves negative recoveries. This is an estimate; alternative sanction-specific proration needs a verified rule implementation.

Before a verified rules release, obtain authoritative orders, record exact title/authority/order number/effective and publication dates/URL/applicability/version, audit transcription, implement regime-specific policy and add independently checked official example tests. Setting a JSON `verified` flag alone is insufficient: verified formula regimes currently remain disabled in code. Never generate missing OROP rows. A qualified reviewer must resolve category equivalence and pension-rule scope before production entitlement use.

## Validation

See [current Pro validation](docs/PRO-VALIDATION.md) and [the Pro XCTest output](validation/pro-core-tests.txt). [VALIDATION.md](VALIDATION.md) records the earlier 44-test baseline. All numeric test examples are explicitly synthetic. No official example results are asserted. PDF content/pagination tests exist in the iOS test target and require a simulator. The project is suitable for continued local Xcode development; production acceptance remains blocked on verified rule data and actual iOS validation.

> This calculator provides estimates based on selected pension rules and reference data. Final pension entitlement and payment are determined by the competent pension sanctioning authority and official PPO/SPARSH records.
