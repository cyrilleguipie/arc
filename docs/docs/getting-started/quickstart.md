---
title: Quick Start — Arc Functional Swift Library
description: Learn Arc in 5 minutes. Replace guard chains with Either, validate forms with Validated, build async pipelines with Effect, and use the either { } DSL.
tags:
  - quickstart
  - tutorial
  - either
  - validated
  - effect
---

# Quick Start

This guide walks you through the most common Arc patterns in 5 minutes.

## 1. Replace guard chains with `Either`

=== "Before (Swift)"

    ```swift
    func loadUserProfile(id: String) async throws -> Profile {
        guard let user = try? await fetchUser(id: id) else {
            throw AppError.notFound
        }
        guard let profile = try? await fetchProfile(userId: user.id) else {
            throw AppError.notFound
        }
        return profile
    }
    ```

=== "After (Arc)"

    ```swift
    func loadUserProfile(id: String) -> Effect<Profile> {
        fetchUser(id: id)
            .flatMap { user in fetchProfile(userId: user.id) }
    }
    ```

## 2. Validate forms with `Validated`

```swift
import Arc

func validateRegistration(name: String, email: String, age: Int) -> Validated<String, User> {
    Validated.combine(
        Validated.validate(name, { $0.count >= 2 }, onFailure: "Name too short"),
        Validated.validate(email, { $0.contains("@") }, onFailure: "Invalid email"),
        Validated.validate(age, { (18...120).contains($0) }, onFailure: "Must be 18+"),
        with: { User(name: $0, email: $1, age: $2) }
    )
}

let result = validateRegistration(name: "A", email: "notanemail", age: 15)
// result.errors == ["Name too short", "Invalid email", "Must be 18+"]
```

Unlike `Result`, `Validated` collects **all** errors — not just the first.

## 3. Build async pipelines with `Effect`

```swift
import Arc

struct UserService {
    func register(input: RegistrationInput) -> Effect<User> {
        Effect { try await api.createUser(input) }
            .flatMap { user in Effect { try await email.sendWelcome(to: user) }.map { _ in user } }
            .retry(3, delay: .seconds(1))
            .timeout(.seconds(30))
    }
}

// In your view model or controller:
let user = try await service.register(input: form).run()
```

## 4. Short-circuit pipelines with the `either { }` DSL

```swift
import Arc

let result: Either<AppError, Invoice> = await either { ctx in
    let user    = try ctx.bind(await fetchUser(id: userId))
    let cart    = try ctx.bind(await fetchCart(userId: user.id))
    let payment = try ctx.bind(await processPayment(cart: cart))
    return       try ctx.bind(await generateInvoice(payment: payment))
}

switch result {
case .right(let invoice): present(invoice)
case .left(let error):    showError(error)
}
```

Each `ctx.bind(...)` exits early if the Either is `.left`. No `try/catch`. No nested `guard`.

## 5. Extend built-in types

Arc adds ergonomic methods to `Optional`, `Result`, and `Array`:

```swift
// Optional → Either
let id: String? = request.params["id"]
let result = id.toEither(AppError.missingId)

// Result → Effect
let effect = Result { try parseJSON(data) }.toEffect()

// Array → parallel traversal
let users = try await ids.traverseConcurrently { id in
    fetchUser(id: id)
}.run()
```

---

## Next steps

- [Either in depth](../api/either.md)
- [Validated for form validation](../api/validated.md)
- [Effect system](../api/effect.md)
- [either { } DSL](../api/either-dsl.md)
