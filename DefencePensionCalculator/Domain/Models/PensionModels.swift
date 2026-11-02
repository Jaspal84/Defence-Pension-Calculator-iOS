import Foundation

enum ArmedForceBranch: String, Codable, CaseIterable, Identifiable, Sendable {
    case army = "Army", navy = "Navy", airForce = "Air Force"
    var id: String { rawValue }
}
enum RankCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case officer = "Commissioned Officer", jco = "JCO / equivalent", otherRank = "Other Rank"
    var id: String { rawValue }
}
enum PensionType: String, Codable, CaseIterable, Identifiable, Sendable {
    case service, disability, warInjury, family
    var id: String { rawValue }
}
enum PensionRuleRegime: String, Codable, CaseIterable, Identifiable, Sendable {
    case illustrative = "Illustrative assumptions", seventhCPC = "7th CPC (verification required)", orop = "OROP (official table required)"
    var id: String { rawValue }
}
enum CalculationStatus: String, Codable, Sendable {
    case verified = "Verified rule-based result", illustrative = "Illustrative estimate", unavailable = "Calculation unavailable"
}
enum PensionError: Error, LocalizedError, Equatable {
    case invalid(String), unsupported(String), missingData(String), ineligible(String)
    var errorDescription: String? {
        switch self { case .invalid(let s), .unsupported(let s), .missingData(let s), .ineligible(let s): return s }
    }
}
struct PensionInput: Codable, Sendable, Equatable {
    var branch: ArmedForceBranch = .army
    var category: RankCategory = .otherRank
    var rankID = "army-sepoy"
    var retirementDate = DateUtilities.date(2024, 1, 1)
    var birthDate = DateUtilities.date(1964, 1, 1)
    var serviceYears = 20
    var completedHalfYears = 0
    var basicPay: Decimal = 40000
    var msp: Decimal = 5200
    var classificationPay: Decimal = 0
    var otherPensionablePay: Decimal = 0
    var includeMSP = true
    var classificationEligible = false
    var otherPayAuthorized = false
    var drPercent: Decimal = 0
    var regime: PensionRuleRegime = .illustrative
    var pensionType: PensionType = .service
}
struct PensionCalculationResult: Codable, Identifiable, Sendable {
    var id = UUID()
    let input: PensionInput
    let eligibleEmoluments: Decimal
    let basicPension: Decimal
    let disabilityElement: Decimal
    let familyElement: Decimal
    let dr: Decimal
    let monthlyPayable: Decimal
    let status: CalculationStatus
    let assumptions: [String]
    let appliedRuleIDs: [String]
    var validationErrors: [String] = []
}
struct PensionRuleMetadata: Codable, Identifiable, Sendable {
    let id: String
    let sourceTitle: String
    let issuingAuthority: String
    let orderNumber: String?
    let effectiveDate: String?
    let publicationDate: String?
    let sourceURL: String?
    let applicability: String
    let dataVersion: String
    let verified: Bool
}
enum PensionNotice {
    static let disclaimer = "This calculator provides estimates based on selected pension rules and reference data. Final pension entitlement and payment are determined by the competent pension sanctioning authority and official PPO/SPARSH records."
    static let illustrative = "Synthetic reference assumptions only: no official entitlement is established. Minimum pension, service eligibility, pay inclusion and rates require official verification."
}
