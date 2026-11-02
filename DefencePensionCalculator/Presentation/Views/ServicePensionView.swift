import SwiftUI
struct ServicePensionView: View {
    @ObservedObject var model: PensionCalculatorViewModel
    var body: some View {
        Form {
            Section {
                Label("DEFENCE PENSION", systemImage: "shield.fill").font(.caption.bold()).foregroundStyle(.orange)
                Text("Plan with clarity").font(.title2.bold())
                Text("Offline pension estimates for the armed forces community.").foregroundStyle(.secondary)
            }
            if let error = model.startupError { Section("Resource error") { Text(error).foregroundStyle(.red) } }
            Section("Service details") {
                Picker("Branch", selection: $model.input.branch) { ForEach(ArmedForceBranch.allCases) { Text($0.rawValue).tag($0) } }
                    .onChange(of: model.input.branch) { _ in model.normalizeRank() }
                Picker("Personnel category", selection: $model.input.category) { ForEach(RankCategory.allCases) { Text($0.rawValue).tag($0) } }
                    .onChange(of: model.input.category) { _ in model.normalizeRank() }
                RankSelectionPicker(model: model)
                DatePicker("Date of birth", selection: $model.input.birthDate, displayedComponents: .date)
                DatePicker("Retirement date", selection: $model.input.retirementDate, displayedComponents: .date)
                Stepper("Service: \(model.input.serviceYears) years", value: $model.input.serviceYears, in: 0...60)
                Picker("Completed six-month periods", selection: $model.input.completedHalfYears) { Text("0").tag(0); Text("1").tag(1) }
            }
            Section("Pensionable pay") {
                CurrencyInputField(title: "Basic pay", value: $model.input.basicPay)
                CurrencyInputField(title: "Military Service Pay", value: $model.input.msp)
                Toggle("Assume MSP is pensionable", isOn: $model.input.includeMSP)
                CurrencyInputField(title: "Classification / Group X pay", value: $model.input.classificationPay)
                Toggle("Confirm classification pay inclusion", isOn: $model.input.classificationEligible)
                CurrencyInputField(title: "Other pensionable emoluments", value: $model.input.otherPensionablePay)
                Toggle("Confirm other pay inclusion", isOn: $model.input.otherPayAuthorized)
                CurrencyInputField(title: "User-supplied DR rate", value: $model.input.drPercent, suffix: "%")
            }
            Section("Rule selection") {
                Picker("Regime", selection: $model.input.regime) { ForEach(PensionRuleRegime.allCases) { Text($0.rawValue).tag($0) } }
                Text("Verified regimes remain unavailable until authenticated rule data is bundled.").font(.caption).foregroundStyle(.secondary)
            }
            Section { Button("Calculate service pension", action: model.calculateService).buttonStyle(.borderedProminent) }
            if let r = model.serviceResult {
                Section("Last calculated result • recalculate after edits") {
                    PensionResultCard(title: "Monthly pension including DR", amount: r.monthlyPayable)
                    LabeledContent("Eligible emoluments", value: Money.format(r.eligibleEmoluments))
                    LabeledContent("Basic pension", value: Money.format(r.basicPension))
                    LabeledContent("Dearness Relief", value: Money.format(r.dr))
                    ForEach(r.assumptions, id: \.self) { Text($0).font(.caption) }
                }
            }
            EstimateNotice()
        }.navigationTitle("Pension Calculator").navigationBarTitleDisplayMode(.inline)
        .toolbar { NavigationLink { SettingsView(model: model) } label: { Image(systemName: "gearshape") }.accessibilityLabel("Settings and rule data") }
        .scrollDismissesKeyboard(.interactively)
    }
}
