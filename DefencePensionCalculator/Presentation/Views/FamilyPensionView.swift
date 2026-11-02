import SwiftUI
struct FamilyPensionView: View {
    @ObservedObject var model: PensionCalculatorViewModel
    var body: some View {
        Form {
            Section("Beneficiary and circumstances") {
                Picker("Category", selection: $model.family.category) { ForEach(FamilyPensionCategory.allCases) { Text($0.rawValue).tag($0) } }
                Picker("Relationship", selection: $model.family.relationship) { ForEach(BeneficiaryRelationship.allCases) { Text($0.rawValue.capitalized).tag($0) } }
                Toggle("Beneficiary eligibility confirmed", isOn: $model.family.beneficiaryEligible)
                DatePicker("Date of death", selection: $model.family.deathDate, displayedComponents: .date)
                DatePicker("Calculate as of", selection: $model.family.calculationDate, displayedComponents: .date)
                if model.family.category == .enhanced { DatePicker("Authorized enhanced end date", selection: $model.family.enhancedEndDate, displayedComponents: .date) }
                if model.family.category == .special { Toggle("Special circumstances confirmed", isOn: $model.family.specialCircumstancesConfirmed) }
                if model.family.category == .liberalized { Toggle("Liberalized circumstances confirmed", isOn: $model.family.liberalizedCircumstancesConfirmed) }
            }
            Section("Calculation") {
                CurrencyInputField(title: "Eligible emoluments", value: $model.family.emoluments)
                CurrencyInputField(title: "DR rate", value: $model.family.drPercent, suffix: "%")
                Picker("Regime", selection: $model.family.regime) { ForEach(PensionRuleRegime.allCases) { Text($0.rawValue).tag($0) } }
                Button("Calculate family pension", action: model.calculateFamily).buttonStyle(.borderedProminent)
            }
            if let r = model.familyResult {
                Section("Last calculated result") {
                    PensionResultCard(title: "Family pension including DR", amount: r.total)
                    LabeledContent("Family element", value: Money.format(r.basicPension))
                    LabeledContent("DR", value: Money.format(r.dr))
                    ForEach(r.assumptions, id: \.self) { Text($0).font(.caption) }
                }
            }
            EstimateNotice()
        }.navigationTitle("Family Pension").scrollDismissesKeyboard(.interactively)
    }
}
