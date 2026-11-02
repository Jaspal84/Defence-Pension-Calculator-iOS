import Foundation
struct DRPeriod: Codable, Identifiable, Sendable {
    var id = UUID()
    var start: Date
    var rate: Decimal
}
struct ArrearsInput: Sendable {
    var previous: Decimal = 20000
    var revised: Decimal = 22600
    var start = DateUtilities.date(2024, 1, 1)
    var end = DateUtilities.date(2024, 12, 31)
    var periods = [DRPeriod(start: DateUtilities.date(2024, 1, 1), rate: 0)]
    var previouslyPaid: Decimal = 0
}
struct ArrearsLine: Codable, Identifiable, Sendable {
    var id = UUID()
    let start: Date
    let end: Date
    let days: Int
    let daysInMonth: Int
    let drRate: Decimal
    let basicDifference: Decimal
    let drDifference: Decimal
    var total: Decimal { basicDifference + drDifference }
}
struct ArrearsCalculationResult: Codable, Sendable {
    let lines: [ArrearsLine]
    let gross: Decimal
    let previouslyPaid: Decimal
    let total: Decimal
    let status: CalculationStatus
    let assumptions: [String]
}
struct OROPSelection: Codable, Equatable, Sendable {
    var branch: ArmedForceBranch = .army
    var rankID = "army-sepoy"
    var serviceHalfYears = 40
    var cohort = "Pre-2016"
    var category: PensionType = .service
    var revisionDate = "2024-07-01"
}
struct OROPEntry: Codable, Sendable {
    let selection: OROPSelection
    let pension: Decimal
    let ruleID: String
}
