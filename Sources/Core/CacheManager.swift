import Foundation

public struct CacheManager: Sendable {
    public let baseDirectory: String
    private let processExecutor: ProcessExecutor

    public init(baseDirectory: String? = nil) {
        self.init(
            baseDirectory: baseDirectory,
            processExecutor: .live
        )
    }

    init(baseDirectory: String? = nil, processExecutor: ProcessExecutor) {
        self.processExecutor = processExecutor
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
        let result = try processExecutor.execute(
            ProcessRequest(
                executablePath: "/usr/bin/git",
                arguments: arguments,
                currentDirectoryPath: directory,
                standardIO: .captureOutput(mergingStandardError: true)
            )
        )

        if result.terminationStatus != 0 {
            throw CacheManagerError.gitFailed(result.outputString)
        }
    }
}

public enum CacheManagerError: Error {
    case gitFailed(String)
}
