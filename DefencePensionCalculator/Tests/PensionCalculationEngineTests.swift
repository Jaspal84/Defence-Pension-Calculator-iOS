import XCTest
#if canImport(PensionCore)
@testable import PensionCore
#else
@testable import DefencePensionCalculator
#endif

// All numeric examples in these suites are synthetic, not official entitlement examples.
final class PensionCalculationEngineTests: XCTestCase {
    func engine() throws -> PensionCalculationEngine { PensionCalculationEngine(rules: try BundledPensionRulesRepository()) }
    func testServiceIncludesMSPAndDR() throws {
        var i = PensionInput(); i.drPercent = 10
        let r = try engine().calculateServicePension(input: i)
        XCTAssertEqual(r.eligibleEmoluments, 45200); XCTAssertEqual(r.basicPension, 22600)
        XCTAssertEqual(r.dr, 2260); XCTAssertEqual(r.monthlyPayable, 24860)
        XCTAssertEqual(r.status, .illustrative); XCTAssertFalse(r.assumptions.isEmpty)
    }
    func testMSPCanBeExcluded() throws {
        var i = PensionInput(); i.includeMSP = false
        XCTAssertEqual(try engine().calculateServicePension(input: i).basicPension, 20000)
    }
    func testClassificationRequiresExplicitInclusion() throws {
        var i = PensionInput(); i.classificationPay = 6000
        XCTAssertThrowsError(try engine().calculateServicePension(input: i))
        i.classificationEligible = true
        XCTAssertEqual(try engine().calculateServicePension(input: i).basicPension, 25600)
    }
    func testOtherPayRequiresAuthorization() throws {
        var i = PensionInput(); i.otherPensionablePay = 1000
        XCTAssertThrowsError(try engine().calculateServicePension(input: i))
        i.otherPayAuthorized = true
        XCTAssertEqual(try engine().calculateServicePension(input: i).basicPension, 23100)
    }
    func testSyntheticMinimum() throws {
        var i = PensionInput(); i.basicPay = 100; i.msp = 0
        XCTAssertEqual(try engine().calculateServicePension(input: i).basicPension, 9000)
    }
    func testOtherRankQualifyingServiceBoundary() throws {
        var i = PensionInput(); i.serviceYears = 14; i.completedHalfYears = 1
        XCTAssertThrowsError(try engine().calculateServicePension(input: i))
        i.serviceYears = 15; i.completedHalfYears = 0
        XCTAssertNoThrow(try engine().calculateServicePension(input: i))
    }
    func testOfficerServiceBoundary() throws {
        var i = PensionInput(); i.category = .officer; i.rankID = "army-captain"; i.serviceYears = 19
        XCTAssertThrowsError(try engine().calculateServicePension(input: i))
        i.serviceYears = 20
        XCTAssertNoThrow(try engine().calculateServicePension(input: i))
    }
    func testNegativeAndInvalidPeriod() throws {
        var i = PensionInput(); i.basicPay = -1
        XCTAssertThrowsError(try engine().calculateServicePension(input: i))
        i.basicPay = 1; i.completedHalfYears = 2
        XCTAssertThrowsError(try engine().calculateServicePension(input: i))
    }
    func testInvalidDatesAndRank() throws {
        var i = PensionInput(); i.birthDate = DateUtilities.date(2025, 1, 1)
        XCTAssertThrowsError(try engine().calculateServicePension(input: i))
        i = PensionInput(); i.branch = .navy
        XCTAssertThrowsError(try engine().calculateServicePension(input: i))
    }
    func testVerifiedRegimesUnavailable() throws {
        var i = PensionInput(); i.regime = .seventhCPC
        XCTAssertThrowsError(try engine().calculateServicePension(input: i))
        i.regime = .orop
        XCTAssertThrowsError(try engine().calculateServicePension(input: i))
    }
    func testRoundingAndNonFiniteDouble() throws {
        XCTAssertEqual(Money.round(Decimal(string: "1.005")!), Decimal(string: "1.01")!)
        XCTAssertEqual(Money.round(Decimal(string: "-1.005")!), Decimal(string: "-1.01")!)
        XCTAssertThrowsError(try Money.decimal(.infinity)); XCTAssertThrowsError(try Money.decimal(.nan))
        XCTAssertTrue(Money.format(123456).contains("1,23,456"))
    }
    func testDRBounds() throws {
        var i = PensionInput(); i.drPercent = -1
        XCTAssertThrowsError(try engine().calculateServicePension(input: i))
        i.drPercent = 101
        XCTAssertThrowsError(try engine().calculateServicePension(input: i))
    }
}
