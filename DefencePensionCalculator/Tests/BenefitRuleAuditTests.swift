import XCTest
#if canImport(PensionCore)
@testable import PensionCore
#else
@testable import DefencePensionCalculator
#endif
final class BenefitRuleAuditTests: XCTestCase {
    func testVersionedAuditLoadsWithoutEnablingUnverifiedRules() throws {
        let catalog = try BenefitRuleAuditRepository().catalog
        XCTAssertEqual(catalog.schemaVersion, 1)
        XCTAssertFalse(catalog.dataVersion.isEmpty)
        XCTAssertTrue(catalog.enabledRuleIDs.isEmpty)
        XCTAssertTrue(catalog.benefits.allSatisfy { $0.decision == "disabled" })
    }
    func testRetirementAndDeathAndNPSSchemesHaveSeparateResearchDecisions() throws {
        let ids = Set(try BenefitRuleAuditRepository().catalog.benefits.map(\.id))
        XCTAssertEqual(ids, Set(["retirementGratuity", "deathGratuity", "leaveEncashment", "sevaNidhi", "nps", "ups"]))
    }
    func testAllSixRequestedSourcesRetainTheirExactOfficialURLs() throws {
        let sources = try BenefitRuleAuditRepository().catalog.sources
        XCTAssertEqual(sources.count, 6)
        XCTAssertEqual(sources.first { $0.id == "agnipath" }?.sourceURL, "https://www.pib.gov.in/PressReleasePage.aspx?PRID=1833765")
        XCTAssertEqual(sources.first { $0.id == "gratuity-ceiling" }?.sourceURL, "https://www.pib.gov.in/PressReleasePage.aspx?PRID=2022470")
        XCTAssertTrue(sources.allSatisfy { URL(string: $0.sourceURL)?.scheme == "https" })
    }
    func testProxyDenialIsNotMistakenForAnOriginResponseOrVerifiedDocument() throws {
        for source in try BenefitRuleAuditRepository().catalog.sources {
            XCTAssertEqual(source.proxyHTTPStatus, 403)
            XCTAssertNil(source.originHTTPStatus)
            XCTAssertEqual(source.verificationStatus, "retrievalBlocked")
            XCTAssertFalse(source.sourceBodyInspected)
            XCTAssertNil(source.contentSHA256)
        }
    }
    func testUninspectedDocumentsNeverInventTitlesDatesOrdersOrRuleNumbers() throws {
        for source in try BenefitRuleAuditRepository().catalog.sources {
            XCTAssertNil(source.sourceTitle); XCTAssertNil(source.issuingAuthority)
            XCTAssertNil(source.documentNumber); XCTAssertNil(source.ruleNumber)
            XCTAssertNil(source.effectiveDate); XCTAssertNil(source.publicationDate)
        }
    }
    func testCivilianReferencesDoNotEstablishMilitaryApplicability() throws {
        let catalog = try BenefitRuleAuditRepository().catalog
        let leave = try XCTUnwrap(catalog.benefits.first { $0.id == "leaveEncashment" })
        XCTAssertTrue(leave.applicabilityPending.contains("not military authority"))
        let gratuity = try XCTUnwrap(catalog.benefits.first { $0.id == "retirementGratuity" })
        XCTAssertTrue(gratuity.verificationRequired.contains("does not establish a military ceiling"))
        let ups = try XCTUnwrap(catalog.benefits.first { $0.id == "ups" })
        XCTAssertTrue(ups.applicabilityPending.contains("not automatically regular Armed Forces"))
    }
    func testEveryBenefitResolvesItsSourceEvidenceWithoutOrphanReferences() throws {
        let repository = try BenefitRuleAuditRepository()
        for item in repository.catalog.benefits {
            XCTAssertEqual(repository.sources(for: item).count, item.sourceIDs.count)
        }
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
}
#endif
