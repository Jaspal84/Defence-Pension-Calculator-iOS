import SwiftUI
struct ContentView: View {
    @ObservedObject var model: PensionCalculatorViewModel
    @State private var selectedTab: AppTab = .home
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeDashboardView(model: model).proNavigationBar().navigationDestination(for: CalculatorRoute.self) { destination($0).proNavigationBar() }
            }.tabItem { Label(AppTab.home.rawValue, systemImage: AppTab.home.symbol) }.tag(AppTab.home)
            NavigationStack {
                CalculatorDirectoryView().proNavigationBar().navigationDestination(for: CalculatorRoute.self) { destination($0).proNavigationBar() }
            }.tabItem { Label(AppTab.calculators.rawValue, systemImage: AppTab.calculators.symbol) }.tag(AppTab.calculators)
            NavigationStack { PensionSummaryView(model: model).proNavigationBar() }
                .tabItem { Label(AppTab.reports.rawValue, systemImage: AppTab.reports.symbol) }.tag(AppTab.reports)
            NavigationStack { ReferencesView(model: model).proNavigationBar() }
                .tabItem { Label(AppTab.references.rawValue, systemImage: AppTab.references.symbol) }.tag(AppTab.references)
            NavigationStack { SettingsView(model: model).proNavigationBar() }
                .tabItem { Label(AppTab.settings.rawValue, systemImage: AppTab.settings.symbol) }.tag(AppTab.settings)
        }.tint(PensionTheme.tint)
        .alert("Calculation unavailable", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) {
            Button("OK") { model.error = nil }
        } message: { Text(model.error ?? "") }
    }
    @ViewBuilder private func destination(_ route: CalculatorRoute) -> some View {
        switch route {
        case .pension: ServicePensionView(model: model)
        case .orop: OROPComparisonView(model: model)
        case .commutation: CommutationView(model: model)
        case .disability: DisabilityPensionView(model: model)
        case .family: FamilyPensionView(model: model)
        case .arrears: ArrearsView(model: model)
        case .gratuity, .leaveEncashment, .sevaNidhi, .npsUPS: UnavailableCalculatorView(route: route)
        }
    }
}
