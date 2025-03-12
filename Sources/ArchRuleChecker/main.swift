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
