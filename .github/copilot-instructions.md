# GitHub Copilot Coding Agent Instructions

## Repository Overview

This repository contains **RebrickableClient**, a Swift 6 API client for the [Rebrickable API](https://rebrickable.com/api/v3/docs/) - a comprehensive LEGO database and collection management service. The client is auto-generated using OpenAPI Generator version 7.15.0 from the official Rebrickable API specification.

### High-Level Repository Information

- **Type**: Swift Package (library)
- **Languages**: Swift 6.1+ only
- **Platforms**: iOS 18+, macOS 15+, tvOS 18+, watchOS 11+
- **Size**: ~5,252 lines of Swift code across 15 source files
- **Dependencies**: None (pure Foundation-based implementation)
- **License**: MIT
- **Generated Code**: Entire codebase is auto-generated; manual modifications should be minimal

### API Structure

The client provides access to three main API groups:
- **LegoAPI**: LEGO catalog data (sets, parts, colors, themes, minifigs) - 1,054 LOC
- **UsersAPI**: User collection management (part lists, set lists, profiles) - 2,218 LOC  
- **SwaggerAPI**: API documentation endpoint - 41 LOC

## Build and Validation Instructions

### Prerequisites

**IMPORTANT**: This package requires Apple development tools and will NOT build on Linux due to iOS/macOS-specific dependencies (MobileCoreServices framework). All build and test operations must be performed on macOS with Xcode installed.

- **macOS 13.0+** with Xcode 15.0+
- **Swift 6.1.2+** (included with Xcode)
- No additional dependencies required

### Build Commands

Always run commands from the repository root directory.

#### 1. Clean Build (Recommended First Step)
```bash
swift package clean
```
**Purpose**: Removes all build artifacts and cached data. Always run this first if encountering build issues.

#### 2. Resolve Dependencies
```bash
swift package resolve
```
**Purpose**: Resolves and fetches dependencies (though this package has none). Safe to run anytime.

#### 3. Build the Package
```bash
swift build --verbose
```
**Expected time**: 15-30 seconds on modern Mac
**Success indicator**: "Build complete!" message without errors
**Common failure**: "no such module 'MobileCoreServices'" - indicates you're running on an unsupported platform (Linux)

#### 4. Describe Package Structure
```bash
swift package describe
```
**Purpose**: Shows package configuration, targets, and platform requirements. Useful for understanding the project structure.

### Platform-Specific Build Requirements

**CRITICAL**: This package cannot be built or tested on non-Apple platforms. The CI system runs on `macos-latest` for this reason.

**If you encounter MobileCoreServices import errors**:
1. Verify you're running on macOS with Xcode installed
2. The package targets iOS/macOS/tvOS/watchOS only
3. Linux builds are not supported due to Apple-specific framework dependencies

### Testing

**No test suite exists** in this repository. The package is a generated API client library that relies on:
1. Successful compilation as validation
2. Integration testing by consumer applications
3. API contract compliance via OpenAPI specification

### Code Quality and Formatting

#### SwiftFormat Configuration
The repository includes a `.swiftformat` configuration file with the following key settings:
- 4-space indentation
- Swift 5.4 compatibility mode (for broader consumer compatibility)
- Enforces consistent code style across generated files

**Note**: SwiftFormat is configured but not required for builds. The generated code already follows the specified formatting rules.

#### Linting
No linting tools are configured or required. The generated code follows OpenAPI Generator's built-in conventions.

### Validation Pipeline

The GitHub Actions CI pipeline (`.github/workflows/ci.yml`) validates:
1. Code checkout on `macos-latest`
2. Swift environment setup via `swift-actions/setup-swift@v2`
3. Build verification with `swift build --verbose`

**CI triggers**: Pushes to `main` branch and all pull requests

## Project Layout and Architecture

### Directory Structure

```
/
├── .github/
│   ├── workflows/ci.yml          # CI/CD pipeline configuration
│   └── dependabot.yml            # Dependency update automation
├── .openapi-generator/           # OpenAPI Generator metadata
│   ├── FILES                     # List of generated files
│   └── VERSION                   # Generator version (7.15.0)
├── Sources/RebrickableClient/    # All Swift source code
│   ├── APIs/                     # API endpoint implementations
│   │   ├── LegoAPI.swift         # LEGO catalog endpoints
│   │   ├── UsersAPI.swift        # User collection endpoints
│   │   └── SwaggerAPI.swift      # API documentation endpoint
│   └── Infrastructure/           # Core client infrastructure
│       ├── APIs.swift            # Base API configuration and builders
│       ├── APIHelper.swift       # HTTP request/response handling
│       ├── CodableHelper.swift   # JSON encoding/decoding utilities
│       ├── Extensions.swift      # Swift type extensions for API use
│       ├── JSONDataEncoding.swift # JSON serialization
│       ├── JSONEncodingHelper.swift # JSON encoding utilities
│       ├── JSONValue.swift       # JSON value representation
│       ├── Models.swift          # Data models and structures
│       ├── OpenISO8601DateFormatter.swift # Date formatting
│       ├── SynchronizedDictionary.swift # Thread-safe dictionary
│       ├── URLSessionImplementations.swift # HTTP client implementations
│       └── Validation.swift      # Input validation utilities
├── docs/                         # API documentation (Markdown)
│   ├── LegoAPI.md               # LEGO endpoints documentation
│   ├── UsersAPI.md              # User endpoints documentation
│   └── SwaggerAPI.md            # Swagger endpoint documentation
├── Package.swift                # Swift Package Manager configuration
├── README.md                    # Project documentation
├── project.yml                  # XcodeGen configuration (legacy)
├── .swiftformat                 # Code formatting rules
├── .gitignore                   # Standard Swift/Xcode gitignore
├── .openapi-generator-ignore    # Files to exclude from regeneration
└── git_push.sh                  # OpenAPI Generator push script
```

### Key Configuration Files

- **Package.swift**: Defines package metadata, dependencies (none), platforms, and targets
- **.swiftformat**: Code formatting configuration (4-space indent, Swift 5.4 compatibility)
- **.github/workflows/ci.yml**: Automated build verification on macOS
- **project.yml**: Legacy XcodeGen configuration (iOS framework, deployment target 11.0)

### Architectural Elements

#### 1. API Configuration
- **Base URL**: `https://rebrickable.com`
- **Authentication**: Not required (public API endpoints)
- **Request Builder**: URLSession-based with configurable interceptors
- **Response Handling**: Codable-based JSON parsing with error handling

#### 2. Core Infrastructure Classes
- `OpenAPIClientAPIConfiguration`: Central configuration management
- `RequestBuilder<T>`: Generic HTTP request construction and execution
- `CodableHelper`: JSON encoding/decoding with date formatting
- `APIHelper`: URL encoding, header management, response validation

#### 3. Generated API Classes
Each API class provides async/await methods for all endpoints:
- Methods follow pattern: `functionName(parameters...) async throws(ErrorResponse) -> ReturnType`
- Request builder methods available for advanced use cases
- All classes use shared configuration by default

### Dependencies and Hidden Requirements

#### External Dependencies
- **None**: Package uses only Foundation and platform-specific Apple frameworks

#### Platform-Specific Dependencies
- **MobileCoreServices** (iOS/tvOS/watchOS): File type identification
- **UniformTypeIdentifiers** (iOS 14+/macOS 11+): Modern file type handling
- **Foundation**: Core networking and data handling
- **FoundationNetworking** (Linux): Automatically imported but not functional due to MobileCoreServices requirement

#### Build Tool Dependencies
- **Xcode 15.0+**: Required for Swift 6.1 support and Apple platform frameworks
- **macOS development environment**: Cannot build on other platforms

### Working with Generated Code

**IMPORTANT NOTES**:
1. **Do not manually edit generated files** - changes will be lost on regeneration
2. **Use OpenAPI Generator** for customizations via configuration files
3. **Extend functionality** through composition rather than inheritance
4. **Report issues** to OpenAPI Generator project for code generation problems

### Common Issues and Workarounds

1. **"no such module 'MobileCoreServices'" error**:
   - **Cause**: Building on non-Apple platform (Linux, Windows)
   - **Solution**: Use macOS with Xcode for all development and testing

2. **Swift version compatibility**:
   - **Package**: Requires Swift 6.1+
   - **Consumer compatibility**: SwiftFormat configured for Swift 5.4+ consumers
   - **Platform versions**: iOS 18+, macOS 15+, tvOS 18+, watchOS 11+

3. **File type handling**:
   - **Modern approach**: Uses UniformTypeIdentifiers when available
   - **Fallback**: MobileCoreServices for older platform versions
   - **Limitation**: No Linux support due to these dependencies

### Trust These Instructions

These instructions are comprehensive and tested. Only explore beyond them if:
- Build commands fail with errors not mentioned above
- You need to modify OpenAPI generation configuration
- Platform support requirements change
- New development tools are added to the repository

For routine development tasks, follow these instructions exactly as written.