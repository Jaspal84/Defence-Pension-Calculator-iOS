import SwiftUI
@main struct DefencePensionCalculatorApp: App {
    @StateObject private var model = PensionCalculatorViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .tint(Color(red: 0.18, green: 0.38, blue: 0.62))
                .environment(\.locale, Locale(identifier: "en_IN"))
                .environment(\.calendar, DateUtilities.calendar)
                .environment(\.timeZone, DateUtilities.calendar.timeZone)
        }
    }
}
