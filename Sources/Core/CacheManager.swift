import Foundation

public struct CacheManager: Sendable {
    public let baseDirectory: String

    public init(baseDirectory: String? = nil) {
        if let baseDirectory {
            self.baseDirectory = baseDirectory
        } else {
            let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
            self.baseDirectory = "\(homeDir)/.swx/cache"
        }
    }

    public func cachePath(for spec: PackageSpec) -> String {
        let version = spec.version ?? "HEAD"
        return "\(baseDirectory)/\(spec.owner)/\(spec.repo)/\(version)"
    }

    public func ensureRepository(for spec: PackageSpec) throws -> String {
        let path = cachePath(for: spec)
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: path) {
            // Already cloned, fetch and checkout
            try runGit(["fetch", "--all"], in: path)
            let ref = spec.version ?? "origin/HEAD"
            try runGit(["checkout", ref], in: path)
        } else {
            // Clone
            try fileManager.createDirectory(
                atPath: (path as NSString).deletingLastPathComponent,
                withIntermediateDirectories: true
            )
            try runGit(["clone", spec.gitURL, path], in: nil)
            if let version = spec.version {
                try runGit(["checkout", version], in: path)
            }
        }

        return path
    }

    private func runGit(_ arguments: [String], in directory: String?) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        if let directory {
            process.currentDirectoryURL = URL(fileURLWithPath: directory)
        }

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            throw CacheManagerError.gitFailed(output)
        }
    }
}

public enum CacheManagerError: Error {
    case gitFailed(String)
}
