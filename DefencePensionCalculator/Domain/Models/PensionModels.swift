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

enum GratuityBenefitType: String, Codable, CaseIterable, Sendable, Equatable {
    case retiringGratuity
    case retirementGratuity
    case serviceGratuity
    case deathGratuity

    var title: String {
        switch self {
        case .retiringGratuity: return "Retiring gratuity"
        case .retirementGratuity: return "Retirement gratuity"
        case .serviceGratuity: return "Service gratuity"
        case .deathGratuity: return "Death gratuity"
        }
    }
}

enum GratuityCommissionType: String, Codable, CaseIterable, Sendable, Equatable {
    case permanent
    case shortService
    case militaryNursingService
    case territorialArmy
    case notApplicable
    case unknown
}

enum GratuityDischargeGround: String, Codable, CaseIterable, Sendable, Equatable {
    case retirement
    case superannuation
    case completionOfEngagement
    case invalidment
    case resignation
    case dismissal
    case deathInService
    case other
    case unknown
}

struct GratuityServicePeriod: Codable, Sendable, Equatable {
    let years: Int
    let months: Int
    let days: Int
}

struct GratuityCertifiedQualifyingService: Codable, Sendable, Equatable {
    let period: GratuityServicePeriod
    let certifiedByCompetentAuthority: Bool
    let certificationReference: String?
}

enum GratuityPriorServiceTreatment: String, Codable, Sendable, Equatable {
    case noneDeclared
    case claimedForCredit
    case certifiedAsCredited
    case certifiedAsNotCredited
    case pendingVerification
}

struct GratuityPriorServiceRecord: Codable, Sendable, Equatable {
    let periods: [GratuityServicePeriod]
    let treatment: GratuityPriorServiceTreatment
    let certifiedByCompetentAuthority: Bool
    let certificationReference: String?
}

struct GratuityPayComponent: Codable, Sendable, Equatable {
    let name: String
    let amount: Decimal
}

struct GratuityPayComponents: Codable, Sendable, Equatable {
    let basicPay: Decimal
    let militaryServicePay: Decimal
    let dearnessAllowance: Decimal
    let classificationOrGroupPay: Decimal
    let otherComponents: [GratuityPayComponent]
    let effectiveDate: Date
    let certifiedByCompetentAuthority: Bool
}

struct GratuityInputContext: Codable, Sendable, Equatable {
    let branch: ArmedForceBranch
    let personnelCategory: RankCategory
    let commissionType: GratuityCommissionType
    let eventDate: Date
    let dischargeGround: GratuityDischargeGround
    let certifiedQualifyingService: GratuityCertifiedQualifyingService
    let priorService: GratuityPriorServiceRecord
    let payComponents: GratuityPayComponents
}

// Distinct input types prevent retiring, retirement, service and death gratuity
// scenarios from silently sharing one benefit-specific calculation path.
struct RetiringGratuityInput: Codable, Sendable, Equatable { let context: GratuityInputContext }
struct RetirementGratuityInput: Codable, Sendable, Equatable { let context: GratuityInputContext }
struct ServiceGratuityInput: Codable, Sendable, Equatable { let context: GratuityInputContext }
struct DeathGratuityInput: Codable, Sendable, Equatable { let context: GratuityInputContext }

struct GratuityResultEvidence: Sendable {
    let amount: Decimal
    let eventDate: Date
    let appliedRuleIDs: [String]
    let ruleMetadata: [PensionRuleMetadata]
    let assumptions: [String]
    let dataVersion: String
}

protocol GratuityCalculationResult: Sendable {
    var benefitType: GratuityBenefitType { get }
    var evidence: GratuityResultEvidence { get }
}

struct RetiringGratuityResult: GratuityCalculationResult { let evidence: GratuityResultEvidence; let benefitType: GratuityBenefitType = .retiringGratuity }
struct RetirementGratuityResult: GratuityCalculationResult { let evidence: GratuityResultEvidence; let benefitType: GratuityBenefitType = .retirementGratuity }
struct ServiceGratuityResult: GratuityCalculationResult { let evidence: GratuityResultEvidence; let benefitType: GratuityBenefitType = .serviceGratuity }
struct DeathGratuityResult: GratuityCalculationResult { let evidence: GratuityResultEvidence; let benefitType: GratuityBenefitType = .deathGratuity }

enum GratuityUnavailableReason: String, Codable, Sendable, Equatable {
    case unsupportedScenario
    case invalidInput
    case uncertifiedRequiredInput
    case missingEvidence
    case rulesNotVerified
    case formulaNotImplemented
}

struct GratuityCalculationFailure: Error, Sendable, Equatable {
    let benefitType: GratuityBenefitType
    let reason: GratuityUnavailableReason
}

enum GratuityCalculationOutcome<Result: Sendable>: Sendable {
    case unavailable(GratuityCalculationFailure)
    case calculated(Result)
}

protocol GratuityCalculationInterface: Sendable {
    func calculate(_ input: RetiringGratuityInput) -> GratuityCalculationOutcome<RetiringGratuityResult>
    func calculate(_ input: RetirementGratuityInput) -> GratuityCalculationOutcome<RetirementGratuityResult>
    func calculate(_ input: ServiceGratuityInput) -> GratuityCalculationOutcome<ServiceGratuityResult>
    func calculate(_ input: DeathGratuityInput) -> GratuityCalculationOutcome<DeathGratuityResult>
}

/// Preparation-stage implementation. It intentionally has no path that produces a result.
struct FailClosedGratuityCalculator: GratuityCalculationInterface {
    let catalog: BenefitRuleAuditCatalog?

    init(catalog: BenefitRuleAuditCatalog? = nil) {
        self.catalog = catalog
    }

    func calculate(_ input: RetiringGratuityInput) -> GratuityCalculationOutcome<RetiringGratuityResult> {
        .unavailable(failure(for: .retiringGratuity, context: input.context))
    }

    func calculate(_ input: RetirementGratuityInput) -> GratuityCalculationOutcome<RetirementGratuityResult> {
        .unavailable(failure(for: .retirementGratuity, context: input.context))
    }

    func calculate(_ input: ServiceGratuityInput) -> GratuityCalculationOutcome<ServiceGratuityResult> {
        .unavailable(failure(for: .serviceGratuity, context: input.context))
    }

    func calculate(_ input: DeathGratuityInput) -> GratuityCalculationOutcome<DeathGratuityResult> {
        .unavailable(failure(for: .deathGratuity, context: input.context))
    }

    private func failure(for benefit: GratuityBenefitType, context: GratuityInputContext) -> GratuityCalculationFailure {
        func fail(_ reason: GratuityUnavailableReason) -> GratuityCalculationFailure {
            GratuityCalculationFailure(benefitType: benefit, reason: reason)
        }

        guard context.commissionType != .unknown, context.dischargeGround != .unknown else {
            return fail(.unsupportedScenario)
        }
        guard Self.valid(context.certifiedQualifyingService.period),
              context.priorService.periods.allSatisfy(Self.valid),
              context.payComponents.basicPay >= 0,
              context.payComponents.militaryServicePay >= 0,
              context.payComponents.dearnessAllowance >= 0,
              context.payComponents.classificationOrGroupPay >= 0,
              context.payComponents.otherComponents.allSatisfy({ $0.amount >= 0 }) else {
            return fail(.invalidInput)
        }
        let priorServiceIsResolved: Bool
        switch context.priorService.treatment {
        case .noneDeclared:
            priorServiceIsResolved = context.priorService.periods.isEmpty && context.priorService.certifiedByCompetentAuthority
        case .certifiedAsCredited, .certifiedAsNotCredited:
            priorServiceIsResolved = !context.priorService.periods.isEmpty && context.priorService.certifiedByCompetentAuthority
        case .claimedForCredit, .pendingVerification:
            priorServiceIsResolved = false
        }
        guard context.certifiedQualifyingService.certifiedByCompetentAuthority,
              priorServiceIsResolved,
              context.payComponents.certifiedByCompetentAuthority else {
            return fail(.uncertifiedRequiredInput)
        }
        guard let catalog else { return fail(.missingEvidence) }
        guard let audit = catalog.benefits.first(where: { $0.id == benefit.rawValue }),
              !audit.sourceIDs.isEmpty,
              audit.sourceIDs.allSatisfy({ id in catalog.documents.contains(where: { $0.id == id && !$0.contentSHA256.isEmpty }) }) else {
            return fail(.missingEvidence)
        }
        guard audit.decision == "enabled",
              !catalog.enabledRuleIDs.isEmpty else {
            return fail(.rulesNotVerified)
        }
        // Evidence may be complete in a future version, but this preparation build has no formula.
        return fail(.formulaNotImplemented)
    }

    private static func valid(_ period: GratuityServicePeriod) -> Bool {
        period.years >= 0 && (0..<12).contains(period.months) && (0..<31).contains(period.days)
    }
}
