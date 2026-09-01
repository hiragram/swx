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
    private let processExecutor: ProcessExecutor

    public init(packagePath: String) {
        self.init(
            packagePath: packagePath,
            processExecutor: .live
        )
    }

    init(packagePath: String, processExecutor: ProcessExecutor) {
        self.packagePath = packagePath
        self.processExecutor = processExecutor
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
        let result = try processExecutor.execute(
            ProcessRequest(
                executablePath: "/usr/bin/swift",
                arguments: ["build", "-c", "release"],
                currentDirectoryPath: packagePath,
                standardIO: .captureOutput(mergingStandardError: true)
            )
        )

        if result.terminationStatus != 0 {
            throw RunnerError.buildFailed(result.outputString)
        }
    }

    public func run(executable: String, arguments: [String]) throws {
        // Inherit stdio so that MCP servers can communicate via stdin/stdout
        let result = try processExecutor.execute(
            ProcessRequest(
                executablePath: executablePath(name: executable),
                arguments: arguments,
                currentDirectoryPath: nil,
                standardIO: .inherit
            )
        )

        if result.terminationStatus != 0 {
            throw RunnerError.executionFailed(result.terminationStatus)
        }
    }

    public func fetchProducts() throws -> [ProductInfo] {
        let result = try processExecutor.execute(
            ProcessRequest(
                executablePath: "/usr/bin/swift",
                arguments: ["package", "describe", "--type", "json"],
                currentDirectoryPath: packagePath,
                standardIO: .captureOutput(mergingStandardError: false)
            )
        )

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

        let description = try JSONDecoder().decode(PackageDescription.self, from: result.output)
        return description.products.map { product in
            let type: ProductType = product.isExecutable ? .executable : .library
            return ProductInfo(name: product.name, type: type)
        }
    }
}
