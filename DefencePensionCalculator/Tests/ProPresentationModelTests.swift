import XCTest
#if canImport(PensionCore)
@testable import PensionCore
#else
@testable import DefencePensionCalculator
#endif

final class ProPresentationModelTests: XCTestCase {
    func testFiveTabsMatchRequestedNavigation() {
        XCTAssertEqual(AppTab.allCases.map(\.rawValue), ["Home", "Calculators", "Reports", "References", "Settings"])
        XCTAssertEqual(Set(AppTab.allCases.map(\.id)).count, 5)
    }
    func testAllTenDashboardRoutesHaveUniqueIdentifiers() {
        XCTAssertEqual(CalculatorRoute.allCases.count, 10)
        XCTAssertEqual(Set(CalculatorRoute.allCases.map(\.accessibilityID)).count, 10)
        XCTAssertTrue(CalculatorRoute.allCases.allSatisfy { !$0.title.isEmpty && !$0.symbol.isEmpty })
    }
    func testExistingCalculatorRoutesStayImplemented() {
        XCTAssertEqual(Set(CalculatorRoute.allCases.filter(\.implemented)), Set([.pension, .orop, .commutation, .disability, .family, .arrears]))
    }
    func testAdditionalCalculatorsDoNotClaimVerifiedAvailability() {
        for route in [CalculatorRoute.gratuity, .leaveEncashment, .sevaNidhi, .npsUPS] {
            XCTAssertFalse(route.implemented)
            XCTAssertEqual(route.availability, "Verified rules required")
            XCTAssertFalse(route.unavailableReason.isEmpty)
        }
    }
    func testOROPMissingDataRemainsExplicit() {
        XCTAssertEqual(CalculatorRoute.orop.availability, "Official data unavailable")
        XCTAssertTrue(CalculatorRoute.npsUPS.unavailableReason.contains("does not establish eligibility"))
    }
    func testCreatorAttributionAndIndependence() {
        XCTAssertEqual(AppBrand.developer, "Jaspal Singh")
        XCTAssertTrue(AppBrand.name.contains("Pro – India"))
        XCTAssertTrue(AppBrand.developerDescription.contains("Designed and developed by Jaspal Singh"))
        XCTAssertTrue(AppBrand.independence.contains("Not affiliated with or endorsed"))
        XCTAssertTrue(AppBrand.copyright.contains("© 2026 Jaspal Singh"))
    }
    func testVersionUsesBundleMetadataRatherThanReferenceImageValue() {
        XCTAssertEqual(AppBrand.version(info: ["CFBundleShortVersionString": "2.3.4", "CFBundleVersion": "17"]), "Version 2.3.4 (17)")
        XCTAssertEqual(AppBrand.version(info: ["CFBundleShortVersionString": "4.2"]), "Version 4.2")
        XCTAssertEqual(AppBrand.version(info: [:]), "Version unavailable")
    }
    func testContactAndWebsiteAreAbsentUntilConfigured() {
        XCTAssertNil(AppBrand.contact(info: [:])); XCTAssertNil(AppBrand.website(info: [:]))
        XCTAssertNil(AppBrand.contact(info: ["DeveloperContactEmail": "not an address"]))
        XCTAssertNil(AppBrand.website(info: ["DeveloperWebsiteURL": "javascript:alert(1)"]))
        XCTAssertNil(AppBrand.website(info: ["DeveloperWebsiteURL": "http://example.invalid"]))
    }
    func testConfiguredContactSelectorsUseSafeSchemes() {
        // Synthetic configuration; these are not application contact details.
        XCTAssertEqual(AppBrand.contact(info: ["DeveloperContactEmail": "creator@example.invalid"])?.scheme, "mailto")
        XCTAssertEqual(AppBrand.website(info: ["DeveloperWebsiteURL": "https://example.invalid"])?.scheme, "https")
    }
    func testReportContainsCreatorDisclaimerAndOriginalCalculationValues() {
        let report = sample()
        XCTAssertTrue(report.text.contains(AppBrand.name))
        XCTAssertTrue(report.text.contains("Developed by Jaspal Singh"))
        XCTAssertTrue(report.text.contains("Basic pension: INR 22,600"))
        XCTAssertTrue(report.text.contains(AppBrand.reportDisclaimer))
        XCTAssertTrue(report.text.contains(PensionNotice.disclaimer))
        XCTAssertTrue(report.text.contains("Illustrative estimate"))
    }
    func testUnverifiedMetadataNeverBecomesAnOfficialCitation() {
        var report = sample()
        report.ruleMetadata = [metadata(id: "illustrative-v1", verified: false)]
        XCTAssertEqual(report.sourceReferences, ["No verified official source references or effective dates are available for this calculation."])
    }
    func testOnlyAppliedVerifiedMetadataGetsDatesAndReferences() {
        var report = sample()
        report.ruleMetadata = [metadata(id: "unapplied-fixture", verified: true)]
        XCTAssertTrue(report.sourceReferences[0].contains("No verified"))
        report.ruleMetadata = [metadata(id: "illustrative-v1", verified: true)]
        XCTAssertTrue(report.sourceReferences[0].contains("Effective: 2024-01-01"))
        XCTAssertTrue(report.sourceReferences[0].contains("Synthetic metadata fixture"))
    }
    func testReportCodableRetainsRulesAndAssumptions() throws {
        let report = sample()
        let decoded = try JSONDecoder().decode(CalculationSummary.self, from: JSONEncoder().encode(report))
        XCTAssertEqual(decoded.text, report.text)
        XCTAssertEqual(decoded.sourceReferences, report.sourceReferences)
    }
    private func sample() -> CalculationSummary {
        CalculationSummary(title: "Synthetic report", date: DateUtilities.date(2024, 1, 1), status: .illustrative,
                           rows: [SummaryRow(title: "Basic pension", value: "INR 22,600")], assumptions: ["Synthetic assumption, not an official example."], rules: ["illustrative-v1"])
    }
    private func metadata(id: String, verified: Bool) -> PensionRuleMetadata {
        PensionRuleMetadata(id: id, sourceTitle: "Synthetic metadata fixture", issuingAuthority: "Test fixture only", orderNumber: nil,
                            effectiveDate: "2024-01-01", publicationDate: nil, sourceURL: nil, applicability: "Synthetic test only", dataVersion: "test", verified: verified)
    }
}
#if canImport(UIKit)
import UIKit
import PDFKit
final class ProPDFAndThemeTests: XCTestCase {
    func testLongReportRowsPaginateAndPreserveDisclaimersAndCreator() throws {
        let summary = CalculationSummary(title: "Synthetic long-row test", date: DateUtilities.date(2024, 1, 1), status: .illustrative,
                                        rows: [SummaryRow(title: "Long synthetic input", value: String(repeating: "unbroken", count: 700))], assumptions: [], rules: ["illustrative-v1"])
        let url = try PensionPDFExporter.export(summary)
        defer { try? FileManager.default.removeItem(at: url) }
        let pdf = try XCTUnwrap(PDFDocument(url: url))
        XCTAssertGreaterThan(pdf.pageCount, 1)
        let text = try XCTUnwrap(pdf.string)
        XCTAssertTrue(text.contains("Developed by Jaspal Singh"))
        XCTAssertTrue(text.contains("No verified official source"))
        XCTAssertTrue(text.contains("not an official pension entitlement"))
        XCTAssertTrue(text.contains("Page 2"))
    }
    func testGeneratedPDFFailsWithInvalidOutputDirectory() {
        let summary = CalculationSummary(title: "Synthetic", date: Date(), status: .illustrative, rows: [], assumptions: [], rules: [])
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("missing")
        XCTAssertThrowsError(try PensionPDFExporter.export(summary, directory: missing))
    }
    func testSemanticSurfacesAdaptToLightAndDarkMode() {
        let light = UITraitCollection(userInterfaceStyle: .light), dark = UITraitCollection(userInterfaceStyle: .dark)
        XCTAssertNotEqual(UIColor.systemGroupedBackground.resolvedColor(with: light), UIColor.systemGroupedBackground.resolvedColor(with: dark))
        XCTAssertNotEqual(UIColor.secondarySystemGroupedBackground.resolvedColor(with: light), UIColor.secondarySystemGroupedBackground.resolvedColor(with: dark))
    }
}
#endif
