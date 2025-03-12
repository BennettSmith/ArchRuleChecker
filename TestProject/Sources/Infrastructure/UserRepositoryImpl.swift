import Foundation

class UserRepositoryImpl: UserRepository {
    func getUser(byId id: String) -> UserEntity {
        return UserEntity(id: id, name: "Test User")
    }
    
    func getAllUsers() -> [UserEntity] {
        return [
            UserEntity(id: "1", name: "User 1"),
            UserEntity(id: "2", name: "User 2")
        ]
    }
}
