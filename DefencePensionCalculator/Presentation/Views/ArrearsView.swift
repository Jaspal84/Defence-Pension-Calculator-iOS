import SwiftUI
struct ArrearsView: View {
    @ObservedObject var model: PensionCalculatorViewModel
    var body: some View {
        Form {
            Section("Revision") {
                CurrencyInputField(title: "Previous monthly basic", value: $model.arrears.previous)
                CurrencyInputField(title: "Revised monthly basic", value: $model.arrears.revised)
                DatePicker("Effective date", selection: $model.arrears.start, displayedComponents: .date)
                DatePicker("Through date (inclusive)", selection: $model.arrears.end, displayedComponents: .date)
                CurrencyInputField(title: "Previously paid arrears", value: $model.arrears.previouslyPaid)
            }
            Section("DR rate schedule • user supplied") {
                ForEach($model.arrears.periods) { $period in
                    VStack(alignment: .leading) {
                        DatePicker("From", selection: $period.start, displayedComponents: .date)
                        CurrencyInputField(title: "DR rate", value: $period.rate, suffix: "%")
                    }
                }.onDelete { model.arrears.periods.remove(atOffsets: $0) }
                Button("Add DR change") { model.arrears.periods.append(DRPeriod(start: model.arrears.end, rate: 0)) }
                Text("Add a rate effective on or before the first arrears day, followed by each change date. Dates may split a month.").font(.caption)
            }
            Section { Button("Calculate arrears", action: model.calculateArrears).buttonStyle(.borderedProminent) }
            if let r = model.arrearsResult {
                Section("Last calculated result") {
                    PensionResultCard(title: "Net arrears / recovery", amount: r.total)
                    LabeledContent("Gross", value: Money.format(r.gross))
                    LabeledContent("Previously paid", value: Money.format(r.previouslyPaid))
                    ForEach(r.lines) { line in
                        VStack(alignment: .leading, spacing: 5) {
                            Text("\(DateUtilities.text(line.start)) – \(DateUtilities.text(line.end))").font(.subheadline.bold())
                            Text("\(line.days)/\(line.daysInMonth) days • DR \(line.drRate)%").font(.caption)
                            Text("Basic \(Money.format(line.basicDifference)) + DR \(Money.format(line.drDifference)) = \(Money.format(line.total))").font(.footnote).monospacedDigit()
                        }
                    }
                    ForEach(r.assumptions, id: \.self) { Text($0).font(.caption) }
                }
            }
            EstimateNotice()
        }.navigationTitle("Pension Arrears").scrollDismissesKeyboard(.interactively)
    }
}
