import Testing
@testable import Core

struct ProcessExecutorTests {
    @Test func capturesStandardOutputAndError() throws {
        let result = try ProcessExecutor.live.execute(
            ProcessRequest(
                executablePath: "/bin/sh",
                arguments: ["-c", "printf output; printf error >&2; exit 7"],
                currentDirectoryPath: nil,
                standardIO: .captureOutput(mergingStandardError: true)
            )
        )

        #expect(result.terminationStatus == 7)
        #expect(result.outputString == "outputerror")
    }

    @Test func drainsOutputLargerThanPipeBuffer() throws {
        let result = try ProcessExecutor.live.execute(
            ProcessRequest(
                executablePath: "/bin/sh",
                arguments: ["-c", "/usr/bin/yes x | /usr/bin/head -c 131072"],
                currentDirectoryPath: nil,
                standardIO: .captureOutput(mergingStandardError: true)
            )
        )

        #expect(result.terminationStatus == 0)
        #expect(result.output.count == 131_072)
    }

    @Test func runsWithInheritedStandardIO() throws {
        let result = try ProcessExecutor.live.execute(
            ProcessRequest(
                executablePath: "/usr/bin/true",
                arguments: [],
                currentDirectoryPath: nil,
                standardIO: .inherit
            )
        )

        #expect(result.terminationStatus == 0)
        #expect(result.output.isEmpty)
    }
}
