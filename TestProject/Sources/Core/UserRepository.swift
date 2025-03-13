import Foundation

protocol UserRepository {
    func getUser(byId id: String) -> UserEntity
    func getAllUsers() -> [UserEntity]
}
