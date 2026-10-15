import Foundation

/// Loads the hardcoded instrument list bundled with the app.
/// `constituents.json` is the single source of truth for symbols, display
/// names, and group membership -- editable without touching Swift code.
enum Constituents {
    enum LoadError: Error {
        case resourceMissing
    }

    static func load(bundle: Bundle = .module) throws -> [Instrument] {
        guard let url = bundle.url(forResource: "constituents", withExtension: "json") else {
            throw LoadError.resourceMissing
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([Instrument].self, from: data).filter(\.enabled)
    }
}
