// Plugins/ArchRuleCheckerPlugin/ConfigurationManager.swift
import Foundation

/// Manages configuration file discovery and creation for the architecture rule checker plugin
struct ConfigurationManager {
    private let packageDirectory: URL
    private let pluginWorkDirectory: URL
    
    init(packageDirectory: URL, pluginWorkDirectory: URL) {
        self.packageDirectory = packageDirectory
        self.pluginWorkDirectory = pluginWorkDirectory
    }
    
    /// Find or create a configuration file
    /// - Returns: The path to the configuration file to use
    func resolveConfigurationLocation() throws -> URL {
        // Look for existing config in standard locations first
        if let existingConfig = findExistingConfigurationFile() {
            print("Using configuration file at: \(existingConfig.path())")
            return existingConfig
        }
        
        // If no config found, create a default one in the working directory
        return try createDefaultConfigurationFile()
    }
    
    private func possibleConfigLocations(relativeTo root: URL) -> [URL] {
        return [
            root.appending(components: "arch-config.json"),
            root.appending(components: ".swiftpm/arch-config.json"),
            root.appending(components: ".config/arch-config.json")
        ]
    }
    
    /// Finds an existing configuration file in the package
    /// - Returns: Path to the configuration file if found, nil otherwise
    private func findExistingConfigurationFile() -> URL? {
        for location in possibleConfigLocations(relativeTo: packageDirectory) {
            if FileManager.default.fileExists(atPath: location.path()) {
                return location
            }
        }
        
        return nil
    }
    
    /// Creates a default configuration file in the plugin working directory
    /// - Returns: Path to the created configuration file
    private func createDefaultConfigurationFile() throws -> URL {
        let configURL = pluginWorkDirectory.appending(components: "arch-config.json")
        
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
            
            print("No configuration file found. Created default configuration at \(configURL.path())")
            printConfigFileHelp()
        }
        
        return configURL
    }
    
    /// Prints help information about creating custom configuration files
    private func printConfigFileHelp() {
        print("You can create your own configuration file at any of these locations:")
        possibleConfigLocations(relativeTo: packageDirectory).forEach { print("- \($0.path())")}
    }
}
