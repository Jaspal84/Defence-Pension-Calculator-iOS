import SwiftUI
struct PensionSummaryView: View {
    @ObservedObject var model: PensionCalculatorViewModel
    var body: some View {
        List {
            if let summary = model.summary {
                Section {
                    Label(summary.status.rawValue, systemImage: "doc.text.magnifyingglass").foregroundStyle(.orange)
                    Text(summary.title).font(.title2.bold())
                    Text("Calculated \(DateUtilities.text(summary.date)). Snapshot of the last successful calculation; recalculate after editing inputs.").font(.caption)
                }
                Section("Breakdown") {
                    ForEach(summary.rows) { row in
                        VStack(alignment: .leading, spacing: 4) { Text(row.title).font(.caption).foregroundStyle(.secondary); Text(row.value).textSelection(.enabled) }
                    }
                }
                Section("Rules & assumptions") {
                    Text(summary.rules.joined(separator: ", ")).font(.caption.monospaced())
                    ForEach(summary.assumptions, id: \.self) { Text($0).font(.footnote) }
                }
                Section("Share offline") {
                    ShareLink(item: summary.text) { Label("Share calculation text", systemImage: "square.and.arrow.up") }
                    Button("Generate PDF", action: model.exportPDF)
                    if let url = model.pdfURL { ShareLink(item: url) { Label("Share PDF", systemImage: "doc.richtext") } }
                }
            } else {
                Section {
                    Label("Your calculation summary", systemImage: "doc.text")
                    Text("Calculate a pension, family, disability, commutation or arrears result to see its full breakdown and export a PDF.").foregroundStyle(.secondary)
                }
            }
            Section { Text(PensionNotice.disclaimer).font(.caption) }
        }.navigationTitle("Summary")
    }
}
