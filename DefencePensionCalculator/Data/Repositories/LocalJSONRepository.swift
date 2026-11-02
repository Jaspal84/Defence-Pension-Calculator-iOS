import Foundation
struct ReferenceTable<T: Codable & Sendable>: Codable, Sendable {
    let dataVersion: String
    let verified: Bool
    let note: String
    let entries: [T]
}
struct LocalJSONRepository {
    let bundle: Bundle
    init(bundle: Bundle? = nil) {
        #if SWIFT_PACKAGE
        self.bundle = bundle ?? .module
        #else
        self.bundle = bundle ?? .main
        #endif
    }
    func load<T: Decodable>(_ name: String, as type: T.Type) throws -> T {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw PensionError.missingData("Missing bundled resource: \(name).json")
        }
        do { return try JSONDecoder().decode(type, from: Data(contentsOf: url)) }
        catch { throw PensionError.missingData("Invalid bundled resource \(name): \(error.localizedDescription)") }
    }
}
struct PayMatrixEntry: Codable, Sendable { let level: String; let cell: Int; let pay: Decimal }
