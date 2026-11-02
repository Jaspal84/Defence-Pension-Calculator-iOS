import XCTest
#if canImport(PensionCore)
@testable import PensionCore
#else
@testable import DefencePensionCalculator
#endif

final class ArrearsTests: XCTestCase {
    func testDRChangeAndPreviouslyPaid() throws {
        var i = ArrearsInput(); i.previous = 1000; i.revised = 1100
        i.periods = [DRPeriod(start: DateUtilities.date(2024, 1, 1), rate: 10), DRPeriod(start: DateUtilities.date(2024, 7, 1), rate: 20)]
        i.previouslyPaid = 50
        let r = try ArrearsCalculationEngine().calculate(i)
        XCTAssertEqual(r.lines.count, 12); XCTAssertEqual(r.gross, 1380); XCTAssertEqual(r.total, 1330)
    }
    func testPartialMonthAndMidMonthDRChange() throws {
        var i = ArrearsInput(); i.previous = 0; i.revised = 3100
        i.start = DateUtilities.date(2024, 1, 16); i.end = DateUtilities.date(2024, 1, 31)
        i.periods = [DRPeriod(start: DateUtilities.date(2024, 1, 1), rate: 0), DRPeriod(start: DateUtilities.date(2024, 1, 20), rate: 10)]
        let r = try ArrearsCalculationEngine().calculate(i)
        XCTAssertEqual(r.lines.count, 2); XCTAssertEqual(r.lines[0].days, 4)
        XCTAssertEqual(r.lines[1].days, 12); XCTAssertEqual(r.total, 1720)
    }
    func testLeapDaySingleDay() throws {
        var i = ArrearsInput(); i.previous = 0; i.revised = 2900
        i.start = DateUtilities.date(2024, 2, 29); i.end = i.start
        XCTAssertEqual(try ArrearsCalculationEngine().calculate(i).total, 100)
    }
    func testScheduleGapsDuplicatesAndDates() throws {
        var i = ArrearsInput(); i.periods = []
        XCTAssertThrowsError(try ArrearsCalculationEngine().calculate(i))
        i = ArrearsInput(); i.periods[0].start = DateUtilities.date(2024, 2, 1)
        XCTAssertThrowsError(try ArrearsCalculationEngine().calculate(i))
        i = ArrearsInput(); i.periods.append(i.periods[0])
        XCTAssertThrowsError(try ArrearsCalculationEngine().calculate(i))
        i = ArrearsInput(); i.end = DateUtilities.date(2023, 1, 1)
        XCTAssertThrowsError(try ArrearsCalculationEngine().calculate(i))
    }
    func testNegativeRecoveryPreserved() throws {
        var i = ArrearsInput(); i.previous = 1100; i.revised = 1000
        XCTAssertEqual(try ArrearsCalculationEngine().calculate(i).total, -1200)
    }
    func testUnsortedScheduleIsSorted() throws {
        var i = ArrearsInput(); i.previous = 1000; i.revised = 1100
        i.periods = [DRPeriod(start: DateUtilities.date(2024, 7, 1), rate: 20), DRPeriod(start: i.start, rate: 10)]
        XCTAssertEqual(try ArrearsCalculationEngine().calculate(i).total, 1380)
    }
}
