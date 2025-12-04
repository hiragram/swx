import ArgumentParser

public struct SwxCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "swx",
        abstract: "Run Swift packages directly from GitHub"
    )

    @Argument(help: "Package to run (format: owner/repo or owner/repo@version)")
    public var package: String

    @Option(name: .long, help: "Executable name to run (required if package has multiple executables)")
    public var exec: String?

    @Argument(parsing: .allUnrecognized, help: "Arguments to pass to the executable (after --)")
    public var arguments: [String] = []

    public init() {}

    public mutating func run() throws {
        let spec = try PackageSpec.parse(package)
        let cacheManager = CacheManager()
        let packagePath = try cacheManager.ensureRepository(for: spec)

        let runner = Runner(packagePath: packagePath)
        try runner.build()

        let products = try runner.fetchProducts()
        let executableName = try runner.resolveExecutable(specified: exec, products: products)

        // Remove leading "--" if present
        let passedArguments = arguments.first == "--" ? Array(arguments.dropFirst()) : arguments
        try runner.run(executable: executableName, arguments: passedArguments)
    }
}
