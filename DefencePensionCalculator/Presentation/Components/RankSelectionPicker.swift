import SwiftUI
struct RankSelectionPicker: View {
    @ObservedObject var model: PensionCalculatorViewModel
    var body: some View {
        Picker("Rank", selection: $model.input.rankID) {
            ForEach(model.ranks) { rank in Text(rank.name).tag(rank.id) }
        }
    }
}
