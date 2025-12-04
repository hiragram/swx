import Testing
@testable import Core

struct PackageSpecTests {
    @Test func parseOwnerRepo() throws {
        let spec = try PackageSpec.parse("apple/swift-format")
        #expect(spec.owner == "apple")
        #expect(spec.repo == "swift-format")
        #expect(spec.version == nil)
    }

    @Test func parseWithVersion() throws {
        let spec = try PackageSpec.parse("apple/swift-format@0.50.0")
        #expect(spec.owner == "apple")
        #expect(spec.repo == "swift-format")
        #expect(spec.version == "0.50.0")
    }

    @Test func gitURL() throws {
        let spec = try PackageSpec.parse("apple/swift-format")
        #expect(spec.gitURL == "https://github.com/apple/swift-format.git")
    }

    @Test func parseInvalidFormat() throws {
        #expect(throws: PackageSpecError.self) {
            try PackageSpec.parse("invalid")
        }
    }
}
