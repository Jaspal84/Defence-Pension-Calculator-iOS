import SwiftUI
struct SettingsView: View {
    @ObservedObject var model: PensionCalculatorViewModel
    @AppStorage("showWelcomeOnLaunch") private var showWelcome = true
    var body: some View {
        List {
            Section("Application") {
                NavigationLink { AboutDeveloperView() } label: { Label("About Developer", systemImage: "person.crop.circle") }
                    .accessibilityIdentifier("settings.aboutDeveloper")
                LabeledContent("Version", value: AppBrand.version())
                Toggle("Show welcome on launch", isOn: $showWelcome).accessibilityIdentifier("settings.welcome")
            }
            Section("Privacy") {
                Text("Calculations work offline. No account, analytics, identifiers or network requests. Only your preferred service branch and welcome-screen preference are stored on this device. Calculation inputs and results remain session-only. Shared files contain the details shown in Reports.")
            }
            Section("Rules & reference data") {
                NavigationLink { ReferencesView(model: model) } label: { Label("Reference versions & availability", systemImage: "book.closed") }
                Text("No current DR rate is assumed. Unsupported benefit schemes remain unavailable until their rules are verified.").font(.footnote)
            }
            Section("Accessibility") { Text("Uses system text sizes, semantic surfaces, VoiceOver labels and an adaptive iPad layout. Original illustrations are decorative and hidden from VoiceOver.") }
            Section("Optional premium reports") { Text("PDF export remains available in this version. No purchases are active. Any future paid digital reports require a reviewed StoreKit 2 implementation and App Store configuration; personal UPI QR codes are not a substitute.").font(.footnote) }
            Section { Text(PensionNotice.disclaimer).font(.caption); Text(AppBrand.independence).font(.caption) }
        }.navigationTitle("Settings").accessibilityIdentifier("screen.settings")
    }
}
