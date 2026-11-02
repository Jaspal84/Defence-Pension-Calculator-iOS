# Build and validation report

Validation date: 2 November 2026 (India). Host: Debian 13, Linux x86_64. Toolchain: official Swift 6.0.3 Ubuntu 22.04 release, signature verified with Swift 6 signing fingerprint `52BB7E3DE28A71BE22EC05FFEF80A866B47A981F`.

| Check | Actual outcome |
| --- | --- |
| Foundation domain/package compilation | Passed using Swift 6.0.3 in Swift 5 language mode |
| Core XCTest | 44 executed, 44 passed, 0 failed; see `validation/core-tests.txt` |
| Bundled JSON decoding | All 5 files decoded by repository tests |
| Xcode project plist parsing | `plutil -lint` passed |
| Source/resource registration, references, scheme XML, deployment settings | `python3 scripts/validate-project.py` passed |
| SwiftUI/view-model/PDF source syntax | `swiftc -frontend -parse` passed; not iOS type checking |
| Installer/startup helpers | Shell syntax passed; installed-toolchain and test helper paths executed successfully |
| Xcode listing | Attempted; `xcodebuild: command not found` (exit 127) |
| iOS simulator build / XCTest / PDF test | Not run: Xcode and Apple SDKs unavailable on Linux |
| iPhone UI, accessibility, dark mode and PDF appearance | Implemented, not runtime verified |
| Official rule/table verification | Blocked: official source destination denied by network policy |
| Signed `.ipa` | Not produced |

Core tests cover service arithmetic, MSP and classification/other pay gating, synthetic minimum and service boundaries, invalid dates/ranks/amounts/regimes, disability attribution and broad-banding boundaries, distinct war injury calculations, family circumstances and enhanced end-day handling, commutation limits/factor requirements/context/restoration/leap dates, DR on original basic, arrears across DR changes and partial months, negative recoveries, Decimal rounding, Indian grouping, JSON decoding and missing OROP data. The initial core run caught a currency-grouping failure; explicit Indian grouping fixed it and all 44 tests passed on rerun. The Swift Testing footer reports zero tests because these are XCTest suites; the preceding XCTest count is authoritative.

The iOS-only PDF test checks multi-page output and extracted status/disclaimer/content with PDFKit. It is conditionally excluded on Linux and is not included in the 44 executed tests. No official examples were available to verify and no synthetic example is labeled official.

The project declares iOS 16.0 and uses ObservableObject/@Published and iOS 16-compatible navigation, sharing and form APIs. Static declarations and syntax do not prove SDK compatibility: run the README's macOS build and simulator test commands before distribution. GitHub Actions is configured for those checks; no CI success is claimed in this report.

The reusable cloud setup retains the compiler on disk and needs no background service or secrets. Saved configuration and publication are separate: environment settings review/save and publication are user actions. A new-task snapshot restoration has not been independently tested.
