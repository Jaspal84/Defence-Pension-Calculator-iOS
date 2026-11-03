import UIKit

struct PensionPDFExporter {
    private static let navy = UIColor(red: 8/255, green: 43/255, blue: 80/255, alpha: 1)
    private static let gold = UIColor(red: 217/255, green: 164/255, blue: 65/255, alpha: 1)
    static func export(_ summary: CalculationSummary, directory: URL = FileManager.default.temporaryDirectory) throws -> URL {
        let url = directory.appendingPathComponent("Pension-Pro-Report-\(UUID().uuidString).pdf")
        let bounds = CGRect(x: 0, y: 0, width: 595, height: 842)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [kCGPDFContextTitle as String: AppBrand.name + " — Pension Calculation Report",
                               kCGPDFContextAuthor as String: AppBrand.developer,
                               kCGPDFContextSubject as String: "Illustrative estimate. Not an official pension entitlement."]
        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)
        try renderer.writePDF(to: url) { context in
            var page = 0
            var y: CGFloat = 0
            let margin: CGFloat = 36
            let contentWidth: CGFloat = 523
            let bottom: CGFloat = 773
            let bodyFont = UIFont.systemFont(ofSize: 10.5)
            func draw(_ value: String, x: CGFloat, at top: CGFloat, font: UIFont = .systemFont(ofSize: 10.5), color: UIColor = .black) {
                (value as NSString).draw(at: CGPoint(x: x, y: top), withAttributes: [.font: font, .foregroundColor: color])
            }
            func beginPage() {
                context.beginPage(); page += 1
                navy.setFill(); UIRectFill(CGRect(x: 0, y: 0, width: 595, height: 107))
                let thirds: [(UIColor, CGFloat)] = [(.init(red: 1, green: 0.6, blue: 0.2, alpha: 1), 0), (.white, 1), (.init(red: 0.075, green: 0.53, blue: 0.03, alpha: 1), 2)]
                for (color, index) in thirds { color.setFill(); UIRectFill(CGRect(x: index * 595/3, y: 107, width: 595/3, height: 4)) }
                draw("Defence Pension Calculator Pro", x: margin, at: 23, font: .boldSystemFont(ofSize: 20), color: .white)
                draw("India  •  Pension Calculation Report", x: margin, at: 51, font: .systemFont(ofSize: 12), color: .white)
                draw("Developed by Jaspal Singh", x: margin, at: 76, font: .systemFont(ofSize: 10), color: gold)
                draw("Generated: " + DateUtilities.text(Date()), x: margin, at: 790, font: .systemFont(ofSize: 8), color: .darkGray)
                draw("Page \(page)  |  © 2026 Jaspal Singh", x: 359, at: 790, font: .systemFont(ofSize: 8), color: .darkGray)
                y = 128
            }
            func ensure(_ height: CGFloat) { if y + height > bottom { beginPage() } }
            // Character-aware wrapping protects against a long URL or unbroken user text overflowing a page.
            func wrapped(_ paragraph: String, font: UIFont, width: CGFloat) -> [String] {
                var result: [String] = [], current = ""
                for character in paragraph {
                    if character == "\n" { result.append(current); current = ""; continue }
                    let candidate = current + String(character)
                    if !current.isEmpty && (candidate as NSString).size(withAttributes: [.font: font]).width > width {
                        // Prefer a word boundary, retaining any remainder for the next line.
                        if let split = current.lastIndex(of: " "), split != current.startIndex {
                            result.append(String(current[..<split]))
                            current = String(current[current.index(after: split)...]) + String(character)
                        } else { result.append(current); current = String(character) }
                    } else { current = candidate }
                }
                if !current.isEmpty { result.append(current) }
                return result.isEmpty ? [""] : result
            }
            func paragraph(_ text: String, font: UIFont = .systemFont(ofSize: 10.5), color: UIColor = .black) {
                for line in wrapped(text, font: font, width: contentWidth) {
                    ensure(font.lineHeight + 4); draw(line, x: margin, at: y, font: font, color: color); y += font.lineHeight + 4
                }
                y += 8
            }
            func section(_ title: String) {
                ensure(52)
                navy.setFill(); UIRectFill(CGRect(x: margin, y: y, width: contentWidth, height: 25))
                draw(title, x: margin + 10, at: y + 5, font: .boldSystemFont(ofSize: 11), color: .white)
                y += 34
            }
            beginPage()
            paragraph(AppBrand.name, font: .boldSystemFont(ofSize: 15), color: navy)
            paragraph(summary.title + " • " + summary.status.rawValue, font: .boldSystemFont(ofSize: 12), color: navy)
            paragraph("Calculation date: " + DateUtilities.text(summary.date))
            paragraph(AppBrand.reportDisclaimer, font: .boldSystemFont(ofSize: 10.5), color: UIColor(red: 0.58, green: 0.15, blue: 0.12, alpha: 1))
            section("Calculation inputs & pension estimate")
            for (index, row) in summary.rows.enumerated() {
                let labelFont = UIFont.systemFont(ofSize: 9.5, weight: .medium)
                let labelLines = wrapped(row.title, font: labelFont, width: 183)
                let valueLines = wrapped(row.value, font: bodyFont, width: 298)
                let lineHeight: CGFloat = max(labelFont.lineHeight, bodyFont.lineHeight) + 4
                let lineCount = max(labelLines.count, valueLines.count)
                var lineIndex = 0
                while lineIndex < lineCount {
                    ensure(lineHeight + 13)
                    let capacity = max(1, Int((bottom - y - 12) / lineHeight))
                    let count = min(capacity, lineCount - lineIndex)
                    let height = CGFloat(count) * lineHeight + 12
                    (index.isMultiple(of: 2) ? UIColor(white: 0.95, alpha: 1) : .white).setFill()
                    UIRectFill(CGRect(x: margin, y: y, width: contentWidth, height: height))
                    for offset in 0..<count {
                        let at = y + 6 + CGFloat(offset) * lineHeight
                        if lineIndex + offset < labelLines.count { draw(labelLines[lineIndex + offset], x: margin + 8, at: at, font: labelFont, color: navy) }
                        if lineIndex + offset < valueLines.count { draw(valueLines[lineIndex + offset], x: margin + 207, at: at, font: bodyFont) }
                    }
                    y += height; lineIndex += count
                }
            }
            y += 16
            section("Applied assumptions & limitations")
            paragraph("Applied rule version / identifiers: " + summary.rules.joined(separator: ", "))
            for assumption in summary.assumptions { paragraph(assumption) }
            section("Source references")
            for reference in summary.sourceReferences { paragraph(reference) }
            section("Important information")
            paragraph(AppBrand.reportDisclaimer, font: .boldSystemFont(ofSize: 10.5))
            for sentence in PensionNotice.disclaimer.components(separatedBy: ". ") {
                paragraph(sentence.hasSuffix(".") ? sentence : sentence + ".")
            }
            paragraph(AppBrand.independence)
            paragraph(AppBrand.copyright, font: .systemFont(ofSize: 9), color: .darkGray)
        }
        return url
    }
}
