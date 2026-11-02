import SwiftUI
struct PensionResultCard: View {
    let title: String
    let amount: Decimal
    var status: CalculationStatus = .illustrative
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(status.rawValue, systemImage: status == .verified ? "checkmark.seal" : "info.circle")
                .font(.caption).foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(Money.format(amount)).font(.title2.bold()).monospacedDigit().foregroundStyle(Color.accentColor)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }
}
struct EstimateNotice: View {
    var body: some View {
        Section {
            Label("Illustrative assumptions", systemImage: "info.circle.fill").foregroundStyle(.orange)
            Text("Official rule tables could not be verified. Rates and eligibility assumptions in this version are illustrative. No official entitlement is calculated.").font(.footnote)
            Text(PensionNotice.disclaimer).font(.caption).foregroundStyle(.secondary)
        }
    }
}
