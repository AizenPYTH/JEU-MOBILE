import Foundation

public enum CaseLoadError: Error, CustomStringConvertible, Equatable {
    case missingFile(String)
    case invalidJSON(file: String, reason: String)
    case unsupportedSchema(file: String, found: Int, supported: Int)

    public var description: String {
        switch self {
        case .missingFile(let file): "File not found: \(file)"
        case .invalidJSON(let file, let reason): "Invalid JSON in \(file): \(reason)"
        case .unsupportedSchema(let file, let found, let supported):
            "\(file) has schemaVersion \(found), this build supports up to \(supported)"
        }
    }
}

/// Reads cases and rules from JSON.
public enum CaseLoader {
    public static let supportedCaseSchema = 1
    public static let supportedRulesSchema = 1

    public static func loadCase(_ data: Data, name: String) throws -> CaseFile {
        let file: CaseFile = try decode(data, name: name)
        guard file.schemaVersion <= supportedCaseSchema else {
            throw CaseLoadError.unsupportedSchema(file: name, found: file.schemaVersion, supported: supportedCaseSchema)
        }
        return file
    }

    public static func loadRules(_ data: Data, name: String = "rules.json") throws -> GameRules {
        let rules: GameRules = try decode(data, name: name)
        guard rules.schemaVersion <= supportedRulesSchema else {
            throw CaseLoadError.unsupportedSchema(file: name, found: rules.schemaVersion, supported: supportedRulesSchema)
        }
        return rules
    }

    /// Loads every `*.json` case of a directory, sorted by case number.
    public static func loadCases(in directory: URL) throws -> [CaseFile] {
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
        return try files.map { url in
            guard let data = try? Data(contentsOf: url) else { throw CaseLoadError.missingFile(url.lastPathComponent) }
            return try loadCase(data, name: url.lastPathComponent)
        }
        .sorted { $0.number < $1.number }
    }

    static func decode<T: Decodable>(_ data: Data, name: String) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch let DecodingError.dataCorrupted(context) {
            throw CaseLoadError.invalidJSON(file: name, reason: describe(context))
        } catch let DecodingError.keyNotFound(key, context) {
            throw CaseLoadError.invalidJSON(file: name, reason: "missing '\(key.stringValue)' at \(path(context))")
        } catch let DecodingError.typeMismatch(_, context), let DecodingError.valueNotFound(_, context) {
            throw CaseLoadError.invalidJSON(file: name, reason: describe(context))
        } catch {
            throw CaseLoadError.invalidJSON(file: name, reason: String(describing: error))
        }
    }

    private static func path(_ context: DecodingError.Context) -> String {
        context.codingPath.map { $0.intValue.map(String.init) ?? $0.stringValue }.joined(separator: ".")
    }

    private static func describe(_ context: DecodingError.Context) -> String {
        "\(context.debugDescription) at \(path(context))"
    }
}
