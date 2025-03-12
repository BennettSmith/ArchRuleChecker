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
