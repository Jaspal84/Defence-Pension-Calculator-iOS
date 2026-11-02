import SwiftUI
struct DisabilityPensionView: View {
    @ObservedObject var model: PensionCalculatorViewModel
    var body: some View {
        Form {
            Section { Text("Uses the branch, rank, qualifying service, pay and DR entered in Calculator. Invalidment concessions are not verified; the illustrative service threshold still applies.").font(.footnote) }
            Section("Assessment") {
                Picker("Entitlement", selection: $model.disability.entitlement) { ForEach(DisabilityEntitlementCategory.allCases) { Text($0.rawValue.capitalized).tag($0) } }
                Picker("Separation", selection: $model.disability.separation) { ForEach(SeparationType.allCases) { Text($0.rawValue.capitalized).tag($0) } }
                CurrencyInputField(title: "Assessed disability", value: $model.disability.percent, suffix: "%")
                Toggle("Assume broad-banding authorized", isOn: $model.disability.broadBandingAuthorized)
                Toggle("War injury calculation", isOn: $model.disability.warInjury)
                if model.disability.warInjury { Toggle("Qualifying war injury confirmed", isOn: $model.disability.injuryCategoryConfirmed) }
            }
            Section { Button("Calculate elements", action: model.calculateDisability).buttonStyle(.borderedProminent) }
            if let r = model.disabilityResult {
                Section("Last calculated result") {
                    PensionResultCard(title: "Total monthly estimate", amount: r.total)
                    LabeledContent("Service element", value: Money.format(r.serviceElement))
                    LabeledContent("Disability / war injury element", value: Money.format(r.disabilityElement))
                    LabeledContent("Applied disability", value: "\(r.appliedPercent)%")
                    LabeledContent("DR", value: Money.format(r.dr))
                    ForEach(r.assumptions, id: \.self) { Text($0).font(.caption) }
                }
            }
            EstimateNotice()
        }.navigationTitle("Disability & War Injury").scrollDismissesKeyboard(.interactively)
    }
}
