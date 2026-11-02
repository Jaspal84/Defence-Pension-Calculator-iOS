import SwiftUI
struct OROPComparisonView: View {
    @ObservedObject var model: PensionCalculatorViewModel
    @State private var existing: Decimal = 0
    var body: some View {
        Form {
            Section("Exact table selection") {
                Picker("Branch", selection: $model.orop.branch) { ForEach(ArmedForceBranch.allCases) { Text($0.rawValue).tag($0) } }
                    .onChange(of: model.orop.branch) { _ in model.orop.rankID = model.repository?.ranks.first(where: { $0.branch == model.orop.branch })?.id ?? "" }
                Picker("Rank", selection: $model.orop.rankID) {
                    ForEach(model.repository?.ranks.filter { $0.branch == model.orop.branch } ?? []) { Text($0.name).tag($0.id) }
                }
                Stepper("Qualifying service: \(model.orop.serviceHalfYears / 2) years \(model.orop.serviceHalfYears % 2 == 1 ? "6 months" : "")", value: $model.orop.serviceHalfYears, in: 0...120)
                TextField("Retirement cohort", text: $model.orop.cohort)
                Picker("Pension category", selection: $model.orop.category) { ForEach(PensionType.allCases) { Text($0.rawValue.capitalized).tag($0) } }
                TextField("Revision date (YYYY-MM-DD)", text: $model.orop.revisionDate)
                CurrencyInputField(title: "Existing basic for comparison", value: $existing)
                Button("Look up official table", action: model.lookupOROP).buttonStyle(.borderedProminent)
            }
            Section("Data availability") {
                Label("Official OROP table data unavailable for this selection.", systemImage: "doc.badge.ellipsis")
                Text("No generated or estimated OROP entries are included. Exact versioned official tables are required before comparison.").font(.footnote).foregroundStyle(.secondary)
            }
            if let r = model.oropResult {
                Section("Official table match") {
                    PensionResultCard(title: "Table pension", amount: r.pension, status: .verified)
                    LabeledContent("Difference", value: Money.format(r.pension - existing))
                }
            }
            Section { Text(PensionNotice.disclaimer).font(.caption) }
        }.navigationTitle("OROP Comparison").scrollDismissesKeyboard(.interactively)
    }
}
