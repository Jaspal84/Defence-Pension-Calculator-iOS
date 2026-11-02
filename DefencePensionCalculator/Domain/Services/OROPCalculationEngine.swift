import Foundation
struct OROPCalculationEngine {
    let rules: any PensionRulesRepository
    func lookup(_ selection: OROPSelection) throws -> OROPEntry {
        guard (0...120).contains(selection.serviceHalfYears), !selection.cohort.isEmpty, !selection.revisionDate.isEmpty else { throw PensionError.invalid("Complete the OROP selection.") }
        return try rules.orop(selection)
    }
}
