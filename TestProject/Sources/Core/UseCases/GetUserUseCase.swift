import Foundation

class GetUserUseCase {
    private let userRepository: UserRepository
    
    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }
    
    // This violates the rule - directly exposing a model object
    func execute(userId: String) -> UserEntity {
        return userRepository.getUser(byId: userId)
    }
}
