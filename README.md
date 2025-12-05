# swx

A Swift package runner similar to npx. Run Swift packages directly from GitHub without manual cloning or installation.

## Usage

```bash
# Basic usage
swx owner/repo

# With version/tag/branch
swx owner/repo@v1.0.0
swx owner/repo@main

# Specify executable (required if package has multiple executables)
swx owner/repo --exec toolname

# Pass arguments to the executable
swx apple/swift-format --exec swift-format -- --help
```

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/hiragram/swx/main/install.sh | bash
```

You can also specify a custom install directory:

```bash
INSTALL_DIR=~/.local/bin curl -fsSL https://raw.githubusercontent.com/hiragram/swx/main/install.sh | bash
```

To uninstall, remove the binary and cache directory:

```bash
rm /usr/local/bin/swx
rm -rf ~/.swx
```

## How it works

1. Parses the package specification (`owner/repo[@version]`)
2. Clones the repository to `~/.swx/cache/<owner>/<repo>/<version>`
3. Builds the package with `swift build -c release`
4. Runs the executable with any provided arguments

Subsequent runs use the cached repository, fetching updates as needed.

## Examples

```bash
# Run swift-format
swx apple/swift-format --exec swift-format -- --version

# Run a specific version
swx apple/swift-format@0.50.0 --exec swift-format -- lint Sources/

# Run a package with a single executable (no --exec needed)
swx owner/single-executable-repo
```

## Requirements

- macOS 13.0+
- Swift 6.0+
- Git

## License

MIT
