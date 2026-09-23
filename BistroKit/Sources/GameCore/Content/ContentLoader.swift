import Foundation

public enum ContentLoadError: Error, CustomStringConvertible {
    case missingFile(String)
    case invalidJSON(file: String, underlying: any Error)
    case unsupportedSchema(file: String, found: Int, supported: Int)

    public var description: String {
        switch self {
        case .missingFile(let file):
            return "Content file not found: \(file)"
        case .invalidJSON(let file, let error):
            return "Invalid JSON in \(file): \(error)"
        case .unsupportedSchema(let file, let found, let supported):
            return "\(file) has schemaVersion \(found), this build supports up to \(supported)"
        }
    }
}

/// Reads the JSON content files from a directory.
public enum ContentLoader {
    public static let supportedSchemaVersion = 1

    public enum FileName {
        public static let ingredients = "ingredients.json"
        public static let stations = "stations.json"
        public static let recipes = "recipes.json"
        public static let regulars = "regulars.json"
        public static let zones = "zones.json"
        public static let decorations = "decorations.json"
    }

    public static func load(from directory: URL) throws -> GameContent {
        GameContent(
            ingredients: try items(FileName.ingredients, in: directory),
            stations: try items(FileName.stations, in: directory),
            recipes: try items(FileName.recipes, in: directory),
            regulars: try items(FileName.regulars, in: directory),
            zones: try items(FileName.zones, in: directory),
            decorations: try items(FileName.decorations, in: directory)
        )
    }

    static func items<T: Codable & Sendable>(_ file: String, in directory: URL) throws -> [T] {
        let decoded: ContentFile<T> = try JSONFile.decode(file, in: directory)
        guard decoded.schemaVersion <= supportedSchemaVersion else {
            throw ContentLoadError.unsupportedSchema(
                file: file, found: decoded.schemaVersion, supported: supportedSchemaVersion)
        }
        return decoded.items
    }
}

enum JSONFile {
    static func decode<T: Decodable>(_ file: String, in directory: URL) throws -> T {
        let url = directory.appendingPathComponent(file)
        guard let data = try? Data(contentsOf: url) else {
            throw ContentLoadError.missingFile(file)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw ContentLoadError.invalidJSON(file: file, underlying: error)
        }
    }
}
