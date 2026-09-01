import Foundation

struct ProcessRequest: Equatable, Sendable {
    enum StandardIO: Equatable, Sendable {
        case captureOutput(mergingStandardError: Bool)
        case inherit
    }

    let executablePath: String
    let arguments: [String]
    let currentDirectoryPath: String?
    let standardIO: StandardIO
}

struct ProcessResult: Equatable, Sendable {
    let terminationStatus: Int32
    let output: Data

    var outputString: String {
        String(data: output, encoding: .utf8) ?? ""
    }
}

struct ProcessExecutor: Sendable {
    let execute: @Sendable (ProcessRequest) throws -> ProcessResult

    static let live = ProcessExecutor { request in
        let process = Process()
        process.executableURL = URL(fileURLWithPath: request.executablePath)
        process.arguments = request.arguments
        if let currentDirectoryPath = request.currentDirectoryPath {
            process.currentDirectoryURL = URL(fileURLWithPath: currentDirectoryPath)
        }

        let outputPipe: Pipe?
        switch request.standardIO {
        case .captureOutput(let mergingStandardError):
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = mergingStandardError ? pipe : FileHandle.nullDevice
            outputPipe = pipe
        case .inherit:
            process.standardInput = FileHandle.standardInput
            process.standardOutput = FileHandle.standardOutput
            process.standardError = FileHandle.standardError
            outputPipe = nil
        }

        try process.run()
        let output = outputPipe?.fileHandleForReading.readDataToEndOfFile() ?? Data()
        process.waitUntilExit()

        return ProcessResult(
            terminationStatus: process.terminationStatus,
            output: output
        )
    }
}
