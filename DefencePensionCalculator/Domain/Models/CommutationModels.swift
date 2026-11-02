import Foundation
struct CommutationTableLookup: Codable, Sendable {
    let ageNextBirthday: Int
    let factor: Decimal
}
struct CommutationInput: Sendable {
    var basicPension: Decimal = 22600
    var ageNextBirthday = 61
    var percentage: Decimal = 40
    var effectiveDate = Date()
    var restorationCommencementDate = Date()
    var commencementConfirmed = false
    var drPercent: Decimal = 0
    var pensionCategory: PensionType = .service
    var regime: PensionRuleRegime = .illustrative
    // Explicit user-supplied factor is never described as official.
    var illustrativeFactor: Decimal? = nil
}
struct CommutationResult: Codable, Sendable {
    let originalBasic: Decimal
    let commutedPortion: Decimal
    let lumpSum: Decimal
    let reducedBasic: Decimal
    let dr: Decimal
    let netMonthly: Decimal
    let restorationDate: Date
    let restoredMonthly: Decimal
    let factor: Decimal
    let status: CalculationStatus
    let assumptions: [String]
    let appliedRuleIDs: [String]
}
