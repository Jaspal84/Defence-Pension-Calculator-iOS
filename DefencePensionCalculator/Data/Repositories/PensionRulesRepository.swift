import Foundation
protocol PensionRulesRepository {
    var ranks: [Rank] { get }
    var metadata: [PensionRuleMetadata] { get }
    func requireIllustrative(_ regime: PensionRuleRegime) throws
    func commutationFactor(age: Int) throws -> Decimal
    func orop(_ selection: OROPSelection) throws -> OROPEntry
}
struct BundledPensionRulesRepository: PensionRulesRepository {
    let ranks: [Rank]
    let metadata: [PensionRuleMetadata]
    let factors: ReferenceTable<CommutationTableLookup>
    let oropTable: ReferenceTable<OROPEntry>
    let payMatrix: ReferenceTable<PayMatrixEntry>
    init(local: LocalJSONRepository = LocalJSONRepository()) throws {
        ranks = try local.load("RankMapping", as: [Rank].self)
        metadata = try local.load("PensionRulesMetadata", as: [PensionRuleMetadata].self)
        factors = try local.load("CommutationFactors", as: ReferenceTable<CommutationTableLookup>.self)
        oropTable = try local.load("OROPReferenceTables", as: ReferenceTable<OROPEntry>.self)
        payMatrix = try local.load("PayMatrix7CPC", as: ReferenceTable<PayMatrixEntry>.self)
    }
    func requireIllustrative(_ regime: PensionRuleRegime) throws {
        guard regime == .illustrative else { throw PensionError.unsupported("Verified rules for \(regime.rawValue) are not bundled. Select illustrative assumptions to explore arithmetic.") }
    }
    func commutationFactor(age: Int) throws -> Decimal {
        guard factors.verified, let row = factors.entries.first(where: { $0.ageNextBirthday == age }), row.factor > 0 else {
            throw PensionError.missingData("Official commutation factor unavailable for this age. An explicitly supplied illustrative factor may be used.")
        }
        return row.factor
    }
    func orop(_ selection: OROPSelection) throws -> OROPEntry {
        guard oropTable.verified, let row = oropTable.entries.first(where: { $0.selection == selection }), metadata.contains(where: { $0.id == row.ruleID && $0.verified }) else {
            throw PensionError.missingData("Official OROP table data unavailable for this selection.")
        }
        return row
    }
}
