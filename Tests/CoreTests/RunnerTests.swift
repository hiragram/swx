import Foundation
import Testing
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

    @Test func buildUsesReleaseConfiguration() throws {
        let executor = ProcessExecutor { request in
            #expect(
                request == ProcessRequest(
                    executablePath: "/usr/bin/swift",
                    arguments: ["build", "-c", "release"],
                    currentDirectoryPath: "/path/to/package",
                    standardIO: .captureOutput(mergingStandardError: true)
                )
            )
            return .stub()
        }
        let runner = Runner(
            packagePath: "/path/to/package",
            processExecutor: executor
        )

        try runner.build()
    }

    @Test func buildFailureIncludesCapturedOutput() {
        let executor = ProcessExecutor { _ in
            .stub(terminationStatus: 1, output: "build failed")
        }
        let runner = Runner(
            packagePath: "/path/to/package",
            processExecutor: executor
        )

        do {
            try runner.build()
            Issue.record("Expected build to throw.")
        } catch RunnerError.buildFailed(let output) {
            #expect(output == "build failed")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func fetchProductsDecodesPackageDescription() throws {
        let output = """
            {
              "products": [
                {"name": "tool", "type": {"executable": null}},
                {"name": "Library", "type": {"library": ["automatic"]}}
              ]
            }
            """
        let executor = ProcessExecutor { request in
            #expect(
                request == ProcessRequest(
                    executablePath: "/usr/bin/swift",
                    arguments: ["package", "describe", "--type", "json"],
                    currentDirectoryPath: "/path/to/package",
                    standardIO: .captureOutput(mergingStandardError: false)
                )
            )
            return .stub(output: output)
        }
        let runner = Runner(
            packagePath: "/path/to/package",
            processExecutor: executor
        )

        let products = try runner.fetchProducts()

        #expect(products.count == 2)
        #expect(products[0].name == "tool")
        #expect(products[0].type == .executable)
        #expect(products[1].name == "Library")
        #expect(products[1].type == .library)
    }

    @Test func runInheritsStandardIO() throws {
        let executor = ProcessExecutor { request in
            #expect(
                request == ProcessRequest(
                    executablePath: "/path/to/package/.build/release/tool",
                    arguments: ["--help"],
                    currentDirectoryPath: nil,
                    standardIO: .inherit
                )
            )
            return .stub()
        }
        let runner = Runner(
            packagePath: "/path/to/package",
            processExecutor: executor
        )

        try runner.run(executable: "tool", arguments: ["--help"])
    }

    @Test func runFailurePreservesExitStatus() {
        let executor = ProcessExecutor { _ in
            .stub(terminationStatus: 42)
        }
        let runner = Runner(
            packagePath: "/path/to/package",
            processExecutor: executor
        )

        do {
            try runner.run(executable: "tool", arguments: [])
            Issue.record("Expected executable to throw.")
        } catch RunnerError.executionFailed(let status) {
            #expect(status == 42)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
