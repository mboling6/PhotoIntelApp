import Foundation

enum MetadataNormalization {
    static func dictionary(_ value: Any?) -> [String: AnyHashable] {
        guard let rawDict = value as? [String: Any] else { return [:] }

        var normalized: [String: AnyHashable] = [:]
        for (key, rawValue) in rawDict {
            normalized[key] = hashable(rawValue)
        }
        return normalized
    }

    static func hashable(_ value: Any?) -> AnyHashable {
        guard let value else { return "" }

        if let hashable = value as? AnyHashable {
            return hashable
        }

        if let dict = value as? [String: Any] {
            let stableString = dict
                .sorted { $0.key < $1.key }
                .map { "\($0.key)=\(hashable($0.value))" }
                .joined(separator: ";")
            return AnyHashable(stableString)
        }

        if let array = value as? [Any] {
            let stableString = array
                .map { "\(hashable($0))" }
                .joined(separator: ",")
            return AnyHashable("[\(stableString)]")
        }

        return AnyHashable(String(describing: value))
    }
}
