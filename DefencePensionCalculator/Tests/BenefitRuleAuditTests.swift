import XCTest
#if canImport(PensionCore)
@testable import PensionCore
#else
@testable import DefencePensionCalculator
#endif

final class BenefitRuleAuditTests: XCTestCase {
    func testVersionedAuditLoadsWithoutEnablingUnverifiedRules() throws {
        let catalog = try BenefitRuleAuditRepository().catalog
        XCTAssertEqual(catalog.schemaVersion, 2)
        XCTAssertFalse(catalog.dataVersion.isEmpty)
        XCTAssertTrue(catalog.enabledRuleIDs.isEmpty)
        XCTAssertTrue(catalog.benefits.allSatisfy { $0.decision == "disabled" })
    }

    func testGratuityTypesAndOtherSchemesHaveSeparateDisabledDecisions() throws {
        let ids = Set(try BenefitRuleAuditRepository().catalog.benefits.map(\.id))
        XCTAssertEqual(ids, Set(["retiringGratuity", "retirementGratuity", "serviceGratuity", "deathGratuity", "leaveEncashment", "sevaNidhi", "nps", "ups"]))
    }

    func testHistoricalRequestsRetainTheirExactURLsAndStatuses() throws {
        let sources = try BenefitRuleAuditRepository().catalog.sources
        XCTAssertEqual(sources.count, 6)
        XCTAssertEqual(sources.first { $0.id == "agnipath" }?.sourceURL, "https://www.pib.gov.in/PressReleasePage.aspx?PRID=1833765")
        XCTAssertEqual(sources.first { $0.id == "gratuity-ceiling" }?.sourceURL, "https://www.pib.gov.in/PressReleasePage.aspx?PRID=2022470")
        XCTAssertTrue(sources.allSatisfy { URL(string: $0.sourceURL)?.scheme == "https" })
        XCTAssertTrue(sources.allSatisfy { $0.verificationStatus == "retrievalBlockedAtPriorCheckpoint" && $0.originHTTPStatus == nil })
    }

    func testDocumentHashesAreWellFormedAndPartialOrderIsNotClaimedInspected() throws {
        let repository = try BenefitRuleAuditRepository()
        XCTAssertEqual(repository.catalog.documents.count, 15)
        XCTAssertTrue(repository.catalog.documents.allSatisfy { $0.contentSHA256.count == 64 })
        let order = try XCTUnwrap(repository.catalog.documents.first { $0.id == "mod-gratuity-revision-order-2017" })
        XCTAssertEqual(order.inspectionStatus, "hashMatchedOnly")
        XCTAssertFalse(order.sourceBodyInspected)
        let pib = try XCTUnwrap(repository.catalog.documents.first { $0.id == "agnipath-pib-prid-1834227" })
        XCTAssertTrue(pib.sourceBodyInspected)
        XCTAssertEqual(pib.contentSHA256, "70ba56a50b03959dbc9847187f2bbcc016f495c969d556a7c2ddb51bd6eea68e")
    }

    func testCivilianReferencesAndIncompleteMilitaryRulesNeverEnableBenefits() throws {
        let catalog = try BenefitRuleAuditRepository().catalog
        let leave = try XCTUnwrap(catalog.benefits.first { $0.id == "leaveEncashment" })
        XCTAssertTrue(leave.applicabilityPending.contains("civilian leave rules do not establish military entitlement"))
        let gratuity = try XCTUnwrap(catalog.benefits.first { $0.id == "retirementGratuity" })
        XCTAssertTrue(gratuity.verificationRequired.contains("applicable current ceiling"))
        let ups = try XCTUnwrap(catalog.benefits.first { $0.id == "ups" })
        XCTAssertTrue(ups.applicabilityPending.contains("not automatically regular Armed Forces"))
        XCTAssertTrue(catalog.benefits.allSatisfy { $0.decision == "disabled" })
    }

    func testEveryBenefitResolvesItsDocumentEvidenceWithoutOrphanReferences() throws {
        let repository = try BenefitRuleAuditRepository()
        for item in repository.catalog.benefits {
            XCTAssertEqual(repository.documents(for: item).count, item.sourceIDs.count)
        }
    }

    func testPriorProxyDenialIsNotMistakenForAnOriginResponse() throws {
        for source in try BenefitRuleAuditRepository().catalog.sources {
            XCTAssertEqual(source.proxyHTTPStatus, 403)
            XCTAssertNil(source.originHTTPStatus)
            XCTAssertFalse(source.sourceBodyInspected)
            XCTAssertNil(source.contentSHA256)
        }
    }
}

final class GratuityPreparationTests: XCTestCase {
    private let eventDate = DateUtilities.date(2024, 1, 1)

    private func context(
        commissionType: GratuityCommissionType = .permanent,
        dischargeGround: GratuityDischargeGround = .retirement,
        certified: Bool = true
    ) -> GratuityInputContext {
        GratuityInputContext(
            branch: .army,
            personnelCategory: .officer,
            commissionType: commissionType,
            eventDate: eventDate,
            dischargeGround: dischargeGround,
            certifiedQualifyingService: GratuityCertifiedQualifyingService(
                period: GratuityServicePeriod(years: 20, months: 0, days: 0),
                certifiedByCompetentAuthority: certified,
                certificationReference: certified ? "synthetic-service-certificate" : nil
            ),
            priorService: GratuityPriorServiceRecord(
                periods: [], treatment: .noneDeclared,
                certifiedByCompetentAuthority: certified,
                certificationReference: certified ? "synthetic-prior-service-check" : nil
            ),
            payComponents: GratuityPayComponents(
                basicPay: 100, militaryServicePay: 0, dearnessAllowance: 0,
                classificationOrGroupPay: 0, otherComponents: [], effectiveDate: eventDate,
                certifiedByCompetentAuthority: certified
            )
        )
    }

    private func failure<Value: Sendable>(
        _ outcome: GratuityCalculationOutcome<Value>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> GratuityCalculationFailure? {
        guard case .unavailable(let failure) = outcome else {
            XCTFail("Unsupported gratuity scenario returned a monetary result", file: file, line: line)
            return nil
        }
        return failure
    }

    func testUnknownCommissionAndDischargeGroundAreUnsupportedForEveryType() throws {
        let calculator = FailClosedGratuityCalculator(catalog: try BenefitRuleAuditRepository().catalog)
        let unsupported = context(commissionType: .unknown, dischargeGround: .unknown)
        XCTAssertEqual(failure(calculator.calculate(RetiringGratuityInput(context: unsupported)))?.reason, .unsupportedScenario)
        XCTAssertEqual(failure(calculator.calculate(RetirementGratuityInput(context: unsupported)))?.reason, .unsupportedScenario)
        XCTAssertEqual(failure(calculator.calculate(ServiceGratuityInput(context: unsupported)))?.reason, .unsupportedScenario)
        XCTAssertEqual(failure(calculator.calculate(DeathGratuityInput(context: unsupported)))?.reason, .unsupportedScenario)
    }

    func testUnsupportedPersonnelCategoryAndCommissionCombinationsStayUnavailable() throws {
        let calculator = FailClosedGratuityCalculator(catalog: try BenefitRuleAuditRepository().catalog)
        let officerWithoutApplicableCommission = RetirementGratuityInput(
            context: context(commissionType: .notApplicable)
        )
        let otherRankWithOfficerCommission = RetirementGratuityInput(
            context: context(commissionType: .permanent).replacingCategory(.otherRank)
        )
        XCTAssertEqual(failure(calculator.calculate(officerWithoutApplicableCommission))?.reason, .rulesNotVerified)
        XCTAssertEqual(failure(calculator.calculate(otherRankWithOfficerCommission))?.reason, .rulesNotVerified)
    }

    func testMissingEvidenceAndUncertifiedInputsNeverReturnAmounts() throws {
        let input = RetirementGratuityInput(context: context())
        XCTAssertEqual(failure(FailClosedGratuityCalculator().calculate(input))?.reason, .missingEvidence)

        let catalog = try BenefitRuleAuditRepository().catalog
        let calculator = FailClosedGratuityCalculator(catalog: catalog)
        let uncertified = RetirementGratuityInput(context: context(certified: false))
        XCTAssertEqual(failure(calculator.calculate(uncertified))?.reason, .uncertifiedRequiredInput)
        XCTAssertEqual(failure(calculator.calculate(input))?.reason, .rulesNotVerified)
    }

    func testFourBenefitTypesRemainDistinctAtCalculationBoundary() throws {
        let calculator = FailClosedGratuityCalculator(catalog: try BenefitRuleAuditRepository().catalog)
        let context = context()
        XCTAssertEqual(failure(calculator.calculate(RetiringGratuityInput(context: context)))?.benefitType, .retiringGratuity)
        XCTAssertEqual(failure(calculator.calculate(RetirementGratuityInput(context: context)))?.benefitType, .retirementGratuity)
        XCTAssertEqual(failure(calculator.calculate(ServiceGratuityInput(context: context)))?.benefitType, .serviceGratuity)
        XCTAssertEqual(failure(calculator.calculate(DeathGratuityInput(context: context)))?.benefitType, .deathGratuity)
    }

    func testUnavailableOrUnverifiedResultsCannotCreatePDFSummary() throws {
        let calculator = FailClosedGratuityCalculator(catalog: try BenefitRuleAuditRepository().catalog)
        let context = context()
        XCTAssertNil(GratuityPDFReportFactory.summary(from: calculator.calculate(RetiringGratuityInput(context: context))))
        XCTAssertNil(GratuityPDFReportFactory.summary(from: calculator.calculate(RetirementGratuityInput(context: context))))
        XCTAssertNil(GratuityPDFReportFactory.summary(from: calculator.calculate(ServiceGratuityInput(context: context))))
        XCTAssertNil(GratuityPDFReportFactory.summary(from: calculator.calculate(DeathGratuityInput(context: context))))

        let unverified = RetirementGratuityResult(evidence: GratuityResultEvidence(
            amount: 999999, eventDate: eventDate, appliedRuleIDs: ["unverified-rule"],
            ruleMetadata: [], assumptions: [], dataVersion: "test-fixture"
        ))
        XCTAssertNil(GratuityPDFReportFactory.summary(from: .calculated(unverified)))
    }

    func testFabricatedVerifiedMetadataCannotAuthorizeWhenRepositoryHasNoEnabledRules() throws {
        let repository = try BenefitRuleAuditRepository()
        XCTAssertTrue(repository.catalog.enabledRuleIDs.isEmpty)
        let fabricated = RetirementGratuityResult(evidence: evidence(
            appliedRuleIDs: ["fabricated-rule"],
            metadata: [metadata(id: "fabricated-rule", verified: true)]
        ))
        XCTAssertFalse(repository.authorizesGratuityPDF(
            benefitID: GratuityBenefitType.retirementGratuity.rawValue,
            appliedRuleIDs: fabricated.evidence.appliedRuleIDs,
            eventDate: eventDate
        ))
        XCTAssertNil(GratuityPDFReportFactory.summary(from: .calculated(fabricated)))
    }

    func testDisabledRuleCannotAuthorizeGratuityPDF() throws {
        let repository = try BenefitRuleAuditRepository()
        let disabledBenefit = try XCTUnwrap(repository.catalog.benefits.first { $0.id == "retirementGratuity" })
        XCTAssertEqual(disabledBenefit.decision, "disabled")
        let fabricated = RetirementGratuityResult(evidence: evidence(
            appliedRuleIDs: ["retirement-gratuity-v1"],
            metadata: [metadata(id: "retirement-gratuity-v1", verified: true)]
        ))
        XCTAssertFalse(repository.authorizesGratuityPDF(
            benefitID: disabledBenefit.id,
            appliedRuleIDs: fabricated.evidence.appliedRuleIDs,
            eventDate: eventDate
        ))
        XCTAssertNil(GratuityPDFReportFactory.summary(from: .calculated(fabricated)))
    }

    func testUnknownAndMismatchedRuleIDsAreRejected() throws {
        let unknown = RetirementGratuityResult(evidence: evidence(
            appliedRuleIDs: ["unknown-rule"],
            metadata: [metadata(id: "unknown-rule", verified: true)]
        ))
        let mismatch = RetirementGratuityResult(evidence: evidence(
            appliedRuleIDs: ["rule-a"],
            metadata: [metadata(id: "rule-b", verified: true)]
        ))
        XCTAssertNil(GratuityPDFReportFactory.summary(from: .calculated(unknown)))
        XCTAssertNil(GratuityPDFReportFactory.summary(from: .calculated(mismatch)))
    }

    func testMissingAndUnverifiedRuleMetadataAreRejected() throws {
        let missing = RetirementGratuityResult(evidence: evidence(
            appliedRuleIDs: ["rule-a"], metadata: []
        ))
        let unverified = RetirementGratuityResult(evidence: evidence(
            appliedRuleIDs: ["rule-a"], metadata: [metadata(id: "rule-a", verified: false)]
        ))
        XCTAssertNil(GratuityPDFReportFactory.summary(from: .calculated(missing)))
        XCTAssertNil(GratuityPDFReportFactory.summary(from: .calculated(unverified)))
    }

    private func evidence(appliedRuleIDs: [String], metadata: [PensionRuleMetadata]) -> GratuityResultEvidence {
        GratuityResultEvidence(
            amount: 999_999, eventDate: eventDate, appliedRuleIDs: appliedRuleIDs,
            ruleMetadata: metadata, assumptions: ["Synthetic fixture"], dataVersion: "fabricated-test-version"
        )
    }

    private func metadata(id: String, verified: Bool) -> PensionRuleMetadata {
        PensionRuleMetadata(
            id: id, sourceTitle: "Fabricated source", issuingAuthority: "Test only", orderNumber: nil,
            effectiveDate: "2024-01-01", publicationDate: nil, sourceURL: nil,
            applicability: "Fabricated applicability", dataVersion: "fabricated-test-version", verified: verified
        )
    }
}

private extension GratuityInputContext {
    func replacingCategory(_ category: RankCategory) -> GratuityInputContext {
        GratuityInputContext(
            branch: branch, personnelCategory: category, commissionType: commissionType,
            eventDate: eventDate, dischargeGround: dischargeGround,
            certifiedQualifyingService: certifiedQualifyingService, priorService: priorService,
            payComponents: payComponents
        )
    }
}

#if canImport(UIKit)
import UIKit
import PDFKit
final class BenefitReportFooterTests: XCTestCase {
    func testEveryPDFPageContainsDeveloperCreditInFooter() throws {
        let summary = CalculationSummary(title: "Synthetic footer test", date: Date(), status: .illustrative, rows: [],
            assumptions: (1...100).map { "Synthetic assumption \($0). Not an official entitlement." }, rules: ["illustrative-v1"])
        let url = try PensionPDFExporter.export(summary)
        defer { try? FileManager.default.removeItem(at: url) }
        let document = try XCTUnwrap(PDFDocument(url: url))
        XCTAssertGreaterThan(document.pageCount, 1)
        for index in 0..<document.pageCount {
            let page = try XCTUnwrap(document.page(at: index))
            let footer = page.selection(for: CGRect(x: 0, y: 0, width: 595, height: 60))?.string ?? ""
            XCTAssertTrue(footer.contains("Developed by Jaspal Singh"))
        }
    }

    func testUnavailableGratuityDoesNotReachPDFExporter() throws {
        let calculator = FailClosedGratuityCalculator(catalog: try BenefitRuleAuditRepository().catalog)
        let input = DeathGratuityInput(context: GratuityInputContext(
            branch: .army, personnelCategory: .otherRank, commissionType: .notApplicable,
            eventDate: DateUtilities.date(2024, 1, 1), dischargeGround: .deathInService,
            certifiedQualifyingService: GratuityCertifiedQualifyingService(
                period: GratuityServicePeriod(years: 10, months: 0, days: 0),
                certifiedByCompetentAuthority: true, certificationReference: "synthetic"
            ),
            priorService: GratuityPriorServiceRecord(periods: [], treatment: .noneDeclared,
                certifiedByCompetentAuthority: true, certificationReference: "synthetic"),
            payComponents: GratuityPayComponents(basicPay: 100, militaryServicePay: 0, dearnessAllowance: 0,
                classificationOrGroupPay: 0, otherComponents: [], effectiveDate: DateUtilities.date(2024, 1, 1),
                certifiedByCompetentAuthority: true)
        ))
        let fabricated = DeathGratuityResult(evidence: GratuityResultEvidence(
            amount: 999_999, eventDate: DateUtilities.date(2024, 1, 1),
            appliedRuleIDs: ["fabricated-death-rule"],
            ruleMetadata: [PensionRuleMetadata(
                id: "fabricated-death-rule", sourceTitle: "Fabricated", issuingAuthority: "Test only",
                orderNumber: nil, effectiveDate: "2024-01-01", publicationDate: nil, sourceURL: nil,
                applicability: "Fabricated", dataVersion: "test", verified: true
            )], assumptions: [], dataVersion: "test"
        ))
        let outcome = calculator.calculate(input)
        let summary = GratuityPDFReportFactory.summary(from: outcome)
        XCTAssertNil(summary)
        let fabricatedSummary = GratuityPDFReportFactory.summary(from: .calculated(fabricated))
        XCTAssertNil(fabricatedSummary)
        let exportedURL: URL?
        if let fabricatedSummary {
            exportedURL = try PensionPDFExporter.export(fabricatedSummary)
        } else {
            exportedURL = nil
        }
        XCTAssertNil(exportedURL, "An unapproved gratuity result must never reach the PDF exporter")
    }
}
#endif
