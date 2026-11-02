import Foundation
struct CommutationEngine {
    let rules: any PensionRulesRepository
    let context: CommutationInput?
    init(rules: any PensionRulesRepository, context: CommutationInput? = nil) {
        self.rules = rules; self.context = context
    }
    func calculate(_ input: CommutationInput) throws -> CommutationResult {
        try rules.requireIllustrative(input.regime)
        try PensionInputValidator.amount(input.basicPension, "Basic pension")
        try PensionInputValidator.percent(input.drPercent, "DR rate")
        try PensionInputValidator.amount(input.percentage, "Commutation percentage", maximum: 50)
        guard input.pensionCategory == .service else { throw PensionError.ineligible("Only service pension commutation is supported in illustrative mode; family and disability components are excluded.") }
        guard (20...100).contains(input.ageNextBirthday) else { throw PensionError.invalid("Age next birthday must be between 20 and 100.") }
        guard input.commencementConfirmed, input.restorationCommencementDate >= input.effectiveDate else { throw PensionError.invalid("Confirm the legally applicable restoration commencement date; it must not precede the effective commutation date.") }
        let factor: Decimal
        if let supplied = input.illustrativeFactor {
            try PensionInputValidator.amount(supplied, "Illustrative factor", maximum: 20)
            guard supplied > 0 else { throw PensionError.invalid("Factor must be positive.") }
            factor = supplied
        } else { factor = try rules.commutationFactor(age: input.ageNextBirthday) }
        let portion = Money.round(input.basicPension * input.percentage / 100)
        let dr = Money.round(input.basicPension * input.drPercent / 100)
        guard let restoration = DateUtilities.calendar.date(byAdding: .year, value: 15, to: input.restorationCommencementDate) else { throw PensionError.invalid("Restoration date out of range.") }
        return CommutationResult(originalBasic: input.basicPension, commutedPortion: portion, lumpSum: Money.round(portion * 12 * factor), reducedBasic: input.basicPension - portion, dr: dr, netMonthly: input.basicPension - portion + dr, restorationDate: restoration, restoredMonthly: input.basicPension + dr, factor: factor, status: .illustrative, assumptions: ["Illustrative service pension limit of 50%; verify the applicable entitlement. Factor \(factor) must be independently verified.", "DR computed on original basic. Restoration assumed 15 years from the user-confirmed commencement date. Restored estimate uses unchanged pension and DR."], appliedRuleIDs: ["illustrative-v1"])
    }
    func calculateCommutation(basicPension: Double, ageNextBirthday: Int, percentage: Double) throws -> CommutationResult {
        guard var input = context else { throw PensionError.invalid("Supply a confirmed commencement date and factor through the engine context or calculate(_:).") }
        input.basicPension = try Money.decimal(basicPension); input.ageNextBirthday = ageNextBirthday
        input.percentage = try Money.decimal(percentage)
        return try calculate(input)
    }
}
