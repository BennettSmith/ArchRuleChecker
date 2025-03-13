// Plugins/ArchRuleCheckerPlugin/plugin.swift
import PackagePlugin
import Foundation

@main
struct ArchRuleCheckerPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        // Find the executable that we'll use
        let architectureRules = try context.tool(named: "arch-rule-checker")
        
        // Set up configuration management
        let configManager = ConfigurationManager(
            packageDirectory: context.package.directoryURL,
            pluginWorkDirectory: context.pluginWorkDirectoryURL
        )
        
        // Resolve the configuration file path
        let configLocation = try configManager.resolveConfigurationLocation()
        
        // Find the target source path to analyze
        let sourceLocation = try resolveSourceLocation(context: context, arguments: arguments)
        
        // Run the architecture checker
        try runArchitectureChecker(
            executableLocation: architectureRules.url,
            sourceLocation: sourceLocation,
            configLocation: configLocation,
            arguments: filterArguments(arguments)
        )
    }
    
    /// Resolves which source path to analyze based on context and arguments
    private func resolveSourceLocation(context: PluginContext, arguments: [String]) throws -> URL {
        // Find all target source paths
        var sourcePaths: [URL] = []
        for target in context.package.targets {
            guard let target = target as? SwiftSourceModuleTarget else { continue }
            sourcePaths.append(target.directoryURL)
        }
        
        if sourcePaths.isEmpty {
            print("No source paths found in package")
            throw "No analyzable targets found in package"
        }
        
        // Allow specifying which target to analyze
        if let targetIndex = arguments.firstIndex(of: "--target") {
            if targetIndex + 1 < arguments.count {
                let targetName = arguments[targetIndex + 1]
                if let target = context.package.targets.first(where: { $0.name == targetName }) as? SwiftSourceModuleTarget {
                    print("Analyzing target: \(targetName) at \(target.directoryURL.path())")
                    return target.directoryURL
                } else {
                    print("Warning: Target '\(targetName)' not found. Using default.")
                }
            }
        }
        
        // Use the first target path as default
        print("Analyzing default target at: \(sourcePaths.first!.path())")
        return sourcePaths.first ?? URL(fileURLWithPath: ".")
    }
    
    /// Runs the architecture checker executable
    private func runArchitectureChecker(
        executableLocation: URL,
        sourceLocation: URL,
        configLocation: URL,
        arguments: [String]
    ) throws {
        // Set up the process
        let process = Process()
        process.executableURL = executableLocation
        process.arguments = [
            "--source-path", sourceLocation.path(),
            "--config-path", configLocation.path()
        ] + arguments
        
        // Run the process
        try process.run()
        process.waitUntilExit()
        
        // Check the exit status
        if process.terminationReason != .exit || process.terminationStatus != 0 {
            throw "Architecture rule violations found"
        }
    }
    
    /// Filters out any arguments already handled by the plugin
    private func filterArguments(_ arguments: [String]) -> [String] {
        var processedArgs = arguments
        if let targetIndex = processedArgs.firstIndex(of: "--target") {
            if targetIndex + 1 < processedArgs.count {
                processedArgs.remove(at: targetIndex + 1)
                processedArgs.remove(at: targetIndex)
            }
        }
        return processedArgs
    }
}

extension String: @retroactive Error {}
