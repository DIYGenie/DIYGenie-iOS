import Foundation

extension Project {
    func idAsUUID() -> UUID? {
        return UUID(uuidString: self.id ?? "")
    }
}
