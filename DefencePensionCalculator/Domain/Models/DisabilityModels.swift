import Foundation
enum DisabilityEntitlementCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case attributable, aggravated, neither
    var id: String { rawValue }
}
enum SeparationType: String, Codable, CaseIterable, Identifiable, Sendable {
    case invalidment, retirement
    var id: String { rawValue }
}
struct DisabilityInput: Sendable {
    var pension = PensionInput()
    var entitlement: DisabilityEntitlementCategory = .attributable
    var separation: SeparationType = .retirement
    var percent: Decimal = 50
    var broadBandingAuthorized = false
    var warInjury = false
    var injuryCategoryConfirmed = false
}
struct DisabilityPensionResult: Codable, Sendable {
    let serviceElement: Decimal
    let disabilityElement: Decimal
    let assessedPercent: Decimal
    let appliedPercent: Decimal
    let dr: Decimal
    let total: Decimal
    let status: CalculationStatus
    let assumptions: [String]
    let appliedRuleIDs: [String]
}
