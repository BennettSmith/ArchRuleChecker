import Foundation
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
