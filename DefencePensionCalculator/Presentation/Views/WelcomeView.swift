import SwiftUI
struct WelcomeView: View {
    let onContinue: () -> Void
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    TricolourRibbon().padding(.top, 12)
                    Image(systemName: "shield.lefthalf.filled").font(.system(size: 48, weight: .light)).foregroundStyle(PensionTheme.gold).accessibilityHidden(true)
                    Text(AppBrand.name).font(.system(.largeTitle, design: .serif).bold()).multilineTextAlignment(.center).accessibilityAddTraits(.isHeader)
                    Text(AppBrand.subtitle).font(.subheadline).multilineTextAlignment(.center).foregroundStyle(Color.white.opacity(0.9))
                    DefenceHorizonIllustration().frame(height: min(230, geometry.size.height * 0.3))
                    VStack(spacing: 3) {
                        Text("Developed by").font(.subheadline)
                        Text(AppBrand.developer).font(.title.bold()).foregroundStyle(PensionTheme.gold)
                    }.accessibilityElement(children: .combine).accessibilityIdentifier("welcome.developer")
                    Button(action: onContinue) { Text("Explore calculators").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 9) }
                        .buttonStyle(.borderedProminent).tint(PensionTheme.gold).foregroundStyle(PensionTheme.navy)
                        .accessibilityIdentifier("welcome.continue")
                    Text(AppBrand.version()).font(.caption).accessibilityIdentifier("welcome.version")
                    Text(AppBrand.independence).font(.caption2).multilineTextAlignment(.center).foregroundStyle(Color.white.opacity(0.85))
                }.padding(28).frame(maxWidth: 640).frame(maxWidth: .infinity).frame(minHeight: geometry.size.height)
            }.background(LinearGradient(colors: [PensionTheme.navy, PensionTheme.royal, PensionTheme.navy], startPoint: .topLeading, endPoint: .bottomTrailing)).foregroundStyle(.white)
        }.accessibilityIdentifier("screen.welcome")
    }
}
