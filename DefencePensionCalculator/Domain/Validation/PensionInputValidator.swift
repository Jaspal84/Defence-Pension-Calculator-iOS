import Foundation
enum PensionInputValidator {
    static func amount(_ value: Decimal, _ label: String, maximum: Decimal = 1000000000) throws {
        guard !value.isNaN, value >= 0, value <= maximum else {
            throw PensionError.invalid("\(label) must be between 0 and \(maximum).")
        }
    }
    static func percent(_ value: Decimal, _ label: String) throws { try amount(value, label, maximum: 100) }
    static func validate(_ input: PensionInput, ranks: [Rank]) throws {
        for (value, label) in [(input.basicPay, "Basic pay"), (input.msp, "MSP"), (input.classificationPay, "Classification pay"), (input.otherPensionablePay, "Other pay")] {
            try amount(value, label)
        }
        try percent(input.drPercent, "DR rate")
        guard (0...60).contains(input.serviceYears), (0...1).contains(input.completedHalfYears) else {
            throw PensionError.invalid("Service must be 0–60 years with 0 or 1 completed six-month period.")
        }
        guard input.retirementDate >= input.birthDate else { throw PensionError.invalid("Retirement precedes birth.") }
        let age = DateUtilities.calendar.dateComponents([.year], from: input.birthDate, to: input.retirementDate).year ?? 0
        guard (18...100).contains(age), input.serviceYears <= age - 15 else { throw PensionError.invalid("Dates and qualifying service are inconsistent.") }
        guard ranks.contains(where: { $0.id == input.rankID && $0.branch == input.branch && $0.category == input.category }) else {
            throw PensionError.invalid("Select a rank matching the branch and personnel category.")
        }
        guard input.classificationPay == 0 || input.classificationEligible else { throw PensionError.ineligible("Confirm classification pay inclusion or set it to zero.") }
        guard input.otherPensionablePay == 0 || input.otherPayAuthorized else { throw PensionError.ineligible("Confirm other pay inclusion or set it to zero.") }
    }
}
