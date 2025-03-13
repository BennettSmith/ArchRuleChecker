import Foundation

class ListUsersUseCase: UseCase {
    private let userRepository: UserRepository
    
    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }
    
    // This follows the rule - using a response object
    func execute() -> [UserListResponse] {
        let users = userRepository.getAllUsers()
        return users.map { UserListResponse(id: $0.id, name: $0.name) }
    }
}

struct UserListResponse {
    let id: String
    let name: String
}
