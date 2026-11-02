import XCTest
#if canImport(PensionCore)
@testable import PensionCore
#else
@testable import DefencePensionCalculator
#endif

final class DisabilityPensionTests: XCTestCase {
    func engine() throws -> DisabilityPensionEngine { DisabilityPensionEngine(rules: try BundledPensionRulesRepository()) }
    func testAttributableAndAggravated() throws {
        var i = DisabilityInput()
        for category in [DisabilityEntitlementCategory.attributable, .aggravated] {
            i.entitlement = category
            let r = try engine().calculate(i)
            XCTAssertEqual(r.serviceElement, 22600); XCTAssertEqual(r.disabilityElement, 6780)
            XCTAssertEqual(r.total, 29380)
        }
    }
    func testNeitherAndZeroRejected() throws {
        var i = DisabilityInput(); i.entitlement = .neither
        XCTAssertThrowsError(try engine().calculate(i)); i.entitlement = .attributable; i.percent = 0
        XCTAssertThrowsError(try engine().calculate(i))
    }
    func testInvalidPercent() throws {
        var i = DisabilityInput()
        for p in [Decimal(-1), 101, .nan] { i.percent = p; XCTAssertThrowsError(try engine().calculate(i)) }
    }
    func testBroadBandingBoundariesSynthetic() throws {
        var i = DisabilityInput(); i.separation = .invalidment; i.broadBandingAuthorized = true
        for (assessed, expected) in [(1, 50), (49, 50), (50, 50), (51, 75), (75, 75), (76, 100), (100, 100)] {
            i.percent = Decimal(assessed)
            XCTAssertEqual(try engine().calculate(i).appliedPercent, Decimal(expected))
        }
    }
    func testRetirementBroadBandingNotAssumed() throws {
        var i = DisabilityInput(); i.broadBandingAuthorized = true
        XCTAssertThrowsError(try engine().calculate(i))
    }
    func testWarInjuryDistinctFromOrdinaryDisability() throws {
        var i = DisabilityInput(); i.injuryCategoryConfirmed = true
        XCTAssertEqual(try engine().calculateWarInjuryPension(i).disabilityElement, 13560)
        i.separation = .invalidment
        XCTAssertEqual(try engine().calculateWarInjuryPension(i).disabilityElement, 22600)
        XCTAssertEqual(try engine().calculate(i).disabilityElement, 6780)
    }
    func testWarInjuryNeedsCategory() throws {
        XCTAssertThrowsError(try engine().calculateWarInjuryPension(DisabilityInput()))
    }
    func testConvenienceDisabilityInterface() throws {
        let e = PensionCalculationEngine(rules: try BundledPensionRulesRepository())
        XCTAssertEqual(try e.calculateDisabilityPension(input: PensionInput(), disabilityPercent: 50).disabilityElement, 6780)
    }
}
