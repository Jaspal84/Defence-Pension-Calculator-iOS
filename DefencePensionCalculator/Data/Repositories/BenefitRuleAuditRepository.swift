import Foundation

struct BenefitRuleAuditRepository {
    let catalog: BenefitRuleAuditCatalog
    init(local: LocalJSONRepository = LocalJSONRepository()) throws {
        let decoded = try local.load("BenefitRuleAudit", as: BenefitRuleAuditCatalog.self)
        let ids = Set(decoded.sources.map(\.id))
        guard decoded.schemaVersion == 1, !decoded.dataVersion.isEmpty,
              decoded.enabledRuleIDs.isEmpty,
              ids.count == decoded.sources.count,
              Set(decoded.benefits.map(\.id)).count == decoded.benefits.count,
              decoded.benefits.allSatisfy({ $0.decision == "disabled" && !$0.sourceIDs.isEmpty && Set($0.sourceIDs).isSubset(of: ids) }),
              decoded.sources.allSatisfy({
                  guard let url = URL(string: $0.sourceURL) else { return false }
                  return url.scheme == "https" && url.host != nil && url.user == nil && url.password == nil
              }) else {
            throw PensionError.missingData("Invalid benefit research audit. No benefit calculator can be activated from this audit-only schema.")
        }
        catalog = decoded
    }
    func sources(for item: BenefitVerificationItem) -> [BenefitSourceAudit] {
        catalog.sources.filter { item.sourceIDs.contains($0.id) }
    }
}
