import SwiftUI
struct SettingsView: View {
    @ObservedObject var model: PensionCalculatorViewModel
    var body: some View {
        List {
            Section("Privacy") { Text("Calculations work offline. No account, analytics, identifiers or network requests. Only your preferred service branch is stored on this device. Calculation inputs and results are retained for this session only. Shared files contain the details shown in Summary.") }
            Section("Reference data") {
                Text("Version 1.0.0-incomplete. Official pay matrix, OROP and commutation tables are not bundled. No current DR rate is assumed.")
                ForEach(model.repository?.metadata ?? []) { m in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(m.sourceTitle).font(.headline)
                        Text(m.issuingAuthority)
                        Text("Version: \(m.dataVersion) • \(m.verified ? "Verified" : "Unverified")").font(.caption)
                        Text(m.applicability).font(.footnote)
                        if let url = m.sourceURL, let link = URL(string: url) { Link("Source", destination: link) }
                    }
                }
            }
            Section("Accessibility") { Text("Supports system light and dark appearance, Dynamic Type, VoiceOver labels and Indian currency formatting.") }
            Section { Text(PensionNotice.disclaimer).font(.caption) }
        }.navigationTitle("Settings & Rules")
    }
}
