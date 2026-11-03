# Native Pro validation — 3 November 2026

Host: Debian 13 Linux x86_64. Official signature-verified Swift 6.0.3 compiler, Swift 5 language mode. Apple SDKs, Xcode, ibtool and simulators are unavailable.

| Check | Outcome |
| --- | --- |
| Shared Foundation build and XCTest | **57 executed, 57 passed, 0 failed**: original 44 + 13 presentation/report model tests |
| Original financial engines, validators, rule/rank models and JSON | Unchanged relative to `feat/offline-pension-calculator` |
| SwiftUI/UIKit/PDFKit/UI-test source syntax | Parsed with `swiftc -frontend -parse`; not SDK type checking |
| Xcode project and privacy manifest plist | `plutil -lint` passed |
| Source/resource registration, shared scheme and launch storyboard XML | Integrity checks passed |
| iOS build / hosted unit tests / UI tests | Not run: Xcode unavailable |
| Physical iPhone/iPad, VoiceOver, PDF visual appearance | Not run |
| App Store archive, signing or IPA | Not produced |

The original `PensionPDFExporterTests.testPDFContainsStatusDisclaimerAndMultiplePages()` is preserved. Three new UIKit/PDF/theme tests and eight UI tests are registered for the simulator. These **12 iOS-only tests have not run** and are not counted among the 57 Linux passes. The scheme's expected iOS total is 61 unit tests plus 8 UI tests; actual execution must be confirmed on Xcode. New pure tests cover all ten routes and statuses, tab order, developer credit, dynamic bundle versions, absent/safe optional contacts, report text/codability and verified/applied-only source references. Existing invalid-input and financial boundary tests continue to pass.

The shared report text initially exceeded Swift's type-checking complexity budget; splitting it into explicit array assembly fixed compilation. UI and PDF code still require actual iOS SDK compilation despite passing syntax parsing. XML/plist checks do not replace ibtool/asset compilation. The renderer produces text instead of screenshots and includes pagination; selectable text, long-row behavior and disclaimer coverage are asserted in iOS PDF tests, whose execution is still pending.

Official rule verification remains incomplete, and additional benefit calculators are explicitly unavailable. No physical testing, payment activation or App Store readiness is claimed. Follow `docs/PRO-DESIGN.md` for M1/Xcode validation and `docs/app-store/RELEASE.md` for remaining launch requirements.
