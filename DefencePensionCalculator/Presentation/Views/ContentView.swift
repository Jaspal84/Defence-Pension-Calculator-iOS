import SwiftUI
struct ContentView: View {
    @ObservedObject var model: PensionCalculatorViewModel
    var body: some View {
        TabView {
            NavigationStack { ServicePensionView(model: model) }
                .tabItem { Label("Calculator", systemImage: "shield.lefthalf.filled") }
            NavigationStack {
                List {
                    NavigationLink("Disability & war injury") { DisabilityPensionView(model: model) }
                    NavigationLink("Family pension") { FamilyPensionView(model: model) }
                    EstimateNotice()
                }.navigationTitle("Disability & Family")
            }.tabItem { Label("Family", systemImage: "person.2.fill") }
            NavigationStack {
                List {
                    NavigationLink("Commutation & restoration") { CommutationView(model: model) }
                    NavigationLink("Pension arrears") { ArrearsView(model: model) }
                    EstimateNotice()
                }.navigationTitle("Commutation & Arrears")
            }.tabItem { Label("Payments", systemImage: "indianrupeesign.circle") }
            NavigationStack { OROPComparisonView(model: model) }
                .tabItem { Label("OROP", systemImage: "chart.bar.xaxis") }
            NavigationStack { PensionSummaryView(model: model) }
                .tabItem { Label("Summary", systemImage: "doc.text") }
        }
        .alert("Calculation unavailable", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) {
            Button("OK") { model.error = nil }
        } message: { Text(model.error ?? "") }
    }
}
