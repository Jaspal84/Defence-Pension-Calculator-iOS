import SwiftUI
@main struct DefencePensionCalculatorApp: App {
    @StateObject private var model = PensionCalculatorViewModel()
    @AppStorage("showWelcomeOnLaunch") private var showWelcomeOnLaunch = true
    @State private var welcomeDismissed = false
    var body: some Scene {
        WindowGroup {
            Group {
                if showWelcomeOnLaunch && !welcomeDismissed {
                    WelcomeView { welcomeDismissed = true }
                } else {
                    ContentView(model: model)
                }
            }
            .tint(PensionTheme.tint)
            .environment(\.locale, Locale(identifier: "en_IN"))
            .environment(\.calendar, DateUtilities.calendar)
            .environment(\.timeZone, DateUtilities.calendar.timeZone)
        }
    }
}
