import Foundation

struct BenefitRuleAuditRepository {
    let catalog: BenefitRuleAuditCatalog
    init(local: LocalJSONRepository = LocalJSONRepository()) throws {
        let decoded = try local.load("BenefitRuleAudit", as: BenefitRuleAuditCatalog.self)
        let requestIDs = Set(decoded.sources.map(\.id))
        let documentIDs = Set(decoded.documents.map(\.id))
        let validURL: (String) -> Bool = { value in
            guard let url = URL(string: value) else { return false }
            return url.scheme == "https" && url.host != nil && url.user == nil && url.password == nil
        }
        let validHash: (String) -> Bool = { value in
            value.count == 64 && value.allSatisfy { $0.isHexDigit && !$0.isUppercase }
        }
        let allowedInspectionStatuses: Set<String> = ["contentInspected", "partialContentInspection", "hashMatchedOnly"]
        guard decoded.schemaVersion == 2, !decoded.dataVersion.isEmpty,
              decoded.enabledRuleIDs.isEmpty,
              requestIDs.count == decoded.sources.count,
              documentIDs.count == decoded.documents.count,
              Set(decoded.benefits.map(\.id)).count == decoded.benefits.count,
              decoded.benefits.allSatisfy({ $0.decision == "disabled" && !$0.sourceIDs.isEmpty && Set($0.sourceIDs).isSubset(of: documentIDs) }),
              decoded.sources.allSatisfy({ validURL($0.sourceURL) }),
              decoded.documents.allSatisfy({
                  validURL($0.sourceURL) && validHash($0.contentSHA256) &&
                  $0.localPath.hasPrefix("docs/rules/source-documents/") && !$0.localPath.contains("..") &&
                  allowedInspectionStatuses.contains($0.inspectionStatus) &&
                  ($0.inspectionStatus == "hashMatchedOnly" ? !$0.sourceBodyInspected : $0.sourceBodyInspected)
              }) else {
            throw PensionError.missingData("Invalid benefit research audit. No benefit calculator can be activated from this audit-only schema.")
        }
        catalog = decoded
    }
    func documents(for item: BenefitVerificationItem) -> [BenefitDocumentAudit] {
        catalog.documents.filter { item.sourceIDs.contains($0.id) }
    }

    /// Schema 2 is an evidence inventory, not an executable rule registry.
    /// It deliberately cannot authorize a gratuity PDF, even if a caller fabricates
    /// result metadata or changes a benefit decision without adding approved rules.
    func authorizesGratuityPDF(
        benefitID: String,
        appliedRuleIDs: [String],
        eventDate: Date
    ) -> Bool {
        guard !appliedRuleIDs.isEmpty,
              Set(appliedRuleIDs).count == appliedRuleIDs.count,
              catalog.enabledRuleIDs.count == appliedRuleIDs.count,
              Set(appliedRuleIDs) == Set(catalog.enabledRuleIDs),
              let benefit = catalog.benefits.first(where: { $0.id == benefitID }),
              benefit.decision == "enabled" else {
            return false
        }

        // The current audit schema has no per-rule approval, applicability,
        // effective-period, or verified operative-text records to validate.
        // Therefore no gratuity result can be authorized under schema 2.
        _ = eventDate
        return false
    }
}
