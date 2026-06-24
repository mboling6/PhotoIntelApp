import Foundation

enum MetadataNormalization {
    nonisolated static func dictionary(_ value: Any?) -> [String: AnyHashable] {
        guard let rawDict = value as? [String: Any] else { return [:] }

        var normalized: [String: AnyHashable] = [:]
        for (key, rawValue) in rawDict {
            normalized[key] = hashable(rawValue)
        }
        return normalized
    }

    nonisolated static func hashable(_ value: Any?) -> AnyHashable {
        guard let value else { return "" }

        if let hashable = value as? AnyHashable {
            return hashable
        }

        if let dict = value as? [String: Any] {
            return AnyHashable(displayString(dict))
        }

        if let array = value as? [Any] {
            return AnyHashable(displayString(array))
        }

        return AnyHashable(String(describing: value))
    }

    nonisolated static func displayString(_ value: Any?) -> String {
        guard let value else { return "" }

        if type(of: value) == AnyHashable.self,
           let hashable = value as? AnyHashable {
            return displayString(hashable.base)
        }

        if let dict = value as? [String: Any] {
            let entries = dict
                .sorted { $0.key < $1.key }
                .map { "\($0.key): \(displayString($0.value))" }
                .joined(separator: ", ")
            return "{\(entries)}"
        }

        if let dict = value as? [AnyHashable: Any] {
            let entries = dict
                .map { (key: String(describing: $0.key), value: $0.value) }
                .sorted { $0.key < $1.key }
                .map { "\($0.key): \(displayString($0.value))" }
                .joined(separator: ", ")
            return "{\(entries)}"
        }

        if let array = value as? [Any] {
            let elements = array
                .map(displayString)
                .joined(separator: ", ")
            return "[\(elements)]"
        }

        if let array = value as? [AnyHashable] {
            let elements = array
                .map { displayString($0.base) }
                .joined(separator: ", ")
            return "[\(elements)]"
        }

        if let data = value as? Data {
            return "\(data.count) bytes"
        }

        return String(describing: value)
    }
}
