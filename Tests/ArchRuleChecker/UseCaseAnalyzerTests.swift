import Testing
import SwiftSyntax
@testable import ArchRuleChecker

@Suite("UseCaseAnalyzerTests")
struct UseCaseAnalyzerTests {
    let modelTypes = ["Entity", "Model", "ValueObject"]
    
    @Test("Non-violating UseCase should have no violations")
    func testNonViolatingUseCase() {
        let source = """
        class LoginUseCase {
            func execute(username: String, password: String) -> LoginResponse {
                return LoginResponse(token: "abc123")
            }
        }
        
        struct LoginResponse {
            let token: String
        }
        """
        
        let violations = UseCaseAnalyzer.analyze(
            sourceCode: source,
            fileName: "LoginUseCase.swift",
            modelTypes: modelTypes
        )
        
        #expect(violations.count == 0)
    }
    
    @Test("UseCase exposing Entity should have a violation")
    func testViolatingUseCase() {
        let source = """
        class GetUserUseCase {
            func execute(userId: String) -> UserEntity {
                return UserEntity(id: userId, name: "John")
            }
        }
        
        class UserEntity {
            let id: String
            let name: String
            
            init(id: String, name: String) {
                self.id = id
                self.name = name
            }
        }
        """
        
        let violations = UseCaseAnalyzer.analyze(
            sourceCode: source,
            fileName: "GetUserUseCase.swift",
            modelTypes: modelTypes
        )
        
        #expect(violations.count == 1)
        if let violation = violations.first {
            if case let .useCaseExposingModelObject(useCaseName, methodName, returnType) = violation {
                #expect(useCaseName == "GetUserUseCase")
                #expect(methodName == "execute")
                #expect(returnType == "UserEntity")
            } else {
                #expect(Bool(false), "Wrong violation type")
            }
        }
    }
    
    @Test("Result-wrapped entity should have a violation")
    func testResultWrappedType() {
        let source = """
        class FetchOrderUseCase {
            func execute(orderId: String) -> Result<OrderEntity, Error> {
                return .success(OrderEntity())
            }
        }
        
        class OrderEntity {}
        """
        
        let violations = UseCaseAnalyzer.analyze(
            sourceCode: source,
            fileName: "FetchOrderUseCase.swift",
            modelTypes: modelTypes
        )
        
        #expect(violations.count == 1)
    }
    
    @Test("Response types should not violate the rule")
    func testResponseDoesntViolate() {
        let source = """
        class GetProductUseCase {
            func execute(productId: String) -> ProductResponse {
                let entity = ProductEntity()
                return ProductResponse(id: entity.id, name: entity.name)
            }
        }
        
        struct ProductResponse {
            let id: String
            let name: String
        }
        
        class ProductEntity {
            let id: String = "123"
            let name: String = "Product"
        }
        """
        
        let violations = UseCaseAnalyzer.analyze(
            sourceCode: source,
            fileName: "GetProductUseCase.swift",
            modelTypes: modelTypes
        )
        
        #expect(violations.count == 0)
    }
}
