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
