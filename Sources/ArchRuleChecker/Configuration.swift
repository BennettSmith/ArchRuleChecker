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