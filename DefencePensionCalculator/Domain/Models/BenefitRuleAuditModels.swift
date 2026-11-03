import Foundation

// This is research provenance, not executable benefit policy. It cannot confer eligibility or activate a calculator.
struct BenefitRuleAuditCatalog: Codable, Sendable {
    let schemaVersion: Int
    let dataVersion: String
    let purpose: String
    let auditedAtUTC: String
    let enabledRuleIDs: [String]
    let sources: [BenefitSourceAudit]
    let benefits: [BenefitVerificationItem]
}
struct BenefitSourceAudit: Codable, Identifiable, Sendable {
    let id: String
    let requestedLabel: String
    let sourceURL: String
    let verificationStatus: String
    let sourceTitle: String?
    let issuingAuthority: String?
    let documentNumber: String?
    let publicationDate: String?
    let effectiveDate: String?
    let ruleNumber: String?
    let contentSHA256: String?
    let sourceBodyInspected: Bool
    let attemptedAtUTC: String
    let proxyHTTPStatus: Int?
    let originHTTPStatus: Int?
    let curlExitCode: Int
}
struct BenefitVerificationItem: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let decision: String
    let sourceIDs: [String]
    let applicabilityPending: String
    let verificationRequired: String
}
