import Testing
import Foundation
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
}
