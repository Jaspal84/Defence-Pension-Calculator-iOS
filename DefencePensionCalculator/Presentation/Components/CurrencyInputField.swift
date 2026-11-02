import SwiftUI
struct CurrencyInputField: View {
    let title: String
    @Binding var value: Decimal
    var suffix = "₹"
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.subheadline).foregroundStyle(.secondary)
            HStack {
                Text(suffix).foregroundStyle(.secondary).accessibilityHidden(true)
                TextField(title, value: $value, format: .number.locale(Locale(identifier: "en_IN")))
                    .keyboardType(.decimalPad).accessibilityLabel(title)
            }
        }.padding(.vertical, 3)
    }
}
