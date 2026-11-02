import Foundation
enum FamilyPensionCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case ordinary = "Ordinary", enhanced = "Enhanced Ordinary", special = "Special", liberalized = "Liberalized"
    var id: String { rawValue }
}
enum BeneficiaryRelationship: String, Codable, CaseIterable, Identifiable, Sendable {
    case spouse, child, parent
    var id: String { rawValue }
}
struct FamilyPensionInput: Sendable {
    var category: FamilyPensionCategory = .ordinary
    var relationship: BeneficiaryRelationship = .spouse
    var emoluments: Decimal = 40000
    var drPercent: Decimal = 0
    var deathDate = DateUtilities.date(2024, 1, 1)
    var calculationDate = Date()
    var enhancedEndDate = DateUtilities.date(2031, 1, 1)
    var beneficiaryEligible = false
    var specialCircumstancesConfirmed = false
    var liberalizedCircumstancesConfirmed = false
    var regime: PensionRuleRegime = .illustrative
}
struct FamilyPensionResult: Codable, Sendable {
    let category: FamilyPensionCategory
    let basicPension: Decimal
    let dr: Decimal
    let total: Decimal
    let status: CalculationStatus
    let assumptions: [String]
    let appliedRuleIDs: [String]
}
