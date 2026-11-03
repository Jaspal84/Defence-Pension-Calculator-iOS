import SwiftUI
import UIKit

enum PensionTheme {
    static let navy = Color(red: 8/255, green: 43/255, blue: 80/255)
    static let royal = Color(red: 20/255, green: 90/255, blue: 158/255)
    static let gold = Color(red: 217/255, green: 164/255, blue: 65/255)
    static let saffron = Color(red: 1, green: 153/255, blue: 51/255)
    static let green = Color(red: 19/255, green: 136/255, blue: 8/255)
    static let background = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let border = Color(uiColor: .separator).opacity(0.25)
    static let tint = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(red: 0.48, green: 0.74, blue: 1, alpha: 1) : UIColor(red: 20/255, green: 90/255, blue: 158/255, alpha: 1)
    })
}
struct TricolourRibbon: View {
    var body: some View {
        HStack(spacing: 0) {
            PensionTheme.saffron
            Color.white
            PensionTheme.green
        }.frame(height: 4).accessibilityHidden(true)
    }
}
struct ProCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .background(PensionTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(PensionTheme.border, lineWidth: 0.5))
    }
}
struct ProStatusNotice: View {
    var body: some View {
        ProCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("Illustrative estimates", systemImage: "info.circle.fill").font(.subheadline.bold())
                Text("Official entitlement and reference data remain unverified. No current DR rate is assumed.").font(.footnote)
                Text(PensionNotice.disclaimer).font(.caption).foregroundStyle(.secondary)
            }
        }.accessibilityElement(children: .combine).accessibilityIdentifier("notice.illustrative")
    }
}
struct CreatorFooter: View {
    var body: some View {
        VStack(spacing: 8) {
            Label("Created by Jaspal Singh", systemImage: "person.fill").font(.subheadline.weight(.semibold))
                .padding(.horizontal, 20).padding(.vertical, 12).frame(maxWidth: .infinity)
                .background(PensionTheme.gold.opacity(0.22), in: RoundedRectangle(cornerRadius: 12))
            Text(AppBrand.independence).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }.accessibilityIdentifier("developer.footer")
    }
}
struct DefenceHorizonIllustration: View {
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .bottom) {
                Ellipse().fill(PensionTheme.royal.opacity(0.28)).frame(width: g.size.width * 1.2, height: g.size.height * 0.45).offset(y: 30)
                ServiceSilhouette().fill(Color.white.opacity(0.86)).frame(width: g.size.width * 0.5, height: g.size.height).offset(x: -g.size.width * 0.07)
                Image(systemName: "airplane").font(.system(size: 38)).rotationEffect(.degrees(-15)).foregroundStyle(PensionTheme.gold).position(x: g.size.width * 0.77, y: g.size.height * 0.3)
                Image(systemName: "ferry.fill").font(.system(size: 45)).foregroundStyle(Color.white.opacity(0.6)).position(x: g.size.width * 0.85, y: g.size.height * 0.8)
            }.clipped()
        }.accessibilityHidden(true)
    }
}
struct ServiceSilhouette: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x*r.width, y: r.minY + y*r.height) }
        p.addEllipse(in: CGRect(x: r.minX + 0.42*r.width, y: r.minY + 0.06*r.height, width: 0.23*r.width, height: 0.22*r.height))
        p.move(to: pt(0.35,0.33)); p.addQuadCurve(to: pt(0.7,0.36), control: pt(0.52,0.25))
        p.addLine(to: pt(0.83,0.82));p.addLine(to: pt(0.67,0.85));p.addLine(to: pt(0.67,1));p.addLine(to: pt(0.34,1));p.addLine(to: pt(0.3,0.56))
        p.addLine(to: pt(0.08,0.49));p.addQuadCurve(to: pt(0.06,0.4), control: pt(0.01,0.44))
        p.addLine(to: pt(0.38,0.18));p.addLine(to: pt(0.47,0.23));p.addLine(to: pt(0.22,0.43));p.addLine(to: pt(0.35,0.45));p.closeSubpath()
        return p
    }
}

struct ProNavigationBar: ViewModifier {
    func body(content: Content) -> some View {
        content.toolbarBackground(PensionTheme.navy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
extension View {
    func proNavigationBar() -> some View { modifier(ProNavigationBar()) }
}
