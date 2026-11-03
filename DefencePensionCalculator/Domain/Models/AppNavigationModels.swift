import Foundation

enum AppTab: String, CaseIterable, Identifiable, Sendable {
    case home = "Home", calculators = "Calculators", reports = "Reports", references = "References", settings = "Settings"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .home: return "house.fill"
        case .calculators: return "square.grid.2x2"
        case .reports: return "doc.text"
        case .references: return "book.closed"
        case .settings: return "gearshape"
        }
    }
}
enum CalculatorRoute: String, CaseIterable, Identifiable, Hashable, Sendable {
    case pension, orop, commutation, gratuity, disability, family, arrears, leaveEncashment, sevaNidhi, npsUPS
    var id: String { rawValue }
    var title: String {
        switch self {
        case .pension: return "Pension Calculator"
        case .orop: return "OROP Calculator"
        case .commutation: return "Commutation"
        case .gratuity: return "Gratuity"
        case .disability: return "Disability Pension"
        case .family: return "Family Pension"
        case .arrears: return "Arrears Calculator"
        case .leaveEncashment: return "Leave Encashment"
        case .sevaNidhi: return "Agniveer Seva Nidhi"
        case .npsUPS: return "NPS / UPS Estimator"
        }
    }
    var symbol: String {
        switch self {
        case .pension: return "function"
        case .orop: return "chart.bar.fill"
        case .commutation: return "indianrupeesign.circle.fill"
        case .gratuity: return "gift.fill"
        case .disability: return "figure.roll"
        case .family: return "person.2.fill"
        case .arrears: return "calendar"
        case .leaveEncashment: return "calendar.badge.clock"
        case .sevaNidhi: return "shield.lefthalf.filled"
        case .npsUPS: return "leaf.fill"
        }
    }
    var implemented: Bool { [.pension, .orop, .commutation, .disability, .family, .arrears].contains(self) }
    var availability: String {
        if self == .orop { return "Official data unavailable" }
        return implemented ? "Illustrative estimate" : "Verified rules required"
    }
    var unavailableReason: String {
        switch self {
        case .gratuity: return "Gratuity rules, emolument definitions, qualifying-service rounding and applicable ceilings have not been verified or implemented in this release."
        case .leaveEncashment: return "Leave encashment needs verified eligibility, authorized leave balance, pay components and applicable ceilings. These rules are not bundled."
        case .sevaNidhi: return "Agniveer Seva Nidhi requires verified scheme eligibility, contributions, government matching and applicable interest rules. These data are not bundled."
        case .npsUPS: return "NPS and UPS are distinct schemes with eligibility-specific rules. The app does not establish eligibility or assume that a scheme applies to armed forces personnel. No verified estimator is available."
        default: return "Use the dedicated calculator. Unverified rules are never presented as official entitlements."
        }
    }
    var accessibilityID: String { "calculator.\(rawValue)" }
}
enum AppBrand {
    static let name = "Defence Pension Calculator Pro – India"
    static let developer = "Jaspal Singh"
    static let subtitle = "Pension • OROP • Commutation • Gratuity • Family Pension • Arrears"
    static let developerDescription = "Designed and developed by Jaspal Singh to help Indian defence personnel, veterans and their families understand and estimate pension, OROP, commutation, gratuity, family pension and other applicable benefits."
    static let independence = "Independent application. Not affiliated with or endorsed by the Government of India, Ministry of Defence, PCDA or SPARSH."
    static let reportDisclaimer = "Important: This is an illustrative estimate based on the information provided and applicable verified rules. It is not an official pension entitlement."
    static let copyright = "© 2026 Jaspal Singh. All rights reserved."
    static func version(info: [String: Any]? = Bundle.main.infoDictionary) -> String {
        guard let version = info?["CFBundleShortVersionString"] as? String, !version.isEmpty else { return "Version unavailable" }
        if let build = info?["CFBundleVersion"] as? String, !build.isEmpty { return "Version \(version) (\(build))" }
        return "Version \(version)"
    }
    static func contact(info: [String: Any]? = Bundle.main.infoDictionary) -> URL? {
        guard let address = info?["DeveloperContactEmail"] as? String,
              !address.contains(" "), address.contains("@"), !address.contains("\n"),
              let url = URL(string: "mailto:" + address), url.scheme == "mailto" else { return nil }
        return url
    }
    static func website(info: [String: Any]? = Bundle.main.infoDictionary) -> URL? {
        guard let value = info?["DeveloperWebsiteURL"] as? String, let url = URL(string: value),
              url.scheme == "https", url.host != nil, url.user == nil, url.password == nil else { return nil }
        return url
    }
}
