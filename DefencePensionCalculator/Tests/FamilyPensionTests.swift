import XCTest
#if canImport(PensionCore)
@testable import PensionCore
#else
@testable import DefencePensionCalculator
#endif

final class FamilyPensionTests: XCTestCase {
    func engine() throws -> FamilyPensionEngine { FamilyPensionEngine(rules: try BundledPensionRulesRepository()) }
    func testOrdinarySynthetic() throws {
        var i = FamilyPensionInput(); i.beneficiaryEligible = true; i.drPercent = 10
        let r = try engine().calculate(i)
        XCTAssertEqual(r.basicPension, 12000); XCTAssertEqual(r.dr, 1200); XCTAssertEqual(r.total, 13200)
    }
    func testEnhancedDurationInclusive() throws {
        var i = FamilyPensionInput(); i.category = .enhanced; i.beneficiaryEligible = true
        i.calculationDate = i.enhancedEndDate
        XCTAssertEqual(try engine().calculate(i).basicPension, 20000)
        i.calculationDate = DateUtilities.calendar.date(byAdding: .day, value: 1, to: i.enhancedEndDate)!
        XCTAssertThrowsError(try engine().calculate(i))
    }
    func testEnhancedEndDateIncludesWholeIndianCalendarDay() throws {
        var i = FamilyPensionInput(); i.category = .enhanced; i.beneficiaryEligible = true
        i.calculationDate = i.enhancedEndDate.addingTimeInterval(12 * 3600)
        XCTAssertNoThrow(try engine().calculate(i))
    }
    func testSpecialAndLiberalizedNeedCircumstances() throws {
        var i = FamilyPensionInput(); i.beneficiaryEligible = true; i.category = .special
        XCTAssertThrowsError(try engine().calculate(i)); i.specialCircumstancesConfirmed = true
        XCTAssertEqual(try engine().calculate(i).basicPension, 24000)
        i.category = .liberalized
        XCTAssertThrowsError(try engine().calculate(i)); i.liberalizedCircumstancesConfirmed = true
        XCTAssertEqual(try engine().calculate(i).basicPension, 40000)
    }
    func testMissingEligibilityInvalidDatesAndNegativePay() throws {
        var i = FamilyPensionInput()
        XCTAssertThrowsError(try engine().calculate(i)); i.beneficiaryEligible = true; i.calculationDate = DateUtilities.date(2023, 1, 1)
        XCTAssertThrowsError(try engine().calculate(i)); i.calculationDate = DateUtilities.date(2025, 1, 1); i.emoluments = -1
        XCTAssertThrowsError(try engine().calculate(i))
    }
}
