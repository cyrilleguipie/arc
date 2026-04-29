# either { } DSL

The `either { }` function provides a structured, readable way to write sequential `Either`-based pipelines without nested `flatMap` calls.

Inspired by Arrow's `either { }` for Kotlin — rebuilt natively for Swift.

---

## Basic usage

```swift
import Arc

let result: Either<AppError, Receipt> = either { ctx in
    let user    = try ctx.bind(fetchUser(id: userId))
    let order   = try ctx.bind(createOrder(user: user))
    let payment = try ctx.bind(processPayment(order: order))
    return try ctx.bind(generateReceipt(payment: payment))
}
```

If any `ctx.bind(...)` receives a `.left`, the block exits immediately and `result` becomes that `.left`. Otherwise, `result` is `.right` with the returned value.

---

## Async variant

```swift
let result: Either<AppError, User> = await either { ctx in
    let raw  = try ctx.bind(await parseRequest(req))
    let user = try ctx.bind(await fetchUser(id: raw.id))
    return user
}
```

---

## Binding optionals

```swift
let result: Either<String, Int> = either { ctx in
    let rawId = try ctx.bind(request.query["id"], orFailWith: "Missing id")
    let id    = try ctx.bind(Int(rawId), orFailWith: "Id must be an integer")
    return id
}
```

---

## Comparison with flatMap

These are equivalent:

=== "either { }"

    ```swift
    let result: Either<AppError, String> = either { ctx in
        let user  = try ctx.bind(fetchUser(id: id))
        let order = try ctx.bind(fetchOrder(userId: user.id))
        return order.summary
    }
    ```

=== "flatMap"

    ```swift
    let result: Either<AppError, String> =
        fetchUser(id: id)
            .flatMap { user in fetchOrder(userId: user.id) }
            .map { $0.summary }
    ```

The DSL shines when you need intermediate values from multiple steps, or when naming each step improves clarity.

---

## API

```swift
// Synchronous
public func either<L, R>(_ body: (EitherContext<L>) throws -> R) -> Either<L, R>

// Asynchronous
public func either<L, R>(_ body: @escaping (EitherContext<L>) async throws -> R) async -> Either<L, R>

// EitherContext methods
func bind<Success>(_ either: Either<Failure, Success>) throws -> Success
func bind<Success>(_ optional: Success?, orFailWith error: @autoclosure () -> Failure) throws -> Success
```
