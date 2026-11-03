# Pro native redesign

Source branch: `feat/offline-pension-calculator` (`b9d452c`). Development branch: `feat/ios-pro-design`. The separate PWA is preserved on `feat/pension-pwa`; its web/payment files are not part of this native branch. No branch is merged into main.

The supplied reference image guides the hierarchy and navy/gold/tricolour treatment. The app uses original SwiftUI vector artwork and generic SF Symbols; it does not reproduce the reference's government seal, service crests, demonstration pension figures or unverified contact details. The original calculation engines, rank models, rule JSON and existing calculation tests are preserved.

## Implemented changes

- A static navy launch storyboard and a lightweight, scrollable SwiftUI welcome screen show the app title, subtitle and developer credit. The welcome screen reads version/build from the actual bundle and can be disabled in Settings. There is no timed blocking animation; reduced-motion users encounter no compulsory motion. Static launch screens cannot dynamically query the bundle version; version appears in the welcome/About screens instead of a hardcoded storyboard number.
- Home has three branch selectors, two prominent primary calculator cards and an adaptive grid for the other eight routes. It includes a developer footer and an explicit illustrative-status notice. Branch selection updates the existing view model's branch/rank selection.
- Home, Calculators, Reports, References and Settings each have native navigation. Six routes reuse the existing service/OROP/commutation/disability/family/arrears views. Gratuity, leave encashment, Agniveer Seva Nidhi and NPS/UPS route to specific unavailable explanations. The source has no verified engines for these schemes, so no fake result or eligibility determination is created.
- About Developer is available from Settings and displays Jaspal Singh, the requested description, actual version/build, copyright and independence disclaimer. Contact and website links appear only if real values are explicitly supplied in the bundle's `DeveloperContactEmail` and HTTPS `DeveloperWebsiteURL` keys. The reference image's sample contact entries are not configured.
- A navy/white PDF has tricolour rules, developer attribution, calculation inputs, result breakdown, applicable commutation/restoration rows, assumptions, rule identifiers, source-reference availability, separate calculation/generation dates and page numbers. It wraps long words, URLs and multi-page rows. Text is drawn as text, not a flattened screenshot. Only metadata explicitly marked verified and actually applied to the calculation can appear as an official reference. A PDFKit preview and system sharing work offline.
- Service context is included in reports as explicitly labeled context; independent family/commutation/arrears inputs drive their own existing calculations. Changing service context does not silently confer family/scheme eligibility. No Aadhaar/PAN/PPO/bank details are requested.
- Reusable semantic surface colours, typography, cards, branch buttons, tricolour ribbon, original silhouette and adaptive grids support iPhone/iPad and large text. Decorative artwork is hidden from VoiceOver; controls have labels/identifiers. Fixed navy hero/launch regions intentionally use light text. Native form surfaces follow system light/dark appearance.

## Build on MacBook Air M1

Install Xcode 15 or newer and its iOS simulator runtime. Use the existing checkout, not a new Git worktree.

```sh
git switch feat/ios-pro-design
cd DefencePensionCalculator
open DefencePensionCalculator.xcodeproj
xcodebuild -list -project DefencePensionCalculator.xcodeproj
xcodebuild -project DefencePensionCalculator.xcodeproj \
  -scheme DefencePensionCalculator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
xcrun simctl list devices available
# Substitute an available simulator UDID; do not assume a particular model is installed.
xcodebuild -project DefencePensionCalculator.xcodeproj \
  -scheme DefencePensionCalculator \
  -destination 'platform=iOS Simulator,id=SIMULATOR_UDID' \
  CODE_SIGNING_ALLOWED=NO test
```

The scheme includes both unit and UI test targets. Apple Silicon uses the native simulator architecture; Rosetta is not required by this dependency-free app. On a physical iPhone, select your own development team/bundle identifier and enable developer mode/signing as required by Xcode. No signed IPA is included. From the repository root, `swift test --jobs 4` runs the shared Foundation tests on macOS; the cloud helper `./scripts/test-core.sh` runs them with the retained Linux compiler.

## Changed-file groups

- App root, ContentView, HomeDashboardView, WelcomeView, AboutDeveloperView, SettingsView, ReferencesView, PensionSummaryView and PDFKit preview.
- `Presentation/DesignSystem/PensionDesignSystem.swift` for navy/gold styling and original vector components.
- `Domain/Models/AppNavigationModels.swift` and `ReportModels.swift` for testable routes, attribution/version selectors, report text and verified-reference filtering.
- View-model summary assembly for complete report snapshots; no financial service code changed.
- PDF exporter, launch storyboard/assets, privacy manifest, Xcode project/shared scheme and resource validation helper.
- Additional presentation/report unit tests, UI test source and release/validation documentation.

## Known limits

Linux cannot build SwiftUI/UIKit/PDFKit or run a simulator. iOS compilation and UI/PDF execution must be performed on the M1/Xcode machine before release; static parsing is not SDK type checking. Official data and production entitlement verification remain unavailable. The new unavailable calculators are transparent routes, not implementations of unverified legal rules. PDF text is selectable, but PDF/UA tagging and full PDF VoiceOver reading order have not been certified. Accessibility/dark-mode/iPad behavior require manual device/simulator review. Native premium payments are inactive; see the StoreKit plan in the release document.
