import SwiftUI
struct CommutationView: View {
    @ObservedObject var model: PensionCalculatorViewModel
    @State private var useFactor = false
    @State private var factor: Decimal = 0
    private var percent: Binding<Double> { Binding(get: { NSDecimalNumber(decimal: model.commutation.percentage).doubleValue }, set: { model.commutation.percentage = Decimal(string: String($0)) ?? 0 }) }
    var body: some View {
        Form {
            Section("Service pension commutation") {
                CurrencyInputField(title: "Original basic pension", value: $model.commutation.basicPension)
                Stepper("Age next birthday: \(model.commutation.ageNextBirthday)", value: $model.commutation.ageNextBirthday, in: 20...100)
                CurrencyInputField(title: "Commutation percentage", value: $model.commutation.percentage, suffix: "%")
                Slider(value: percent, in: 0...50, step: 1).accessibilityLabel("Commutation percentage")
                DatePicker("Effective commutation date", selection: $model.commutation.effectiveDate, displayedComponents: .date)
                DatePicker("Restoration commencement", selection: $model.commutation.restorationCommencementDate, displayedComponents: .date)
                Toggle("Commencement verified from applicable records", isOn: $model.commutation.commencementConfirmed)
                CurrencyInputField(title: "DR rate", value: $model.commutation.drPercent, suffix: "%")
            }
            Section("Factor source") {
                Text("Official age factors are unavailable. Supply a factor from your records for an illustrative estimate; no factor is assumed.").font(.footnote)
                Toggle("Use my illustrative factor", isOn: $useFactor)
                if useFactor { CurrencyInputField(title: "Factor from your records", value: $factor, suffix: "×") }
                Button("Calculate commutation") {
                    model.commutation.illustrativeFactor = useFactor ? factor : nil
                    model.calculateCommutation()
                }.buttonStyle(.borderedProminent)
            }
            if let r = model.commutationResult {
                Section("Last calculated result") {
                    PensionResultCard(title: "Commutation lump sum", amount: r.lumpSum)
                    LabeledContent("Before: basic + DR", value: Money.format(r.originalBasic + r.dr))
                    LabeledContent("Commuted portion", value: Money.format(r.commutedPortion))
                    LabeledContent("Reduced basic", value: Money.format(r.reducedBasic))
                    LabeledContent("DR on original basic", value: Money.format(r.dr))
                    LabeledContent("After: monthly payable", value: Money.format(r.netMonthly))
                    LabeledContent("Restoration date", value: DateUtilities.text(r.restorationDate))
                    LabeledContent("Restored monthly estimate", value: Money.format(r.restoredMonthly))
                    ForEach(r.assumptions, id: \.self) { Text($0).font(.caption) }
                }
            }
            EstimateNotice()
        }.navigationTitle("Commutation").scrollDismissesKeyboard(.interactively)
    }
}
