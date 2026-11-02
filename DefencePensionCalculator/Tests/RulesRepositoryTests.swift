import XCTest
#if canImport(PensionCore)
@testable import PensionCore
#else
@testable import DefencePensionCalculator
#endif

final class RulesRepositoryTests: XCTestCase {
    func testAllJSONResourcesDecode() throws {
        let r = try BundledPensionRulesRepository()
        XCTAssertGreaterThan(r.ranks.count, 30)
        XCTAssertEqual(Set(r.ranks.map(\.id)).count, r.ranks.count)
        XCTAssertFalse(r.metadata.isEmpty)
        XCTAssertTrue(r.factors.entries.isEmpty); XCTAssertFalse(r.factors.verified)
        XCTAssertTrue(r.payMatrix.entries.isEmpty); XCTAssertFalse(r.payMatrix.verified)
        XCTAssertTrue(r.oropTable.entries.isEmpty); XCTAssertFalse(r.oropTable.verified)
        XCTAssertTrue(r.metadata.allSatisfy { !$0.verified })
    }
    func testMissingOfficialOROPReturnsExactMessage() throws {
        let engine = OROPCalculationEngine(rules: try BundledPensionRulesRepository())
        XCTAssertThrowsError(try engine.lookup(OROPSelection())) { error in
            XCTAssertEqual(error.localizedDescription, "Official OROP table data unavailable for this selection.")
        }
    }
    func testMissingFactorAndInvalidResource() throws {
        let r = try BundledPensionRulesRepository()
        XCTAssertThrowsError(try r.commutationFactor(age: 61))
        XCTAssertThrowsError(try LocalJSONRepository().load("Missing", as: [Rank].self))
    }
    func testInvalidOROPService() throws {
        var s = OROPSelection(); s.serviceHalfYears = -1
        XCTAssertThrowsError(try OROPCalculationEngine(rules: BundledPensionRulesRepository()).lookup(s))
    }
    func testInputCodableRoundTrip() throws {
        let i = PensionInput()
        XCTAssertEqual(try JSONDecoder().decode(PensionInput.self, from: JSONEncoder().encode(i)), i)
    }
}
#if canImport(UIKit)
import UIKit
import PDFKit
final class PensionPDFExporterTests: XCTestCase {
    func testPDFContainsStatusDisclaimerAndMultiplePages() throws {
        let s = CalculationSummary(title: "Synthetic PDF test", date: DateUtilities.date(2024, 1, 1), status: .illustrative,
            rows: [SummaryRow(title: "Basic pension", value: "INR 22,600")],
            assumptions: (1...100).map { "Synthetic assumption \($0): not an official entitlement." }, rules: ["illustrative-v1"])
        let url = try PensionPDFExporter.export(s)
        defer { try? FileManager.default.removeItem(at: url) }
        let pdf = try XCTUnwrap(PDFDocument(url: url))
        XCTAssertGreaterThan(pdf.pageCount, 1)
        let text = try XCTUnwrap(pdf.string)
        XCTAssertTrue(text.contains("Illustrative estimate")); XCTAssertTrue(text.contains("Final pension entitlement"))
        XCTAssertTrue(text.contains("Synthetic assumption 100"))
    }
}
#endif
