import Foundation
struct ArrearsCalculationEngine {
    func calculate(_ input: ArrearsInput) throws -> ArrearsCalculationResult {
        try PensionInputValidator.amount(input.previous, "Previous pension")
        try PensionInputValidator.amount(input.revised, "Revised pension")
        try PensionInputValidator.amount(input.previouslyPaid, "Previously paid arrears")
        let cal = DateUtilities.calendar
        let start = cal.startOfDay(for: input.start), end = cal.startOfDay(for: input.end)
        guard start <= end, (cal.dateComponents([.day], from: start, to: end).day ?? Int.max) <= 36525 else { throw PensionError.invalid("Arrears dates must be ordered and span at most 100 years.") }
        let periods = input.periods.sorted { $0.start < $1.start }
        guard !periods.isEmpty, cal.startOfDay(for: periods[0].start) <= start else { throw PensionError.invalid("DR schedule must cover the first arrears day.") }
        let normalized = periods.map { cal.startOfDay(for: $0.start) }
        guard Set(normalized).count == periods.count else { throw PensionError.invalid("DR change dates must be unique.") }
        for p in periods { try PensionInputValidator.percent(p.rate, "DR rate") }
        var lines: [ArrearsLine] = [], cursor = start
        while cursor <= end {
            let month = cal.dateInterval(of: .month, for: cursor)!
            let monthLast = cal.date(byAdding: .day, value: -1, to: month.end)!
            let currentIndex = normalized.lastIndex(where: { $0 <= cursor })!
            var segmentEnd = min(monthLast, end)
            if currentIndex + 1 < periods.count {
                let nextLast = cal.date(byAdding: .day, value: -1, to: normalized[currentIndex + 1])!
                segmentEnd = min(segmentEnd, nextLast)
            }
            let days = cal.dateComponents([.day], from: cursor, to: segmentEnd).day! + 1
            let monthDays = cal.range(of: .day, in: .month, for: cursor)!.count
            let rawBasic = (input.revised - input.previous) * Decimal(days) / Decimal(monthDays)
            let basic = Money.round(rawBasic)
            let relief = Money.round(rawBasic * periods[currentIndex].rate / 100)
            lines.append(ArrearsLine(start: cursor, end: segmentEnd, days: days, daysInMonth: monthDays, drRate: periods[currentIndex].rate, basicDifference: basic, drDifference: relief))
            cursor = cal.date(byAdding: .day, value: 1, to: segmentEnd)!
        }
        let gross = lines.reduce(Decimal(0)) { $0 + $1.total }
        return ArrearsCalculationResult(lines: lines, gross: gross, previouslyPaid: input.previouslyPaid, total: gross - input.previouslyPaid, status: .illustrative, assumptions: ["Inclusive dates in India time. Calendar-day proration; paise half-up per period component. DR uses revised minus previous basic. Negative totals indicate a potential recovery, not a payment. No interest, tax or changing commutation adjustments."])
    }
}
