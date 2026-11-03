import Foundation
struct SummaryRow: Codable, Identifiable, Sendable {
    var id: String { title }
    let title: String
    let value: String
}
struct CalculationSummary: Codable, Sendable {
    let title: String
    let date: Date
    let status: CalculationStatus
    let rows: [SummaryRow]
    let assumptions: [String]
    let rules: [String]
    // Metadata is included only when the repository actually carries the applied identifier.
    var ruleMetadata: [PensionRuleMetadata] = []
    var text: String {
        var sections = [AppBrand.name, "Pension Calculation Report", "Developed by " + AppBrand.developer,
                        title, DateUtilities.text(date), status.rawValue]
        sections.append(contentsOf: rows.map { "\($0.title): \($0.value)" })
        sections.append("Applied rule identifiers: " + rules.joined(separator: ", "))
        sections.append(contentsOf: assumptions)
        sections.append(contentsOf: [AppBrand.reportDisclaimer, PensionNotice.disclaimer, AppBrand.independence])
        return sections.joined(separator: "\n\n")
    }
    var sourceReferences: [String] {
        let verified = ruleMetadata.filter { $0.verified && rules.contains($0.id) }
        guard !verified.isEmpty else { return ["No verified official source references or effective dates are available for this calculation."] }
        return verified.map { metadata in
            [metadata.sourceTitle, metadata.issuingAuthority, metadata.orderNumber.map { "Order: " + $0 },
             metadata.effectiveDate.map { "Effective: " + $0 }, metadata.publicationDate.map { "Published: " + $0 }, metadata.sourceURL,
             "Applicability: " + metadata.applicability, "Data version: " + metadata.dataVersion].compactMap { $0 }.joined(separator: " • ")
        }
    }
}
