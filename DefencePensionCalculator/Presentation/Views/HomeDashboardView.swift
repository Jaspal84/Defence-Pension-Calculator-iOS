import SwiftUI
struct HomeDashboardView: View {
    @ObservedObject var model: PensionCalculatorViewModel
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 240 : (sizeClass == .regular ? 200 : 102)), spacing: 12)]
    }
    private var primaryColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: typeSize.isAccessibilitySize ? 1 : 2)
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("DEFENCE PENSION").font(.caption.weight(.semibold)).tracking(2).foregroundStyle(PensionTheme.gold)
                    Text("Plan your next chapter.").font(.system(.largeTitle, design: .serif).bold()).foregroundStyle(.white)
                    Text("Pension clarity for those who served, and the families beside them.").font(.subheadline).foregroundStyle(Color.white.opacity(0.88))
                    TricolourRibbon().padding(.top, 8)
                }.padding(22).frame(maxWidth: .infinity, alignment: .leading)
                    .background(LinearGradient(colors: [PensionTheme.navy, PensionTheme.royal], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 20))
                BranchSelectionCards(model: model)
                HStack { Text("Your calculators").font(.title2.bold()); Spacer(); Text("Offline • No login").font(.caption).foregroundStyle(.secondary) }
                LazyVGrid(columns: primaryColumns, spacing: 12) {
                    ForEach(Array(CalculatorRoute.allCases.prefix(2))) { route in
                        NavigationLink(value: route) { CalculatorNavigationCard(route: route) }
                            .buttonStyle(.plain).accessibilityIdentifier(route.accessibilityID)
                    }
                }
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(CalculatorRoute.allCases.dropFirst(2))) { route in
                        NavigationLink(value: route) { CalculatorNavigationCard(route: route) }
                            .buttonStyle(.plain).accessibilityIdentifier(route.accessibilityID)
                    }
                }
                ProStatusNotice()
                CreatorFooter()
            }.padding(18).frame(maxWidth: 1000).frame(maxWidth: .infinity)
        }.background(PensionTheme.background).navigationTitle("Defence Pension Pro").navigationBarTitleDisplayMode(.inline)
            .accessibilityIdentifier("screen.home")
    }
}
struct BranchSelectionCards: View {
    @ObservedObject var model: PensionCalculatorViewModel
    @Environment(\.dynamicTypeSize) private var typeSize
    private func symbol(_ branch: ArmedForceBranch) -> String { branch == .army ? "shield.lefthalf.filled" : (branch == .navy ? "ferry.fill" : "airplane") }
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: typeSize.isAccessibilitySize ? 1 : 3), spacing: 10) {
            ForEach(ArmedForceBranch.allCases) { branch in
                Button {
                    model.input.branch = branch; model.normalizeRank()
                } label: {
                    VStack(spacing: 9) {
                        Image(systemName: symbol(branch)).font(.title2).accessibilityHidden(true)
                        Text("Indian " + branch.rawValue).font(.caption.bold()).multilineTextAlignment(.center)
                        if model.input.branch == branch { Image(systemName: "checkmark.circle.fill").font(.caption).accessibilityHidden(true) }
                    }.frame(maxWidth: .infinity, minHeight: 88).padding(10)
                        .foregroundStyle(model.input.branch == branch ? Color.white : Color.primary)
                        .background(model.input.branch == branch ? PensionTheme.navy : PensionTheme.surface, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(model.input.branch == branch ? PensionTheme.gold : PensionTheme.border, lineWidth: model.input.branch == branch ? 2 : 0.5))
                }.buttonStyle(.plain).accessibilityLabel("Indian " + branch.rawValue)
                    .accessibilityAddTraits(model.input.branch == branch ? [.isSelected] : [])
                    .accessibilityIdentifier("branch.\(branch.id)")
            }
        }
    }
}
struct CalculatorNavigationCard: View {
    let route: CalculatorRoute
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: route.symbol).font(.system(size: 27, weight: .semibold)).foregroundStyle(route.implemented ? PensionTheme.tint : Color.secondary).accessibilityHidden(true)
            Text(route.title).font(.subheadline.bold()).foregroundStyle(.primary).fixedSize(horizontal: false, vertical: true)
            Text(route.availability).font(.caption2).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }.frame(maxWidth: .infinity, minHeight: 124, alignment: .topLeading).padding(16)
            .background(PensionTheme.surface, in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(PensionTheme.border, lineWidth: 0.5))
            .accessibilityElement(children: .combine)
    }
}
struct CalculatorDirectoryView: View {
    var body: some View {
        List {
            Section("Pension & benefits") {
                ForEach(CalculatorRoute.allCases) { route in
                    NavigationLink(value: route) {
                        Label {
                            VStack(alignment: .leading, spacing: 3) { Text(route.title); Text(route.availability).font(.caption).foregroundStyle(.secondary) }
                        } icon: { Image(systemName: route.symbol).foregroundStyle(PensionTheme.tint) }
                    }.accessibilityIdentifier("directory.\(route.id)")
                }
            }
            Section { Text(PensionNotice.disclaimer).font(.caption) }
        }.navigationTitle("Calculators").accessibilityIdentifier("screen.calculators")
    }
}
struct UnavailableCalculatorView: View {
    let route: CalculatorRoute
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Image(systemName: route.symbol).font(.largeTitle).foregroundStyle(PensionTheme.tint).accessibilityHidden(true)
                Text("Calculation unavailable").font(.title.bold())
                Text(route.unavailableReason)
                ProStatusNotice()
                Text("This feature will only be activated after its applicable rules and reference data are verified. No estimated entitlement is generated here.").font(.footnote).foregroundStyle(.secondary)
            }.padding(24).frame(maxWidth: 700).frame(maxWidth: .infinity)
        }.background(PensionTheme.background).navigationTitle(route.title).navigationBarTitleDisplayMode(.inline)
            .accessibilityIdentifier("unavailable.\(route.id)")
    }
}
