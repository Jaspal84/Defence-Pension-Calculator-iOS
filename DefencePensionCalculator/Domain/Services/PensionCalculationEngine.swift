import Foundation
struct PensionCalculationEngine {
    let rules: any PensionRulesRepository
    func calculateServicePension(input: PensionInput) throws -> PensionCalculationResult {
        try rules.requireIllustrative(input.regime)
        try PensionInputValidator.validate(input, ranks: rules.ranks)
        guard input.pensionType == .service || input.pensionType == .disability || input.pensionType == .warInjury else {
            throw PensionError.ineligible("Use the separate family pension engine.")
        }
        // These boundaries are declared synthetic assumptions, not verified law.
        let requiredYears = input.category == .officer ? 20 : 15
        guard input.serviceYears >= requiredYears else { throw PensionError.ineligible("Illustrative service assumption requires \(requiredYears) years. Special concessions and invalidment service elements need verified adjudication.") }
        let emoluments = input.basicPay + (input.includeMSP ? input.msp : 0) + input.classificationPay + input.otherPensionablePay
        let pension = max(Decimal(9000), Money.round(emoluments / 2))
        let dr = Money.round(pension * input.drPercent / 100)
        return PensionCalculationResult(input: input, eligibleEmoluments: emoluments, basicPension: pension, disabilityElement: 0, familyElement: 0, dr: dr, monthlyPayable: pension + dr, status: .illustrative, assumptions: [PensionNotice.illustrative, "50% of selected emoluments; assumed ₹9,000 minimum and \(requiredYears)-year service threshold. Half-up paise rounding. Alternative average-emolument bases and official revision not applied.", "MSP inclusion: \(input.includeMSP). Classification and other pay require explicit user confirmation. DR is user supplied."], appliedRuleIDs: ["illustrative-v1"])
    }
    func calculateDisabilityPension(input: PensionInput, disabilityPercent: Double) throws -> PensionCalculationResult {
        var d = DisabilityInput(); d.pension = input; d.percent = try Money.decimal(disabilityPercent)
        let result = try DisabilityPensionEngine(rules: rules).calculate(d)
        let service = try calculateServicePension(input: input)
        return PensionCalculationResult(input: input, eligibleEmoluments: service.eligibleEmoluments, basicPension: result.serviceElement, disabilityElement: result.disabilityElement, familyElement: 0, dr: result.dr, monthlyPayable: result.total, status: result.status, assumptions: result.assumptions, appliedRuleIDs: result.appliedRuleIDs)
    }
}
