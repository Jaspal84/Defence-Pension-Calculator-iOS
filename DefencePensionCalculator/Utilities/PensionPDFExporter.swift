import UIKit
struct PensionPDFExporter {
    static func export(_ summary: CalculationSummary, directory: URL = FileManager.default.temporaryDirectory) throws -> URL {
        let url = directory.appendingPathComponent("Pension-Calculation-\(UUID().uuidString).pdf")
        let bounds = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        let lines = ["Defence Pension Calculator", summary.title, "Calculated: " + DateUtilities.text(summary.date), summary.status.rawValue] + summary.rows.map { "\($0.title): \($0.value)" } + ["Rules: " + summary.rules.joined(separator: ", ")] + summary.assumptions + [PensionNotice.disclaimer]
        try renderer.writePDF(to: url) { context in
            var page = 0, y: CGFloat = 0
            func beginPage() {
                context.beginPage(); page += 1
                UIColor(red: 0.07, green: 0.14, blue: 0.25, alpha: 1).setFill()
                UIRectFill(CGRect(x: 0, y: 0, width: bounds.width, height: 12))
                let footer = "Defence Pension Calculator • Page \(page) • Offline estimate"
                footer.draw(at: CGPoint(x: 36, y: 810), withAttributes: [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: UIColor.darkGray])
                y = 36
            }
            beginPage()
            // Wrap and paginate by rendered lines so even long assumptions cannot overflow a page.
            for (index, paragraph) in lines.enumerated() {
                let font = index == 0 ? UIFont.boldSystemFont(ofSize: 20) : UIFont.systemFont(ofSize: 11)
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.black]
                var current = ""
                for word in paragraph.components(separatedBy: .whitespacesAndNewlines) {
                    let candidate = current.isEmpty ? word : current + " " + word
                    if (candidate as NSString).size(withAttributes: attrs).width > 523 && !current.isEmpty {
                        if y + font.lineHeight > 786 { beginPage() }
                        (current as NSString).draw(at: CGPoint(x: 36, y: y), withAttributes: attrs)
                        y += font.lineHeight + 3; current = word
                    } else { current = candidate }
                }
                if y + font.lineHeight > 786 { beginPage() }
                (current as NSString).draw(at: CGPoint(x: 36, y: y), withAttributes: attrs)
                y += font.lineHeight + 12
            }
        }
        return url
    }
}
