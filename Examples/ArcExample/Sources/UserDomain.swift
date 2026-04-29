import Arc
import Foundation

// MARK: - Domain model

struct User: Sendable {
    let id: String
    let name: String
    let email: String
    let age: Int
}

enum UserError: Error, CustomStringConvertible {
    case notFound(String)
    case invalidInput(String)
    case networkError(String)

    var description: String {
        switch self {
        case .notFound(let id): return "User not found: \(id)"
        case .invalidInput(let msg): return "Invalid input: \(msg)"
        case .networkError(let msg): return "Network error: \(msg)"
        }
    }
}

// MARK: - Validation

func validateName(_ name: String) -> Validated<String, String> {
    Validated.validate(name, { $0.count >= 2 }, onFailure: "Name must be at least 2 characters")
}

func validateEmail(_ email: String) -> Validated<String, String> {
    Validated.validate(email, { $0.contains("@") }, onFailure: "Email must contain @")
}

func validateAge(_ age: Int) -> Validated<String, Int> {
    Validated.validate(age, { (0...120).contains($0) }, onFailure: "Age must be between 0 and 120")
}

func validateUser(name: String, email: String, age: Int) -> Validated<String, User> {
    Validated.combine(
        validateName(name),
        validateEmail(email),
        validateAge(age),
        with: { User(id: UUID().uuidString, name: $0, email: $1, age: $2) }
    )
}

// MARK: - Repository (Effect-based)

struct UserRepository {
    func fetchUser(id: String) -> Effect<User> {
        Effect {
            // Simulate async network call
            try await Task.sleep(for: .milliseconds(10))
            guard id != "invalid" else { throw UserError.notFound(id) }
            return User(id: id, name: "Alice", email: "alice@example.com", age: 30)
        }
    }

    func saveUser(_ user: User) -> Effect<User> {
        Effect {
            try await Task.sleep(for: .milliseconds(10))
            return user
        }
    }
}

// MARK: - Use case: fetch, validate, save

struct UserService {
    let repo = UserRepository()

    func updateUser(id: String, newName: String) -> Effect<User> {
        repo.fetchUser(id: id)
            .flatMap { user in
                let validated = validateName(newName)
                switch validated {
                case .invalid(let errors):
                    return Effect.failure(UserError.invalidInput(errors.joined(separator: ", ")))
                case .valid(let name):
                    let updated = User(id: user.id, name: name, email: user.email, age: user.age)
                    return self.repo.saveUser(updated)
                }
            }
            .retry(3)
    }
}

// MARK: - DSL example

func exampleDSL(id: String) async -> Either<UserError, User> {
    let repo = UserRepository()

    return await either { ctx in
        let user = try ctx.bind(await repo.fetchUser(id: id).runEither().mapLeft { _ in UserError.notFound(id) })
        let _ = try ctx.bind(
            validateName(user.name)
                .toEither()
                .mapLeft { UserError.invalidInput($0.joined(separator: ", ")) }
        )
        return user
    }
}

// MARK: - Parallel fetch

func fetchMultipleUsers(ids: [String]) -> Effect<[User]> {
    let repo = UserRepository()
    return ids.traverseConcurrently { id in repo.fetchUser(id: id) }
}
