import SwiftUI
struct ReferencesView: View {
    @ObservedObject var model: PensionCalculatorViewModel
    var body: some View {
        List {
            Section("Current data status") {
                Label("Official tables unavailable", systemImage: "doc.badge.ellipsis")
                Text("The OROP, 7th CPC pay matrix and official commutation factor datasets are incomplete. No government circulars or table entries have been invented.").font(.footnote)
            }
            Section("Applied reference model") {
                ForEach(model.repository?.metadata ?? []) { metadata in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(metadata.sourceTitle).font(.headline)
                        Text(metadata.issuingAuthority).font(.subheadline)
                        Text("Version \(metadata.dataVersion) • \(metadata.verified ? "Verified" : "Unverified")").font(.caption)
                        Text(metadata.applicability).font(.footnote).foregroundStyle(.secondary)
                        if metadata.verified {
                            if let order = metadata.orderNumber { Text("Order: " + order).font(.caption) }
                            if let effective = metadata.effectiveDate { Text("Effective: " + effective).font(.caption) }
                            if let value = metadata.sourceURL, let url = URL(string: value), url.scheme == "https" { Link("Read official source", destination: url) }
                        }
                    }.padding(.vertical, 5)
                }
            }
            if let error = model.startupError { Section("Resource error") { Text(error).foregroundStyle(.red) } }
            Section { Text(PensionNotice.disclaimer).font(.caption); Text(AppBrand.independence).font(.caption) }
        }.navigationTitle("References").accessibilityIdentifier("screen.references")
    }
}
