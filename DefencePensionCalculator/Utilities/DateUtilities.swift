import Foundation
enum DateUtilities {
    static var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        c.locale = Locale(identifier: "en_IN")
        return c
    }
    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
    static func text(_ date: Date) -> String {
        let f = DateFormatter(); f.calendar = calendar; f.timeZone = calendar.timeZone
        f.locale = Locale(identifier: "en_IN"); f.dateStyle = .medium
        return f.string(from: date)
    }
}
