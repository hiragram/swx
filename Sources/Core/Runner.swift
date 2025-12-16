import Foundation

public enum ProductType: Sendable {
    case executable
    case library
}

public struct ProductInfo: Sendable {
    public let name: String
    public let type: ProductType

    public init(name: String, type: ProductType) {
        self.name = name
        self.type = type
    }
}

public enum RunnerError: Error {
    case multipleExecutables([String])
    case noExecutables
    case buildFailed(String)
    case executionFailed(Int32)
}

public struct Runner: Sendable {
    public let packagePath: String

    public init(packagePath: String) {
        self.packagePath = packagePath
    }

    public var buildCommand: [String] {
        ["swift", "build", "-c", "release"]
    }

    public func executablePath(name: String) -> String {
        "\(packagePath)/.build/release/\(name)"
    }

    public func resolveExecutable(specified: String?, products: [ProductInfo]) throws -> String {
        if let specified {
            return specified
        }

        let executables = products.filter { $0.type == .executable }

        if executables.isEmpty {
            throw RunnerError.noExecutables
        }

        if executables.count > 1 {
            throw RunnerError.multipleExecutables(executables.map(\.name))
        }

        return executables[0].name
    }

    public func build() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        process.arguments = ["build", "-c", "release"]
        process.currentDirectoryURL = URL(fileURLWithPath: packagePath)

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            throw RunnerError.buildFailed(output)
        }
    }

    public func run(executable: String, arguments: [String]) throws {
        let path = executablePath(name: executable)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments

        // Inherit stdio so that MCP servers can communicate via stdin/stdout
        process.standardInput = FileHandle.standardInput
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw RunnerError.executionFailed(process.terminationStatus)
        }
    }

    public func fetchProducts() throws -> [ProductInfo] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        process.arguments = ["package", "describe", "--type", "json"]
        process.currentDirectoryURL = URL(fileURLWithPath: packagePath)

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()

        struct PackageDescription: Decodable {
            struct Product: Decodable {
                let name: String
                let type: [String: JSONValue]

                enum JSONValue: Decodable {
                    case null
                    case array([String])

                    init(from decoder: Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        if container.decodeNil() {
                            self = .null
                        } else if let array = try? container.decode([String].self) {
                            self = .array(array)
                        } else {
                            self = .null
                        }
                    }
                }

                var isExecutable: Bool {
                    type.keys.contains("executable")
                }
            }
            let products: [Product]
        }

        let description = try JSONDecoder().decode(PackageDescription.self, from: data)
        return description.products.map { product in
            let type: ProductType = product.isExecutable ? .executable : .library
            return ProductInfo(name: product.name, type: type)
        }
    }
}
