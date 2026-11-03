import SwiftUI
struct AboutDeveloperView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Image(systemName: "person.crop.circle.fill").font(.system(size: 90, weight: .light)).foregroundStyle(PensionTheme.tint)
                    .padding(18).background(PensionTheme.gold.opacity(0.25), in: Circle()).accessibilityHidden(true)
                VStack(spacing: 10) {
                    Text(AppBrand.developer).font(.largeTitle.bold()).accessibilityIdentifier("about.name")
                    Text("Creator & Developer").font(.headline).padding(.horizontal, 22).padding(.vertical, 8)
                        .background(PensionTheme.gold.opacity(0.25), in: Capsule())
                    Text(AppBrand.name).font(.title3.bold()).multilineTextAlignment(.center)
                }
                Text(AppBrand.developerDescription).font(.body).frame(maxWidth: .infinity, alignment: .leading)
                ProCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Label(AppBrand.version(), systemImage: "info.circle").accessibilityIdentifier("about.version")
                        if let contact = AppBrand.contact() { Link(destination: contact) { Label("Contact developer", systemImage: "envelope") }.accessibilityIdentifier("about.contact") }
                        if let website = AppBrand.website() { Link(destination: website) { Label("Developer website", systemImage: "globe") }.accessibilityIdentifier("about.website") }
                    }
                }
                ProCard { Label(AppBrand.independence, systemImage: "info.circle").font(.footnote).accessibilityIdentifier("about.disclaimer") }
                Text(AppBrand.copyright).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }.padding(24).frame(maxWidth: 700).frame(maxWidth: .infinity)
        }.background(PensionTheme.background).navigationTitle("About Developer").navigationBarTitleDisplayMode(.inline)
            .proNavigationBar().accessibilityIdentifier("screen.aboutDeveloper")
    }
}
