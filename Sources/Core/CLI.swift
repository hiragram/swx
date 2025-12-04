import ArgumentParser

public enum RunAction: Equatable {
    case run(executable: String, arguments: [String])
    case listExecutables([String])
}

public struct SwxCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "swx",
        abstract: "Run Swift packages directly from GitHub"
    )

    @Argument(help: "Package to run (format: owner/repo or owner/repo@version)")
    public var package: String

    @Option(name: .long, help: "Executable name to run (required if package has multiple executables)")
    public var exec: String?

    @Flag(name: .long, help: "List available executables in the package")
    public var listExecutables: Bool = false

    @Argument(parsing: .allUnrecognized, help: "Arguments to pass to the executable (after --)")
    public var arguments: [String] = []

    public init() {}

    public mutating func run() throws {
        let spec = try PackageSpec.parse(package)
        let cacheManager = CacheManager()
        let packagePath = try cacheManager.ensureRepository(for: spec)

        let runner = Runner(packagePath: packagePath)
        let products = try runner.fetchProducts()
        let executables = products.filter { $0.type == .executable }

        // Remove leading "--" if present
        let passedArguments = arguments.first == "--" ? Array(arguments.dropFirst()) : arguments

        let action = determineAction(
            listExecutablesFlag: listExecutables,
            specifiedExec: exec,
            executables: executables.map(\.name),
            arguments: passedArguments
        )

        switch action {
        case .listExecutables(let names):
            printExecutables(names)
        case .run(let executable, _):
            try runner.build()
            try runner.run(executable: executable, arguments: passedArguments)
        }
    }

    private func printExecutables(_ names: [String]) {
        print("Available executables:")
        for name in names {
            print("  - \(name)")
        }
    }
}

public func determineAction(
    listExecutablesFlag: Bool,
    specifiedExec: String?,
    executables: [String],
    arguments: [String]
) -> RunAction {
    if listExecutablesFlag {
        return .listExecutables(executables)
    }

    if let specified = specifiedExec {
        return .run(executable: specified, arguments: arguments)
    }

    if executables.count == 1 {
        return .run(executable: executables[0], arguments: arguments)
    }

    // Multiple executables and none specified
    return .listExecutables(executables)
}
