import XCTest
#if canImport(PensionCore)
@testable import PensionCore
#else
@testable import DefencePensionCalculator
#endif

final class CommutationTests: XCTestCase {
    func engine() throws -> CommutationEngine { CommutationEngine(rules: try BundledPensionRulesRepository()) }
    func input() -> CommutationInput {
        var i = CommutationInput(); i.illustrativeFactor = 8; i.commencementConfirmed = true
        i.effectiveDate = DateUtilities.date(2024, 1, 1); i.restorationCommencementDate = DateUtilities.date(2024, 2, 1)
        return i
    }
    func testSyntheticLumpSumDRAndRestoration() throws {
        var i = input(); i.drPercent = 10
        let r = try engine().calculate(i)
        XCTAssertEqual(r.commutedPortion, 9040); XCTAssertEqual(r.lumpSum, 867840)
        XCTAssertEqual(r.reducedBasic, 13560); XCTAssertEqual(r.dr, 2260); XCTAssertEqual(r.netMonthly, 15820)
        XCTAssertEqual(r.restoredMonthly, 24860)
        XCTAssertEqual(r.restorationDate, DateUtilities.date(2039, 2, 1))
    }
    func testLeapDayRestoration() throws {
        var i = input(); i.restorationCommencementDate = DateUtilities.date(2024, 2, 29)
        XCTAssertEqual(try engine().calculate(i).restorationDate, DateUtilities.date(2039, 2, 28))
    }
    func testPercentageLimits() throws {
        var i = input(); i.percentage = 50
        XCTAssertNoThrow(try engine().calculate(i)); i.percentage = 51
        XCTAssertThrowsError(try engine().calculate(i)); i.percentage = -1
        XCTAssertThrowsError(try engine().calculate(i))
    }
    func testInvalidAgeFactorAndCategory() throws {
        var i = input(); i.ageNextBirthday = 0
        XCTAssertThrowsError(try engine().calculate(i)); i = input(); i.illustrativeFactor = 0
        XCTAssertThrowsError(try engine().calculate(i)); i = input(); i.pensionCategory = .family
        XCTAssertThrowsError(try engine().calculate(i))
    }
    func testMissingFactorNotInvented() throws {
        var i = input(); i.illustrativeFactor = nil
        XCTAssertThrowsError(try engine().calculate(i))
    }
    func testCommencementMustBeConfirmedAndOrdered() throws {
        var i = input(); i.commencementConfirmed = false
        XCTAssertThrowsError(try engine().calculate(i)); i.commencementConfirmed = true
        i.restorationCommencementDate = DateUtilities.date(2023, 1, 1)
        XCTAssertThrowsError(try engine().calculate(i))
    }
    func testConvenienceAPIUsesExplicitContext() throws {
        let e = CommutationEngine(rules: try BundledPensionRulesRepository(), context: input())
        XCTAssertEqual(try e.calculateCommutation(basicPension: 22600, ageNextBirthday: 61, percentage: 40).lumpSum, 867840)
    }
    func testConvenienceAPIRequiresExplicitContext() throws {
        XCTAssertThrowsError(try engine().calculateCommutation(basicPension: 22600, ageNextBirthday: 61, percentage: 40))
    }
}
