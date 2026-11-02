import Foundation
struct Rank: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let branch: ArmedForceBranch
    let category: RankCategory
    let name: String
}
