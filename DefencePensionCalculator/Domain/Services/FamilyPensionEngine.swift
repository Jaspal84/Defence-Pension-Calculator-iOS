import Foundation
struct FamilyPensionEngine {
    let rules: any PensionRulesRepository
    func calculate(_ input: FamilyPensionInput) throws -> FamilyPensionResult {
        try rules.requireIllustrative(input.regime)
        try PensionInputValidator.amount(input.emoluments, "Emoluments")
        try PensionInputValidator.percent(input.drPercent, "DR rate")
        guard input.beneficiaryEligible else { throw PensionError.ineligible("Confirm beneficiary eligibility from sanctioning records.") }
        let cal = DateUtilities.calendar
        let asOf = cal.startOfDay(for: input.calculationDate)
        let death = cal.startOfDay(for: input.deathDate)
        let enhancedEnd = cal.startOfDay(for: input.enhancedEndDate)
        guard asOf >= death else { throw PensionError.invalid("Calculation date precedes death.") }
        let rate: Decimal
        switch input.category {
        case .ordinary: rate = 30
        case .enhanced:
            guard enhancedEnd >= death, asOf <= enhancedEnd else { throw PensionError.ineligible("Enhanced period has ended or is invalid; select ordinary pension.") }
            rate = 50
        case .special:
            guard input.specialCircumstancesConfirmed else { throw PensionError.ineligible("Special family pension circumstances must be confirmed.") }
            rate = 60
        case .liberalized:
            guard input.liberalizedCircumstancesConfirmed else { throw PensionError.ineligible("Liberalized family pension circumstances must be confirmed.") }
            rate = 100
        }
        let basic = Money.round(input.emoluments * rate / 100)
        let dr = Money.round(basic * input.drPercent / 100)
        return FamilyPensionResult(category: input.category, basicPension: basic, dr: dr, total: basic + dr, status: .illustrative, assumptions: [PensionNotice.illustrative, "Assumed rate \(rate)%. Beneficiary eligibility and enhanced end date are user-confirmed, not adjudicated. No automatic duration, minimum, cap or apportionment rules applied."], appliedRuleIDs: ["illustrative-v1"])
    }
}
