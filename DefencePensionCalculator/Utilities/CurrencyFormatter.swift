import Foundation
enum Money {
    // Illustrative calculations round half up to paise at displayed component boundaries.
    static func round(_ value: Decimal, scale: Int = 2) -> Decimal {
        var source = value, result = Decimal()
        NSDecimalRound(&result, &source, scale, .plain)
        return result
    }
    static func format(_ value: Decimal) -> String {
        let f = NumberFormatter(); f.locale = Locale(identifier: "en_IN")
        f.numberStyle = .currency; f.currencyCode = "INR"
        f.usesGroupingSeparator = true; f.groupingSize = 3; f.secondaryGroupingSize = 2
        f.minimumFractionDigits = 2; f.maximumFractionDigits = 2
        return f.string(from: NSDecimalNumber(decimal: value)) ?? "₹\(value)"
    }
    static func decimal(_ value: Double) throws -> Decimal {
        guard value.isFinite, let d = Decimal(string: String(value), locale: Locale(identifier: "en_US_POSIX")) else {
            throw PensionError.invalid("Enter a finite number.")
        }
        return d
    }
}
