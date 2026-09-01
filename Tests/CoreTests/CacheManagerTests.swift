import Foundation
import Testing
@testable import Core

struct CacheManagerTests {
    @Test func cachePath() throws {
        let spec = try PackageSpec.parse("apple/swift-format")
        let manager = CacheManager(baseDirectory: "/tmp/swx-test")
        let path = manager.cachePath(for: spec)
        #expect(path == "/tmp/swx-test/apple/swift-format/HEAD")
    }

    @Test func cachePathWithVersion() throws {
        let spec = try PackageSpec.parse("apple/swift-format@0.50.0")
        let manager = CacheManager(baseDirectory: "/tmp/swx-test")
        let path = manager.cachePath(for: spec)
        #expect(path == "/tmp/swx-test/apple/swift-format/0.50.0")
    }

    @Test func defaultBaseDirectory() {
        let manager = CacheManager()
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        #expect(manager.baseDirectory == "\(homeDir)/.swx/cache")
    }

    @Test func clonesUncachedRepositoryUsingGit() throws {
        let baseDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: baseDirectory) }

        let spec = try PackageSpec.parse("apple/swift-format")
        let expectedPath = baseDirectory
            .appendingPathComponent("apple/swift-format/HEAD")
            .path
        let executor = ProcessExecutor { request in
            #expect(
                request == ProcessRequest(
                    executablePath: "/usr/bin/git",
                    arguments: ["clone", spec.gitURL, expectedPath],
                    currentDirectoryPath: nil,
                    standardIO: .captureOutput(mergingStandardError: true)
                )
            )
            return .stub()
        }
        let manager = CacheManager(
            baseDirectory: baseDirectory.path,
            processExecutor: executor
        )

        let path = try manager.ensureRepository(for: spec)

        #expect(path == expectedPath)
    }

    @Test func cloneFailureIncludesCapturedGitOutput() throws {
        let baseDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: baseDirectory) }

        let spec = try PackageSpec.parse("apple/swift-format")
        let executor = ProcessExecutor { _ in
            .stub(terminationStatus: 128, output: "fatal: clone failed")
        }
        let manager = CacheManager(
            baseDirectory: baseDirectory.path,
            processExecutor: executor
        )

        do {
            _ = try manager.ensureRepository(for: spec)
            Issue.record("Expected clone to throw.")
        } catch CacheManagerError.gitFailed(let output) {
            #expect(output == "fatal: clone failed")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
