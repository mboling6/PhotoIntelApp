import Foundation

enum MetadataDisplayFormatter {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()

    static func dateString(_ date: Date?) -> String {
        guard let date else { return "-" }
        return dateFormatter.string(from: date)
    }

    static func metadataValue(forKey key: String, value: AnyHashable) -> String {
        let normalizedKey = key.lowercased()

        if normalizedKey == "exposuretime" {
            return formatExposure(value)
        }

        if normalizedKey == "fnumber" || normalizedKey == "aperturevalue" {
            return formatAperture(value)
        }

        if normalizedKey.contains("iso") {
            return formatISO(value)
        }

        if normalizedKey == "focallength" || normalizedKey == "focallenin35mmfilm" {
            return formatMillimeters(value)
        }

        if normalizedKey == "latitude" || normalizedKey == "longitude" {
            return formatCoordinate(value)
        }

        if normalizedKey == "altitude" {
            return formatAltitude(value)
        }

        return String(describing: value)
    }

    private static func formatExposure(_ value: AnyHashable) -> String {
        guard let numeric = toDouble(value) else {
            return String(describing: value)
        }

        if numeric > 0, numeric < 1 {
            let denominator = Int((1.0 / numeric).rounded())
            return "1/\(max(1, denominator)) s"
        }

        return String(format: "%.3f s", numeric)
    }

    private static func formatAperture(_ value: AnyHashable) -> String {
        guard let numeric = toDouble(value) else {
            return String(describing: value)
        }

        return String(format: "f/%.1f", numeric)
    }

    private static func formatISO(_ value: AnyHashable) -> String {
        if let intValue = value as? Int {
            return "ISO \(intValue)"
        }

        if let numeric = toDouble(value) {
            return "ISO \(Int(numeric.rounded()))"
        }

        return String(describing: value)
    }

    private static func formatMillimeters(_ value: AnyHashable) -> String {
        guard let numeric = toDouble(value) else {
            return String(describing: value)
        }

        return String(format: "%.2f mm", numeric)
    }

    private static func formatCoordinate(_ value: AnyHashable) -> String {
        guard let numeric = toDouble(value) else {
            return String(describing: value)
        }

        return String(format: "%.6f°", numeric)
    }

    private static func formatAltitude(_ value: AnyHashable) -> String {
        guard let numeric = toDouble(value) else {
            return String(describing: value)
        }

        return String(format: "%.2f m", numeric)
    }

    private static func toDouble(_ value: AnyHashable) -> Double? {
        if let value = value as? Double { return value }
        if let value = value as? Float { return Double(value) }
        if let value = value as? Int { return Double(value) }
        if let value = value as? NSNumber { return value.doubleValue }
        if let value = value as? String { return Double(value) }
        return nil
    }
}
