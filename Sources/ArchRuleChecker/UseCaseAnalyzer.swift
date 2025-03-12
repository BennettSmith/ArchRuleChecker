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
