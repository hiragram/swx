public enum PackageSpecError: Error {
    case invalidFormat
}

public struct PackageSpec: Sendable {
    public let owner: String
    public let repo: String
    public let version: String?

    public var gitURL: String {
        "https://github.com/\(owner)/\(repo).git"
    }

    public static func parse(_ input: String) throws -> PackageSpec {
        // Format: owner/repo or owner/repo@version
        let parts = input.split(separator: "@", maxSplits: 1)
        let ownerRepo = String(parts[0])
        let version = parts.count > 1 ? String(parts[1]) : nil

        let ownerRepoParts = ownerRepo.split(separator: "/", maxSplits: 1)
        guard ownerRepoParts.count == 2 else {
            throw PackageSpecError.invalidFormat
        }

        return PackageSpec(
            owner: String(ownerRepoParts[0]),
            repo: String(ownerRepoParts[1]),
            version: version
        )
    }
}
