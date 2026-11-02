import Foundation
struct DisabilityPensionEngine {
    let rules: any PensionRulesRepository
    func calculate(_ input: DisabilityInput) throws -> DisabilityPensionResult {
        try rules.requireIllustrative(input.pension.regime)
        try PensionInputValidator.percent(input.percent, "Disability percentage")
        guard input.entitlement != .neither else { throw PensionError.ineligible("Disability element unavailable without attributable/aggravated entitlement.") }
        guard input.percent > 0 else { throw PensionError.ineligible("No disability element at zero percent.") }
        let service = try PensionCalculationEngine(rules: rules).calculateServicePension(input: input.pension)
        var applied = input.percent
        if input.broadBandingAuthorized {
            guard input.separation == .invalidment else { throw PensionError.unsupported("Broad-banding on retirement requires verified regime-specific rules.") }
            applied = input.percent <= 50 ? 50 : (input.percent <= 75 ? 75 : 100)
        }
        if input.warInjury && !input.injuryCategoryConfirmed { throw PensionError.ineligible("Confirm qualifying war injury circumstances.") }
        let rate: Decimal = input.warInjury ? (input.separation == .invalidment ? 100 : 60) : 30
        let element = Money.round(service.eligibleEmoluments * rate * applied / 10000)
        let dr = Money.round((service.basicPension + element) * input.pension.drPercent / 100)
        return DisabilityPensionResult(serviceElement: service.basicPension, disabilityElement: element, assessedPercent: input.percent, appliedPercent: applied, dr: dr, total: service.basicPension + element + dr, status: .illustrative, assumptions: service.assumptions + ["Synthetic \(input.warInjury ? "war injury" : "disability") rate: \(rate)% at 100% disability, pro rata. Broad-banding only by explicit assumption. Invalidment service concessions and war injury caps are not verified; this is not an entitlement."], appliedRuleIDs: ["illustrative-v1"])
    }
    func calculateWarInjuryPension(_ input: DisabilityInput) throws -> DisabilityPensionResult {
        var copy = input; copy.warInjury = true
        return try calculate(copy)
    }
}
