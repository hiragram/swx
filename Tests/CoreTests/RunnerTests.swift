import Testing
import Foundation
@testable import Core

struct RunnerTests {
    @Test func buildCommand() {
        let runner = Runner(packagePath: "/path/to/package")
        let command = runner.buildCommand
        #expect(command == ["swift", "build", "-c", "release"])
    }

    @Test func executablePath() {
        let runner = Runner(packagePath: "/path/to/package")
        let path = runner.executablePath(name: "mytool")
        #expect(path == "/path/to/package/.build/release/mytool")
    }

    @Test func resolveExecutableWhenSpecified() throws {
        let runner = Runner(packagePath: "/path/to/package")
        let name = try runner.resolveExecutable(
            specified: "mytool",
            products: [
                ProductInfo(name: "mytool", type: .executable),
                ProductInfo(name: "other", type: .executable)
            ]
        )
        #expect(name == "mytool")
    }

    @Test func resolveExecutableWhenSingleProduct() throws {
        let runner = Runner(packagePath: "/path/to/package")
        let name = try runner.resolveExecutable(
            specified: nil,
            products: [ProductInfo(name: "onlyone", type: .executable)]
        )
        #expect(name == "onlyone")
    }

    @Test func resolveExecutableFailsWhenMultipleAndNotSpecified() throws {
        let runner = Runner(packagePath: "/path/to/package")
        #expect(throws: RunnerError.self) {
            try runner.resolveExecutable(
                specified: nil,
                products: [
                    ProductInfo(name: "tool1", type: .executable),
                    ProductInfo(name: "tool2", type: .executable)
                ]
            )
        }
    }

    @Test func resolveExecutableFailsWhenNoExecutables() throws {
        let runner = Runner(packagePath: "/path/to/package")
        #expect(throws: RunnerError.self) {
            try runner.resolveExecutable(
                specified: nil,
                products: [ProductInfo(name: "MyLib", type: .library)]
            )
        }
    }
}
