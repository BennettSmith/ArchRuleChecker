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
