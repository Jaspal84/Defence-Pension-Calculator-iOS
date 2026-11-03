import SwiftUI
struct PensionSummaryView: View {
    @ObservedObject var model: PensionCalculatorViewModel
    @State private var showingPDF = false
    var body: some View {
        List {
            if let summary = model.summary {
                Section {
                    Label(summary.status.rawValue, systemImage: "doc.text.magnifyingglass").foregroundStyle(PensionTheme.tint)
                    Text(summary.title).font(.title2.bold())
                    Text("Calculated \(DateUtilities.text(summary.date)). Snapshot of the last successful calculation; recalculate after editing inputs.").font(.caption)
                }
                Section("Pension calculation breakdown") {
                    ForEach(summary.rows) { row in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(row.title).font(.caption).foregroundStyle(.secondary)
                            Text(row.value).font(.body.weight(.medium)).textSelection(.enabled)
                        }.padding(.vertical, 3)
                    }
                }
                Section("Rules & assumptions") {
                    Text(summary.rules.joined(separator: ", ")).font(.caption.monospaced())
                    ForEach(summary.assumptions, id: \.self) { Text($0).font(.footnote) }
                }
                Section("Source references") { ForEach(summary.sourceReferences, id: \.self) { Text($0).font(.footnote) } }
                Section("Share & keep your report") {
                    ShareLink(item: summary.text) { Label("Share calculation text", systemImage: "square.and.arrow.up") }.accessibilityIdentifier("report.shareText")
                    Button {
                        model.exportPDF(); showingPDF = model.pdfURL != nil
                    } label: { Label("Preview professional PDF", systemImage: "doc.richtext") }.accessibilityIdentifier("report.generatePDF")
                    if let url = model.pdfURL { ShareLink(item: url) { Label("Share PDF report", systemImage: "square.and.arrow.up") }.accessibilityIdentifier("report.sharePDF") }
                }
            } else {
                Section {
                    Label("Your pension report", systemImage: "doc.text").font(.headline)
                    Text("Calculate a supported estimate to see the full breakdown and create a report. No sample values are presented as your entitlement.").foregroundStyle(.secondary)
                }
            }
            Section {
                Text(AppBrand.reportDisclaimer).font(.footnote.weight(.semibold))
                Text(PensionNotice.disclaimer).font(.caption)
                Text("Developed by " + AppBrand.developer).font(.caption)
            }
        }.navigationTitle("Reports").accessibilityIdentifier("screen.reports")
        .sheet(isPresented: $showingPDF) {
            NavigationStack {
                if let url = model.pdfURL {
                    PensionPDFPreview(url: url).navigationTitle("Pension Report").navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showingPDF = false } } }
                }
            }
        }
    }
}
