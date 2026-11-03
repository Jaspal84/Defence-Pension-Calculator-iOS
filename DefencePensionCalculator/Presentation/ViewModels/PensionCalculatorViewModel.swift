import Foundation
import Combine
@MainActor final class PensionCalculatorViewModel: ObservableObject {
    @Published var input = PensionInput()
    @Published var disability = DisabilityInput()
    @Published var family = FamilyPensionInput()
    @Published var commutation = CommutationInput()
    @Published var arrears = ArrearsInput()
    @Published var orop = OROPSelection()
    @Published var serviceResult: PensionCalculationResult?
    @Published var disabilityResult: DisabilityPensionResult?
    @Published var familyResult: FamilyPensionResult?
    @Published var commutationResult: CommutationResult?
    @Published var arrearsResult: ArrearsCalculationResult?
    @Published var oropResult: OROPEntry?
    @Published var summary: CalculationSummary?
    @Published var error: String?
    @Published var startupError: String?
    @Published var pdfURL: URL?
    let repository: BundledPensionRulesRepository?
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        do { repository = try BundledPensionRulesRepository() }
        catch { repository = nil; startupError = error.localizedDescription }
        // Only a non-sensitive display preference is retained. Inputs/results are session-only.
        if let raw = defaults.string(forKey: "preferredBranch"), let branch = ArmedForceBranch(rawValue: raw) {
            input.branch = branch
        }
        normalizeRank()
    }
    var ranks: [Rank] { repository?.ranks.filter { $0.branch == input.branch && $0.category == input.category } ?? [] }
    func normalizeRank() {
        if !ranks.contains(where: { $0.id == input.rankID }) { input.rankID = ranks.first?.id ?? "" }
        defaults.set(input.branch.rawValue, forKey: "preferredBranch")
    }
    func perform(_ block: () throws -> Void) {
        error = nil; pdfURL = nil
        do { try block() } catch { self.error = error.localizedDescription }
    }
    func rules() throws -> BundledPensionRulesRepository {
        guard let repository else { throw PensionError.missingData(startupError ?? "Bundled rules could not be loaded.") }
        return repository
    }
    func save(_ title: String, rows: [SummaryRow], assumptions: [String], rules: [String], status: CalculationStatus = .illustrative) {
        let context: [SummaryRow] = [
            SummaryRow(title: "Selected service (context)", value: input.branch.rawValue),
            SummaryRow(title: "Selected personnel category (context)", value: input.category.rawValue),
            SummaryRow(title: "Selected rank (context)", value: repository?.ranks.first(where: { $0.id == input.rankID })?.name ?? input.rankID),
            SummaryRow(title: "Selected qualifying service (context)", value: "\(input.serviceYears) years + \(input.completedHalfYears) half-year"),
            SummaryRow(title: "Selected retirement date (context)", value: DateUtilities.text(input.retirementDate))
        ]
        summary = CalculationSummary(title: title, date: Date(), status: status, rows: context + rows,
                                     assumptions: assumptions + ["Selected service context is taken from Calculator inputs. Family pension, commutation and arrears use their separate stated inputs; context does not establish eligibility."],
                                     rules: rules, ruleMetadata: repository?.metadata.filter { rules.contains($0.id) } ?? [])
    }
    func calculateService() {
        serviceResult = nil; summary = nil
        perform {
            let result = try PensionCalculationEngine(rules: rules()).calculateServicePension(input: input)
            serviceResult = result
            let rank = repository?.ranks.first(where: { $0.id == input.rankID })?.name ?? input.rankID
            save("Service pension", rows: [
                SummaryRow(title: "Branch / category", value: "\(input.branch.rawValue) / \(input.category.rawValue)"),
                SummaryRow(title: "Rank", value: rank),
                SummaryRow(title: "Retirement", value: DateUtilities.text(input.retirementDate)),
                SummaryRow(title: "Qualifying service", value: "\(input.serviceYears) years + \(input.completedHalfYears) half-year"),
                SummaryRow(title: "Pension category", value: "Service pension"),
                SummaryRow(title: "Basic pay input", value: Money.format(input.basicPay)),
                SummaryRow(title: "MSP input / inclusion", value: "\(Money.format(input.msp)) / \(input.includeMSP ? "included" : "excluded")"),
                SummaryRow(title: "Classification pay input", value: Money.format(input.classificationPay)),
                SummaryRow(title: "Other pensionable pay input", value: Money.format(input.otherPensionablePay)),
                SummaryRow(title: "Selected regime", value: input.regime.rawValue),
                SummaryRow(title: "Eligible emoluments", value: Money.format(result.eligibleEmoluments)),
                SummaryRow(title: "Basic pension", value: Money.format(result.basicPension)),
                SummaryRow(title: "DR (\(input.drPercent)%)", value: Money.format(result.dr)),
                SummaryRow(title: "Monthly payable", value: Money.format(result.monthlyPayable))
            ], assumptions: result.assumptions, rules: result.appliedRuleIDs)
        }
    }
    func calculateDisability() {
        disabilityResult = nil; summary = nil
        perform {
            disability.pension = input
            disability.pension.pensionType = disability.warInjury ? .warInjury : .disability
            let result = try DisabilityPensionEngine(rules: rules()).calculate(disability)
            disabilityResult = result
            save(disability.warInjury ? "War injury estimate" : "Disability estimate", rows: [
                SummaryRow(title: "Branch / rank", value: "\(input.branch.rawValue) / \(input.rankID)"),
                SummaryRow(title: "Personnel category", value: input.category.rawValue),
                SummaryRow(title: "Qualifying service", value: "\(input.serviceYears) years + \(input.completedHalfYears) half-year"),
                SummaryRow(title: "Retirement", value: DateUtilities.text(input.retirementDate)),
                SummaryRow(title: "Basic pay / MSP", value: "\(Money.format(input.basicPay)) / \(Money.format(input.msp))"),
                SummaryRow(title: "Classification / other pay", value: "\(Money.format(input.classificationPay)) / \(Money.format(input.otherPensionablePay))"),
                SummaryRow(title: "DR rate", value: "\(input.drPercent)%"),
                SummaryRow(title: "Entitlement / separation", value: "\(disability.entitlement.rawValue) / \(disability.separation.rawValue)"),
                SummaryRow(title: "Assessed / applied disability", value: "\(result.assessedPercent)% / \(result.appliedPercent)%"),
                SummaryRow(title: "Service element", value: Money.format(result.serviceElement)),
                SummaryRow(title: "Disability / war injury element", value: Money.format(result.disabilityElement)),
                SummaryRow(title: "DR", value: Money.format(result.dr)),
                SummaryRow(title: "Monthly payable", value: Money.format(result.total))
            ], assumptions: result.assumptions, rules: result.appliedRuleIDs)
        }
    }
    func calculateFamily() {
        familyResult = nil; summary = nil
        perform {
            let result = try FamilyPensionEngine(rules: rules()).calculate(family)
            familyResult = result
            save("\(family.category.rawValue) family pension", rows: [
                SummaryRow(title: "Date of death", value: DateUtilities.text(family.deathDate)),
                SummaryRow(title: "Enhanced period end (if selected)", value: family.category == .enhanced ? DateUtilities.text(family.enhancedEndDate) : "Not applicable"),
                SummaryRow(title: "DR rate", value: "\(family.drPercent)%"),
                SummaryRow(title: "Relationship", value: family.relationship.rawValue.capitalized),
                SummaryRow(title: "Emoluments", value: Money.format(family.emoluments)),
                SummaryRow(title: "Calculation date", value: DateUtilities.text(family.calculationDate)),
                SummaryRow(title: "Family element", value: Money.format(result.basicPension)),
                SummaryRow(title: "DR", value: Money.format(result.dr)),
                SummaryRow(title: "Monthly payable", value: Money.format(result.total))
            ], assumptions: result.assumptions, rules: result.appliedRuleIDs)
        }
    }
    func calculateCommutation() {
        commutationResult = nil; summary = nil
        perform {
            let result = try CommutationEngine(rules: rules()).calculate(commutation)
            commutationResult = result
            save("Commutation", rows: [
                SummaryRow(title: "Age next birthday", value: String(commutation.ageNextBirthday)),
                SummaryRow(title: "Pension category", value: commutation.pensionCategory.rawValue),
                SummaryRow(title: "Effective commutation date", value: DateUtilities.text(commutation.effectiveDate)),
                SummaryRow(title: "Commutation percentage", value: "\(commutation.percentage)%"),
                SummaryRow(title: "DR rate", value: "\(commutation.drPercent)%"),
                SummaryRow(title: "Original basic", value: Money.format(result.originalBasic)),
                SummaryRow(title: "Commuted portion", value: Money.format(result.commutedPortion)),
                SummaryRow(title: "Factor", value: "\(result.factor)"),
                SummaryRow(title: "Lump sum", value: Money.format(result.lumpSum)),
                SummaryRow(title: "Reduced basic", value: Money.format(result.reducedBasic)),
                SummaryRow(title: "DR on original basic", value: Money.format(result.dr)),
                SummaryRow(title: "Monthly payable", value: Money.format(result.netMonthly)),
                SummaryRow(title: "Restoration commencement", value: DateUtilities.text(commutation.restorationCommencementDate)),
                SummaryRow(title: "Restoration date", value: DateUtilities.text(result.restorationDate)),
                SummaryRow(title: "Restored monthly estimate", value: Money.format(result.restoredMonthly))
            ], assumptions: result.assumptions, rules: result.appliedRuleIDs)
        }
    }
    func calculateArrears() {
        arrearsResult = nil; summary = nil
        perform {
            let result = try ArrearsCalculationEngine().calculate(arrears)
            arrearsResult = result
            save("Arrears", rows: [
                SummaryRow(title: "Effective date", value: DateUtilities.text(arrears.start)),
                SummaryRow(title: "Through (inclusive)", value: DateUtilities.text(arrears.end)),
                SummaryRow(title: "Previous / revised", value: "\(Money.format(arrears.previous)) / \(Money.format(arrears.revised))"),
                SummaryRow(title: "Gross", value: Money.format(result.gross)),
                SummaryRow(title: "Previously paid", value: Money.format(result.previouslyPaid)),
                SummaryRow(title: "Net arrears / recovery", value: Money.format(result.total))
            ] + result.lines.map { SummaryRow(title: "\(DateUtilities.text($0.start)) – \(DateUtilities.text($0.end))", value: "\($0.days)/\($0.daysInMonth) days, DR \($0.drRate)%, \(Money.format($0.total))") }, assumptions: result.assumptions, rules: ["illustrative-v1"])
        }
    }
    func lookupOROP() {
        oropResult = nil; summary = nil
        perform {
            let row = try OROPCalculationEngine(rules: rules()).lookup(orop)
            oropResult = row
            save("OROP lookup", rows: [SummaryRow(title: "Table basic pension", value: Money.format(row.pension))], assumptions: ["Exact table selection; verify personal sanctioning records."], rules: [row.ruleID], status: .verified)
        }
    }
    func exportPDF() {
        perform {
            guard let summary else { throw PensionError.invalid("Calculate a result before exporting.") }
            pdfURL = try PensionPDFExporter.export(summary)
        }
    }
}
