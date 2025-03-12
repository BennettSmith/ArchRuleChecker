# Detailed Implementation Guide: Swift Architecture Rule Checker

This guide provides a step-by-step implementation for building an architectural rule checker for Swift projects, using Swift Testing instead of XCTest.

## Iteration 1: Setting Up the Project

### Create the project directory
```bash
mkdir ArchRuleChecker
cd ArchRuleChecker
```

### Initialize the Swift package
```bash
swift package init --type executable
```

### Update Package.swift with dependencies
```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ArchRuleChecker",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "arch-rule-checker", targets: ["ArchRuleChecker"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "ArchRuleChecker",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "ArchRuleCheckerTests",
            dependencies: [
                "ArchRuleChecker",
                .product(name: "Testing", package: "swift-testing")
            ]
        ),
    ]
)
```

### Build the project to verify dependencies
```bash
swift build
```

## Iteration 2: Creating a Basic Command Line Interface

### Update Sources/ArchRuleChecker/main.swift
```swift
import Foundation
import ArgumentParser

struct ArchRuleChecker: ParsableCommand {
    @Option(help: "Path to the directory containing the source code")
    var sourcePath: String = "."
    
    @Option(help: "Path to configuration file")
    var configPath: String?
    
    func run() throws {
        print("Architecture Rule Checker")
        print("Source Path: \(sourcePath)")
        print("Config Path: \(configPath ?? "Not specified")")
        
        // We'll implement the actual checking later
    }
}

ArchRuleChecker.main()
```

### Test the CLI
```bash
swift run arch-rule-checker --source-path ./Sources
```

## Iteration 3: Creating a Configuration Parser

### Create Sources/ArchRuleChecker/Configuration.swift
```swift
import Foundation

struct Configuration: Codable {
    var modelTypes: [String]
    
    static let defaultConfiguration = Configuration(
        modelTypes: ["Entity", "AggregateRoot", "ValueObject", "Model", "Domain"]
    )
}

class ConfigurationLoader {
    static func load(from path: String?) -> Configuration {
        guard let path = path else {
            return Configuration.defaultConfiguration
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(Configuration.self, from: data)
        } catch {
            print("Error loading configuration: \(error.localizedDescription)")
            print("Using default configuration")
            return Configuration.defaultConfiguration
        }
    }
}
```

### Add Tests/ArchRuleCheckerTests/ConfigurationTests.swift using Swift Testing
```swift
import Testing
@testable import ArchRuleChecker

@Suite("ConfigurationTests")
struct ConfigurationTests {
    @Test("Default configuration has expected model types")
    func testDefaultConfiguration() {
        let config = Configuration.defaultConfiguration
        #expect(config.modelTypes.count == 5)
        #expect(config.modelTypes.contains("Entity"))
        #expect(config.modelTypes.contains("ValueObject"))
    }
    
    @Test("Loading non-existent configuration file returns default config")
    func testLoadingNonExistentFile() {
        let config = ConfigurationLoader.load(from: "/path/does/not/exist")
        // Should fall back to default
        #expect(config.modelTypes.count == 5)
    }
    
    @Test("Loading valid configuration file works correctly")
    func testLoadingValidConfiguration() throws {
        // Create a temporary file
        let tempDir = NSTemporaryDirectory()
        let tempFilePath = tempDir + "/test_config.json"
        
        let testConfig = """
        {
            "modelTypes": ["TestModel", "TestEntity"]
        }
        """
        
        try testConfig.write(to: URL(fileURLWithPath: tempFilePath), atomically: true, encoding: .utf8)
        
        let config = ConfigurationLoader.load(from: tempFilePath)
        #expect(config.modelTypes.count == 2)
        #expect(config.modelTypes.contains("TestModel"))
        #expect(config.modelTypes.contains("TestEntity"))
        
        // Clean up
        try FileManager.default.removeItem(atPath: tempFilePath)
    }
}
```

### Run the tests
```bash
swift test
```

## Iteration 4: File Discovery

### Create Sources/ArchRuleChecker/FileDiscovery.swift
```swift
import Foundation

struct FileDiscovery {
    static func findSwiftFiles(in directory: String) -> [URL] {
        let fileManager = FileManager.default
        let directoryURL = URL(fileURLWithPath: directory)
        
        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            print("Could not enumerate files in \(directory)")
            return []
        }
        
        var swiftFiles: [URL] = []
        
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "swift" else { continue }
            
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                guard resourceValues.isRegularFile! else { continue }
                swiftFiles.append(fileURL)
            } catch {
                print("Error examining \(fileURL.path): \(error.localizedDescription)")
            }
        }
        
        return swiftFiles
    }
    
    static func isUseCase(file: URL) -> Bool {
        let fileName = file.lastPathComponent
        let pathComponents = file.pathComponents
        
        return fileName.contains("UseCase") || 
              (pathComponents.contains("Core") && pathComponents.contains("UseCases"))
    }
}
```

### Add Tests/ArchRuleCheckerTests/FileDiscoveryTests.swift
```swift
import Testing
import Foundation
@testable import ArchRuleChecker

@Suite("FileDiscoveryTests")
struct FileDiscoveryTests {
    @Test("Should find Swift files in directory")
    func testSwiftFileDiscovery() throws {
        // Create a temporary directory with some test files
        let tempDir = NSTemporaryDirectory() + "/SwiftFileTest"
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        
        // Create test files
        try "".write(to: URL(fileURLWithPath: tempDir + "/Test1.swift"), atomically: true, encoding: .utf8)
        try "".write(to: URL(fileURLWithPath: tempDir + "/Test2.swift"), atomically: true, encoding: .utf8)
        try "".write(to: URL(fileURLWithPath: tempDir + "/NotSwift.txt"), atomically: true, encoding: .utf8)
        
        let files = FileDiscovery.findSwiftFiles(in: tempDir)
        #expect(files.count == 2)
        #expect(files.contains(where: { $0.lastPathComponent == "Test1.swift" }))
        #expect(files.contains(where: { $0.lastPathComponent == "Test2.swift" }))
        #expect(!files.contains(where: { $0.lastPathComponent == "NotSwift.txt" }))
        
        // Clean up
        try FileManager.default.removeItem(atPath: tempDir)
    }
    
    @Test("Should correctly identify UseCase files")
    func testUseCaseDetection() {
        let useCaseURL = URL(fileURLWithPath: "/Core/UseCases/LoginUseCase.swift")
        #expect(FileDiscovery.isUseCase(file: useCaseURL))
        
        let nonUseCaseURL = URL(fileURLWithPath: "/Infrastructure/Services/AuthService.swift")
        #expect(!FileDiscovery.isUseCase(file: nonUseCaseURL))
    }
}
```

## Iteration 5: SwiftSyntax Analyzer

### Create Sources/ArchRuleChecker/UseCaseAnalyzer.swift
```swift
import Foundation
import SwiftSyntax
import SwiftParser

enum ArchitectureError: Error, CustomStringConvertible {
    case useCaseExposingModelObject(useCaseName: String, methodName: String, returnType: String)
    
    var description: String {
        switch self {
        case let .useCaseExposingModelObject(useCaseName, methodName, returnType):
            return "UseCase '\(useCaseName)' exposes model object '\(returnType)' in method '\(methodName)'"
        }
    }
}

class UseCaseVisitor: SyntaxVisitor {
    let fileName: String
    let modelTypes: [String]
    var currentClassName: String?
    var violations: [ArchitectureError] = []
    
    init(fileName: String, modelTypes: [String]) {
        self.fileName = fileName
        self.modelTypes = modelTypes
        super.init(viewMode: .sourceAccurate)
    }
    
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        currentClassName = node.name.text
        return .visitChildren
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let currentClassName = currentClassName else {
            return .visitChildren
        }
        
        // Check if function returns a model type
        if let returnType = node.signature.returnClause?.type {
            let returnTypeString = returnType.description.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check for direct model returns or inside wrappers like Result<ModelType, Error>
            for modelType in modelTypes {
                if returnTypeString.contains(modelType) {
                    // Allow response objects which should contain only data
                    if !returnTypeString.contains("Response") && !returnTypeString.contains("DTO") {
                        violations.append(.useCaseExposingModelObject(
                            useCaseName: currentClassName,
                            methodName: node.name.text,
                            returnType: returnTypeString
                        ))
                    }
                }
            }
        }
        
        return .visitChildren
    }
}

class UseCaseAnalyzer {
    static func analyze(sourceCode: String, fileName: String, modelTypes: [String]) -> [ArchitectureError] {
        let sourceFile = Parser.parse(source: sourceCode)
        let visitor = UseCaseVisitor(fileName: fileName, modelTypes: modelTypes)
        visitor.walk(sourceFile)
        return visitor.violations
    }
}
```

### Add Tests/ArchRuleCheckerTests/UseCaseAnalyzerTests.swift
```swift
import Testing
import SwiftSyntax
@testable import ArchRuleChecker

@Suite("UseCaseAnalyzerTests")
struct UseCaseAnalyzerTests {
    let modelTypes = ["Entity", "Model", "ValueObject"]
    
    @Test("Non-violating UseCase should have no violations")
    func testNonViolatingUseCase() {
        let source = """
        class LoginUseCase {
            func execute(username: String, password: String) -> LoginResponse {
                return LoginResponse(token: "abc123")
            }
        }
        
        struct LoginResponse {
            let token: String
        }
        """
        
        let violations = UseCaseAnalyzer.analyze(
            sourceCode: source,
            fileName: "LoginUseCase.swift",
            modelTypes: modelTypes
        )
        
        #expect(violations.count == 0)
    }
    
    @Test("UseCase exposing Entity should have a violation")
    func testViolatingUseCase() {
        let source = """
        class GetUserUseCase {
            func execute(userId: String) -> UserEntity {
                return UserEntity(id: userId, name: "John")
            }
        }
        
        class UserEntity {
            let id: String
            let name: String
            
            init(id: String, name: String) {
                self.id = id
                self.name = name
            }
        }
        """
        
        let violations = UseCaseAnalyzer.analyze(
            sourceCode: source,
            fileName: "GetUserUseCase.swift",
            modelTypes: modelTypes
        )
        
        #expect(violations.count == 1)
        if let violation = violations.first {
            if case let .useCaseExposingModelObject(useCaseName, methodName, returnType) = violation {
                #expect(useCaseName == "GetUserUseCase")
                #expect(methodName == "execute")
                #expect(returnType == "UserEntity")
            } else {
                throw TestFailure("Wrong violation type")
            }
        }
    }
    
    @Test("Result-wrapped entity should have a violation")
    func testResultWrappedType() {
        let source = """
        class FetchOrderUseCase {
            func execute(orderId: String) -> Result<OrderEntity, Error> {
                return .success(OrderEntity())
            }
        }
        
        class OrderEntity {}
        """
        
        let violations = UseCaseAnalyzer.analyze(
            sourceCode: source,
            fileName: "FetchOrderUseCase.swift",
            modelTypes: modelTypes
        )
        
        #expect(violations.count == 1)
    }
    
    @Test("Response types should not violate the rule")
    func testResponseDoesntViolate() {
        let source = """
        class GetProductUseCase {
            func execute(productId: String) -> ProductResponse {
                let entity = ProductEntity()
                return ProductResponse(id: entity.id, name: entity.name)
            }
        }
        
        struct ProductResponse {
            let id: String
            let name: String
        }
        
        class ProductEntity {
            let id: String = "123"
            let name: String = "Product"
        }
        """
        
        let violations = UseCaseAnalyzer.analyze(
            sourceCode: source,
            fileName: "GetProductUseCase.swift",
            modelTypes: modelTypes
        )
        
        #expect(violations.count == 0)
    }
}
```

## Iteration 6: Integrating Everything in the Main Command

### Update Sources/ArchRuleChecker/main.swift
```swift
import Foundation
import ArgumentParser
import SwiftSyntax
import SwiftParser

struct ArchRuleChecker: ParsableCommand {
    @Option(help: "Path to the directory containing the source code")
    var sourcePath: String = "."
    
    @Option(help: "Path to configuration file")
    var configPath: String?
    
    func run() throws {
        print("Architecture Rule Checker")
        
        // Load configuration
        let config = ConfigurationLoader.load(from: configPath)
        print("Using model types: \(config.modelTypes.joined(separator: ", "))")
        
        // Find Swift files
        let files = FileDiscovery.findSwiftFiles(in: sourcePath)
        print("Found \(files.count) Swift files")
        
        var violations: [ArchitectureError] = []
        var analyzedUseCases = 0
        
        // Analyze use cases
        for fileURL in files {
            if FileDiscovery.isUseCase(file: fileURL) {
                analyzedUseCases += 1
                do {
                    let sourceCode = try String(contentsOf: fileURL, encoding: .utf8)
                    let fileViolations = UseCaseAnalyzer.analyze(
                        sourceCode: sourceCode,
                        fileName: fileURL.lastPathComponent,
                        modelTypes: config.modelTypes
                    )
                    violations.append(contentsOf: fileViolations)
                } catch {
                    print("Error analyzing \(fileURL.path): \(error.localizedDescription)")
                }
            }
        }
        
        // Report results
        print("\nAnalyzed \(analyzedUseCases) use case files")
        
        if violations.isEmpty {
            print("✅ No architectural violations found")
        } else {
            print("❌ Found \(violations.count) architectural violations:")
            for violation in violations {
                print("- \(violation)")
            }
            throw ExitCode(1)
        }
    }
}

ArchRuleChecker.main()
```

## Iteration 7: Create a Sample Test Project

### Create directories for the test project
```bash
mkdir -p TestProject/Sources/{Application,Core,Infrastructure}
mkdir -p TestProject/Sources/Core/{Models,UseCases,Repositories}
```

### Create TestProject/Sources/Core/Models/UserEntity.swift
```swift
import Foundation

class UserEntity {
    let id: String
    let name: String
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
```

### Create TestProject/Sources/Core/UseCases/GetUserUseCase.swift
```swift
import Foundation

class GetUserUseCase {
    private let userRepository: UserRepository
    
    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }
    
    // This violates the rule - directly exposing a model object
    func execute(userId: String) -> UserEntity {
        return userRepository.getUser(byId: userId)
    }
}
```

### Create TestProject/Sources/Core/UseCases/ListUsersUseCase.swift
```swift
import Foundation

class ListUsersUseCase {
    private let userRepository: UserRepository
    
    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }
    
    // This follows the rule - using a response object
    func execute() -> [UserListResponse] {
        let users = userRepository.getAllUsers()
        return users.map { UserListResponse(id: $0.id, name: $0.name) }
    }
}

struct UserListResponse {
    let id: String
    let name: String
}
```

### Create TestProject/Sources/Core/Repositories/UserRepository.swift
```swift
import Foundation

protocol UserRepository {
    func getUser(byId id: String) -> UserEntity
    func getAllUsers() -> [UserEntity]
}
```

### Create TestProject/Sources/Infrastructure/UserRepositoryImpl.swift
```swift
import Foundation

class UserRepositoryImpl: UserRepository {
    func getUser(byId id: String) -> UserEntity {
        return UserEntity(id: id, name: "Test User")
    }
    
    func getAllUsers() -> [UserEntity] {
        return [
            UserEntity(id: "1", name: "User 1"),
            UserEntity(id: "2", name: "User 2")
        ]
    }
}
```

### Run the tool on the sample project
```bash
swift run arch-rule-checker --source-path ./TestProject/Sources
```

## Iteration 8: Create a Swift Package Manager Plugin

### Update Package.swift to include the plugin
```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ArchRuleChecker",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "arch-rule-checker", targets: ["ArchRuleChecker"]),
        .plugin(name: "ArchRuleCheckerPlugin", targets: ["ArchRuleCheckerPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "ArchRuleChecker",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .plugin(
            name: "ArchRuleCheckerPlugin",
            capability: .command(
                intent: .custom(
                    verb: "check-architecture",
                    description: "Verifies code adheres to architectural rules"
                ),
                permissions: [.writeToPackageDirectory(reason: "To output report files")]
            ),
            dependencies: [
                .target(name: "ArchRuleChecker")
            ]
        ),
        .testTarget(
            name: "ArchRuleCheckerTests",
            dependencies: [
                "ArchRuleChecker",
                .product(name: "Testing", package: "swift-testing")
            ]
        ),
    ]
)
```

### Create Plugins/ArchRuleCheckerPlugin/plugin.swift
```swift
import PackagePlugin
import Foundation

@main
struct ArchRuleCheckerPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        // Find the executable
        let archRuleChecker = try context.tool(named: "arch-rule-checker")
        
        // Working directory for outputs
        let outputDirectory = context.pluginWorkDirectory
        
        // Create default config if needed
        let configPath = outputDirectory.appending("arch-config.json")
        let configURL = URL(fileURLWithPath: configPath.string)
        
        if !FileManager.default.fileExists(atPath: configPath.string) {
            let defaultConfig = """
            {
                "modelTypes": [
                    "Entity",
                    "AggregateRoot",
                    "ValueObject",
                    "Model",
                    "Domain"
                ]
            }
            """
            try defaultConfig.write(to: configURL, atomically: true, encoding: .utf8)
            print("Created default configuration at \(configPath)")
        }
        
        // Find all target source paths
        var sourcePaths: [Path] = []
        for target in context.package.targets {
            guard let target = target as? SourceModuleTarget else { continue }
            sourcePaths.append(target.directory)
        }
        
        if sourcePaths.isEmpty {
            print("No source paths found in package")
            return
        }
        
        // Process arguments
        var processedArgs = arguments
        var sourcePath = sourcePaths.first!.string
        
        // Allow specifying which target to analyze
        if let targetIndex = processedArgs.firstIndex(of: "--target") {
            if targetIndex + 1 < processedArgs.count {
                let targetName = processedArgs[targetIndex + 1]
                if let target = context.package.targets.first(where: { $0.name == targetName }) as? SourceModuleTarget {
                    sourcePath = target.directory.string
                    print("Analyzing target: \(targetName) at \(sourcePath)")
                }
                processedArgs.remove(at: targetIndex + 1)
                processedArgs.remove(at: targetIndex)
            }
        }
        
        // Run the command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: archRuleChecker.path.string)
        process.arguments = [
            "--source-path", sourcePath,
            "--config-path", configPath.string
        ] + processedArgs
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationReason != .exit || process.terminationStatus != 0 {
            throw "Architecture rule violations found"
        }
    }
}

extension String: Error {}
```

## Iteration 9: Extending with Additional Rules

### Update Sources/ArchRuleChecker/UseCaseAnalyzer.swift to include new error types
```swift
enum ArchitectureError: Error, CustomStringConvertible {
    case useCaseExposingModelObject(useCaseName: String, methodName: String, returnType: String)
    case infraDependsOnCoreImplementation(className: String, dependencyName: String)
    
    var description: String {
        switch self {
        case let .useCaseExposingModelObject(useCaseName, methodName, returnType):
            return "UseCase '\(useCaseName)' exposes model object '\(returnType)' in method '\(methodName)'"
        case let .infraDependsOnCoreImplementation(className, dependencyName):
            return "Infrastructure class '\(className)' depends on core implementation '\(dependencyName)' instead of interface"
        }
    }
}
```

### Create Sources/ArchRuleChecker/InfrastructureAnalyzer.swift
```swift
import Foundation
import SwiftSyntax
import SwiftParser

class InfrastructureVisitor: SyntaxVisitor {
    let fileName: String
    var currentClassName: String?
    var violations: [ArchitectureError] = []
    
    init(fileName: String) {
        self.fileName = fileName
        super.init(viewMode: .sourceAccurate)
    }
    
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        currentClassName = node.name.text
        return .visitChildren
    }
    
    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let currentClassName = currentClassName else {
            return .visitChildren
        }
        
        // This would need more sophisticated analysis in a real implementation
        // For demonstration purposes, we'll use a simple check for concrete implementations
        // by looking for non-protocol property types
        
        for binding in node.bindings {
            if let typeAnnotation = binding.typeAnnotation,
               let type = typeAnnotation.type.as(SimpleTypeIdentifierSyntax.self) {
                let typeName = type.name.text
                
                // A very simple check - in real life you'd need a more sophisticated check
                if !typeName.hasPrefix("Protocol") && !typeName.hasSuffix("Protocol") &&
                   !typeName.hasSuffix("Repository") && !typeName.hasSuffix("Service") {
                    violations.append(.infraDependsOnCoreImplementation(
                        className: currentClassName,
                        dependencyName: typeName
                    ))
                }
            }
        }
        
        return .visitChildren
    }
}

class InfrastructureAnalyzer {
    static func analyze(sourceCode: String, fileName: String) -> [ArchitectureError] {
        let sourceFile = Parser.parse(source: sourceCode)
        let visitor = InfrastructureVisitor(fileName: fileName)
        visitor.walk(sourceFile)
        return visitor.violations
    }
}
```

### Update FileDiscovery.swift with infrastructure detection
```swift
static func isInfrastructure(file: URL) -> Bool {
    let pathComponents = file.pathComponents
    return pathComponents.contains("Infrastructure")
}
```

### Update main.swift to use the new analyzer
```swift
// In the run method, update the file analysis loop:
for fileURL in files {
    if FileDiscovery.isUseCase(file: fileURL) {
        analyzedUseCases += 1
        do {
            let sourceCode = try String(contentsOf: fileURL, encoding: .utf8)
            let fileViolations = UseCaseAnalyzer.analyze(
                sourceCode: sourceCode,
                fileName: fileURL.lastPathComponent,
                modelTypes: config.modelTypes
            )
            violations.append(contentsOf: fileViolations)
        } catch {
            print("Error analyzing \(fileURL.path): \(error.localizedDescription)")
        }
    } else if FileDiscovery.isInfrastructure(file: fileURL) {
        do {
            let sourceCode = try String(contentsOf: fileURL, encoding: .utf8)
            let fileViolations = InfrastructureAnalyzer.analyze(
                sourceCode: sourceCode,
                fileName: fileURL.lastPathComponent
            )
            violations.append(contentsOf: fileViolations)
        } catch {
            print("Error analyzing \(fileURL.path): \(error.localizedDescription)")
        }
    }
}
```

## Iteration 10: Xcode Integration

### Create a shell script check_architecture.sh
```bash
#!/bin/bash
# check_architecture.sh

if which swift >/dev/null; then
  cd "${SRCROOT}" && swift package check-architecture --target ${TARGET_NAME}
  
  # Check exit code
  if [ $? -ne 0 ]; then
    echo "Architecture violations found!"
    exit 1
  fi
else
  echo "warning: Swift Package Manager not installed"
fi
```

### Make the script executable
```bash
chmod +x check_architecture.sh
```

### Configure Xcode
1. Add the script as a "Run Script Phase" in your target's Build Phases
2. Position it early in the build process
3. Make sure it fails the build on errors with "Show environment variables in build log" and "Run script only when installing" unchecked

## Iteration 11: CI Integration

### Create .github/workflows/architecture-check.yml
```yaml
name: Architecture Check

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  architecture-check:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Swift
      uses: swift-actions/setup-swift@v1
      with:
        swift-version: '5.9'
    
    - name: Build
      run: swift build
        
    - name: Check architecture rules
      run: swift run arch-rule-checker --source-path ./Sources
        
    - name: Run tests
      run: swift test
```

## Iteration 12: Documentation

### Create a README.md file
```markdown
# Architecture Rule Checker

A tool for enforcing architectural rules in Swift projects.

## Features

- Check that use cases don't expose model objects
- Verify dependency rules in infrastructure layers
- Integrate with Swift Package Manager
- Run from command line or CI pipelines

## Usage

```bash
swift run arch-rule-checker --source-path ./Sources --config-path ./config.json
```

## Configuration

Create a `arch-config.json` file:

```json
{
  "modelTypes": [
    "Entity",
    "AggregateRoot", 
    "ValueObject",
    "Model",
    "Domain"
  ]
}
```

## Adding New Rules

To add new architectural rules, extend the `ArchitectureError` enum and create a new visitor class.
```

## Summary

This step-by-step guide has walked you through building a complete architecture rule checker for Swift projects. You've learned how to:

1. Set up a Swift Package Manager project with dependencies
2. Use Swift Testing for unit tests
3. Parse and analyze Swift code with SwiftSyntax
4. Detect architectural violations in use cases
5. Create a command-line tool
6. Build a Swift Package Manager plugin
7. Integrate with Xcode and CI workflows

The implementation focuses on a specific architectural rule (use cases shouldn't expose model objects), but the framework is extensible and can be enhanced with additional rules as needed.

## Next Steps

- Add more rules to enforce your architectural boundaries
- Create a visualization of the architecture
- Add support for reporting and metrics
- Integrate with code review tools
