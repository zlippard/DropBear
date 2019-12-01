import Foundation

public class Generator {
    enum Error: Swift.Error {
        case pathMustBeFile
    }

    // MARK: - Private Properties
    private let data: [String : [(identifier: String, rawValue: String)]] // Class, Sanitized ID, Raw ID

    // MARK: - Lifecycle
    public init(identifiers: [AccessibilityIdentifierPair]) {
        self.data = identifiers.grouped(key: { $0.parent }, value: { ($0.identifier.sanitized(), $0.identifier) })
    }

    // MARK: - Public Functions
    public func generate(path: Path) throws {
        guard !path.exists || path.isFile else {
            throw Error.pathMustBeFile
        }

        try path.write(outputString())
    }

    // MARK: - Private Functions
    private func outputString() -> String {
        let sortedData = data.sorted(by: { $0.key < $1.key })

        let output = """
            // swiftlint:disable all
            // Generated using DropBearGen

            enum AccessibilityIdentifiers {
            {{content}}
            }
            """

        let enums = sortedData.compactMap { className, identifiers -> String? in
            guard !identifiers.isEmpty else { return nil }

            let output = """
            \tstruct \(className): RawRepresentable {
            \t\tlet rawValue: String
            {{content}}
            \t}
            """

            let sortedIdentifiers = identifiers.sorted(by: { $0.rawValue < $1.rawValue })

            let cases = sortedIdentifiers.map { identifier in
                return "\t\tstatic let \(identifier.identifier) = \(className)(rawValue: \"\(identifier.rawValue)\")"
            }

            return output.replacingOccurrences(of: "{{content}}", with: cases.joined(separator: "\n"))
        }

        return output.replacingOccurrences(of: "{{content}}", with: enums.joined(separator: "\n"))
    }
}
