import PackagePlugin
import Foundation

@main
struct ArchRuleCheckerPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        // Find the executable
        let archRuleChecker = try context.tool(named: "ArchRuleChecker")
        
        // Working directory for outputs
        let outputDirectory = context.pluginWorkDirectoryURL
        
        // Create default config if needed
        let configURL = outputDirectory.appending(component: "arch-config.json")
        
        if !FileManager.default.fileExists(atPath: configURL.path()) {
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
            print("Created default configuration at \(configURL.path())")
        }
        
        // Find all target source paths
        var sourcePaths: [URL] = []
        for target in context.package.targets {
            guard let target = target as? SwiftSourceModuleTarget else { continue }
            sourcePaths.append(target.directoryURL)
        }
        
        if sourcePaths.isEmpty {
            print("No source paths found in package")
            return
        }
        
        // Process arguments
        var processedArgs = arguments
        var sourcePath = sourcePaths.first!.path()
        
        // Allow specifying which target to analyze
        if let targetIndex = processedArgs.firstIndex(of: "--target") {
            if targetIndex + 1 < processedArgs.count {
                let targetName = processedArgs[targetIndex + 1]
                if let target = context.package.targets.first(where: { $0.name == targetName }) as? SwiftSourceModuleTarget {
                    sourcePath = target.directoryURL.path()
                    print("Analyzing target: \(targetName) at \(sourcePath)")
                }
                processedArgs.remove(at: targetIndex + 1)
                processedArgs.remove(at: targetIndex)
            }
        }
        
        // Run the command
        let process = Process()
        process.executableURL = archRuleChecker.url
        process.arguments = [
            "--source-path", sourcePath,
            "--config-path", configURL.path()
        ] + processedArgs
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationReason != .exit || process.terminationStatus != 0 {
            throw "Architecture rule violations found"
        }
    }
}

extension String: @retroactive Error {}
