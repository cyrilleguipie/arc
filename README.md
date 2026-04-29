<p align="center">
  <img src="docs/docs/assets/arc-logo.svg" width="120" alt="Arc logo" />
</p>

<h1 align="center">Arc</h1>

<p align="center">
  <strong>Pragmatic functional programming for Swift.</strong><br/>
  Async-first. Production-ready. Native.
</p>

<p align="center">
  <a href="https://swiftpackageindex.com/yourorg/arc">
    <img src="https://img.shields.io/badge/Swift-6.0+-orange?logo=swift" alt="Swift 6+" />
  </a>
  <a href="https://swiftpackageindex.com/yourorg/arc">
    <img src="https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-blue" alt="Platforms" />
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License" />
  </a>
</p>

---

## Why Arc?

Swift has `Optional`. Swift has `Result`. Swift has `async/await`.  
But it doesn't have a consistent, ergonomic story for **composing** all of these.

You end up with:

```swift
guard let user = try? await fetchUser(id) else { return }
guard case .success(let validated) = validate(user) else { return }
let saved = try await save(validated)
```

Or worse — deeply nested closures and scattered error handling.

Arc gives you a **unified language** for async, typed errors, and validation — designed to feel native to Swift, not ported from Haskell.

```swift
fetchUser(id: id)
    .flatMap(validate)
    .flatMap(save)
    .map(transform)
```

---

## Arc vs Bow vs Arrow

| | **Arc** | **Bow** | **Arrow (Kotlin)** |
|---|---|---|---|
| Language | Swift | Swift | Kotlin |
| Async model | `async/await` native | RxSwift / Combine | Coroutines |
| API style | Swift-idiomatic | Haskell-inspired | Scala-inspired |
| Higher-kinded types | No | Yes | Yes |
| Learning curve | Low | High | Medium |
| Production ready | Yes | Abandoned | Yes |
| iOS / Vapor | Yes | iOS only | JVM only |

**Bow** was a bold idea but required you to learn category theory before writing a network call. It was also abandoned in 2022.

**Arrow** is excellent — for Kotlin. Arc takes its best ideas and rebuilds them for Swift's type system and concurrency model.

Arc's north star: **a junior developer should be able to read Arc code on day one.**

---

## Installation

### Swift Package Manager

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/cyrilleguipie/arc.git", from: "1.0.0")
],
targets: [
    .target(name: "MyApp", dependencies: ["Arc"])
]
```

### Xcode

**File → Add Package Dependencies** → paste the repository URL.

---

## Core Types

### `Either<Left, Right>`

Represents one of two values. By convention, `left` = failure, `right` = success.

```swift
func fetchUser(id: String) -> Either<UserError, User> {
    guard let user = db.find(id) else {
        return .left(.notFound(id))
    }
    return .right(user)
}

fetchUser(id: "42")
    .map { $0.name.uppercased() }
    .flatMap(validateName)
    .getOrElse("Unknown")
```

**Key operations:**

| Method | Description |
|---|---|
| `map` | Transform the right value |
| `flatMap` | Chain computations |
| `mapLeft` | Transform the left value |
| `fold(ifLeft:ifRight:)` | Handle both sides |
| `getOrElse` | Unwrap or use a default |
| `toOptional()` | Convert to Swift Optional |

---

### `Option<A>`

An explicit option type with a consistent API matching `Either` and `Validated`.  
Use when you want pipeline symmetry across all Arc types.

```swift
Option(user.profilePhoto)
    .map(resize)
    .filter(isValidSize)
    .getOrElse(defaultAvatar)
```

---

### `Validated<Failure, Success>`

Unlike `Either`, `Validated` **accumulates errors** instead of stopping at the first one.  
Essential for form validation.

```swift
let result = Validated<String, User>.combine(
    validateName(input.name),
    validateEmail(input.email),
    validateAge(input.age),
    with: { User(name: $0, email: $1, age: $2) }
)

switch result {
case .valid(let user):
    save(user)
case .invalid(let errors):
    showErrors(errors) // ["Name too short", "Invalid email"]
}
```

**Key operations:**

| Method | Description |
|---|---|
| `zip` | Combine two, accumulating errors |
| `combine(_:_:with:)` | Combine 2–4, accumulating errors |
| `validate(_:_:onFailure:)` | Build from a predicate |
| `.failure("msg")` | Single-error convenience |

---

### `NonEmptyArray<A>`

An array guaranteed to contain at least one element. All operations are safe — no force-unwraps.

```swift
let tags: NonEmptyArray<String> = ["swift", "functional", "arc"]
let uppercased = tags.map { $0.uppercased() }
print(tags.first)  // "swift" — not optional
print(tags.last)   // "arc"   — not optional
```

---

### `Effect<A>`

A **lazy**, composable unit of async work. Nothing runs until you call `.run()`.

```swift
let pipeline = Effect { try await fetchUser(id: "42") }
    .flatMap { user in Effect { try await validate(user) } }
    .flatMap { user in Effect { try await save(user) } }
    .retry(3)
    .timeout(.seconds(10))

// Nothing has happened yet — run it:
let user = try await pipeline.run()
```

**Key operations:**

| Method | Description |
|---|---|
| `map` | Transform the output |
| `flatMap` | Chain effects sequentially |
| `zip` | Run two effects in parallel |
| `Effect.all([...])` | Run many effects in parallel |
| `retry(_:delay:)` | Retry on failure |
| `retryWithBackoff(...)` | Exponential backoff |
| `timeout(_:)` | Fail after a duration |
| `catchError` | Recover from failure |
| `tap` | Side effect without changing output |
| `runEither()` | Run and get `Either<Error, A>` |

---

## The `either { }` DSL

For sequential pipelines where you want to short-circuit on the first failure:

```swift
let result: Either<UserError, Receipt> = either { ctx in
    let user    = try ctx.bind(fetchUser(id: id))
    let product = try ctx.bind(fetchProduct(sku: sku))
    let order   = try ctx.bind(createOrder(user: user, product: product))
    return try ctx.bind(processPayment(order: order))
}
```

If any step returns `.left(...)`, the block exits immediately and the left value is returned.  
Same idea as Kotlin Arrow's `either { }` — adapted natively for Swift.

Async version works the same way:

```swift
let result: Either<UserError, User> = await either { ctx in
    let raw  = try ctx.bind(await parseRequest())
    let user = try ctx.bind(await fetchUser(raw.id))
    return user
}
```

---

## Extensions

Arc extends Swift's built-in types to integrate seamlessly:

```swift
// Optional → Either
let userId: String? = request.query["id"]
let result = userId.toEither(AppError.missingId)

// Result → Either / Effect
let either = Result { try parse(data) }.toEither()
let effect = Result { try parse(data) }.toEffect()

// Array traversal — stop at first error
let users = ids.traverse { id in fetchUser(id: id) }

// Array traversal — accumulate all errors
let validated = inputs.traverseValidated { input in validate(input) }

// Parallel concurrent traversal
let results = ids.traverseConcurrently { id in fetchUser(id: id) }
```

---

## Real-world example

```swift
struct UserService {
    func register(name: String, email: String, age: Int) -> Effect<User> {
        // 1. Validate all fields at once, accumulate errors
        let validation = Validated<String, UserInput>.combine(
            validateName(name),
            validateEmail(email),
            validateAge(age),
            with: UserInput.init
        )

        // 2. Convert to Effect and chain async operations
        return validation
            .toEither()
            .mapLeft { AppError.validation($0) }
            .toEffect()
            .flatMap { input in self.checkEmailUnique(input.email).map { _ in input } }
            .flatMap { input in self.createUser(from: input) }
            .flatMap { user  in self.sendWelcomeEmail(to: user).map { _ in user } }
            .retry(2)
    }
}
```

---

## Requirements

| Platform | Minimum |
|---|---|
| iOS | 16.0 |
| macOS | 13.0 |
| tvOS | 16.0 |
| watchOS | 9.0 |
| Swift | 5.9+ |

---

## Philosophy

Arc is built on three beliefs:

**1. Pragmatism over purity.** No higher-kinded types. No typeclasses. Just Swift.

**2. Async is the default.** Every type in Arc works naturally with `async/await` and Swift Concurrency.

**3. The API should explain itself.** If you need to read the docs to understand what `.flatMap` does on an `Either`, the API has failed.

---

## License

MIT — see [LICENSE](LICENSE).
