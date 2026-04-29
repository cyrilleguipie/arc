---
title: Effect — Lazy Async Operations in Swift
description: Arc's Effect<A> type wraps async/await in a lazy, composable value. Supports map, flatMap, zip, retry with backoff, timeout, parallel execution, and more.
tags:
  - effect
  - async await
  - concurrency
  - retry
  - timeout
  - swift
---

# Effect

```swift
public struct Effect<Output>
```

A **lazy**, composable unit of async work. Nothing runs until you call `.run()`.

This is Arc's answer to the "async/await is great but hard to compose" problem.

---

## The core idea

```swift
// Define the work:
let pipeline = Effect { try await fetchUser(id: id) }
    .flatMap { user in Effect { try await fetchOrders(userId: user.id) } }
    .map(\.total)
    .retry(3)
    .timeout(.seconds(10))

// Nothing has happened yet.

// Execute it:
let total = try await pipeline.run()
```

Effects are values. You can store them, pass them, compose them, and run them multiple times.

---

## Construction

```swift
// From an async throwing closure:
let effect = Effect { try await api.getUser(id: id) }

// Convenience:
Effect.success(42)
Effect.failure(AppError.notFound)
Effect.async { await heavyComputation() }

// From a throwing function:
effect { try parse(data) }
```

---

## Composition

### `map`

Transform the output:

```swift
fetchUser(id: id).map { $0.name }
```

### `flatMap`

Chain effects sequentially:

```swift
fetchUser(id: id)
    .flatMap { user in fetchOrders(userId: user.id) }
    .flatMap { orders in generateReport(orders: orders) }
```

### `tap`

Run a side effect without changing the output:

```swift
fetchUser(id: id)
    .tap { user in logger.info("Fetched: \(user.id)") }
    .flatMap(processUser)
```

### `mapError`

Transform the error:

```swift
fetchUser(id: id)
    .mapError { dbError in AppError.database(dbError) }
```

### `catchError`

Recover from failure:

```swift
fetchFromPrimary()
    .catchError { _ in fetchFromFallback() }
```

---

## Parallel execution

### `zip`

Run two effects concurrently:

```swift
let (user, config) = try await fetchUser(id: id)
    .zip(fetchConfig())
    .run()
```

### `Effect.all`

Run an array of effects concurrently, preserving order:

```swift
let users = try await Effect.all(ids.map { fetchUser(id: $0) }).run()
```

### `Effect.race`

Return the first to succeed:

```swift
let result = try await Effect.race([primaryAPI(), fallbackAPI()]).run()
```

### `traverseConcurrently` (on Array)

```swift
let users = try await ids.traverseConcurrently { id in fetchUser(id: id) }.run()
```

---

## Resilience

### `retry`

```swift
// Retry up to 3 times
fetchUser(id: id).retry(3)

// With a delay between attempts
fetchUser(id: id).retry(3, delay: .seconds(1))

// Only retry on specific errors
fetchUser(id: id).retry(3, when: { $0 is NetworkError })
```

### `retryWithBackoff`

Exponential backoff — doubles the delay between each attempt:

```swift
fetchUser(id: id).retryWithBackoff(
    maxAttempts: 5,
    initialDelay: .milliseconds(200),
    multiplier: 2.0,
    maxDelay: .seconds(30)
)
```

### `timeout`

```swift
heavyOperation().timeout(.seconds(10))
```

---

## Running effects

```swift
// Throws on failure:
let result = try await effect.run()

// Returns Either — never throws:
let either = await effect.runEither()  // Either<Error, Output>

// Returns a new Effect wrapping the result in Either:
let safe = effect.toEither()  // Effect<Either<Error, Output>>
```

---

## Integration with Either

```swift
// Convert an Either to an Effect
let effect: Effect<User> = fetchUser().toEffect()

// Run an Effect and get Either
let either: Either<Error, User> = await fetchUser().runEither()
```

---

## Full API reference

```swift
// Construction
init(_ run: @escaping () async throws -> Output)
static func success(_ value: Output) -> Effect
static func failure(_ error: Error) -> Effect
static func async(_ work: @escaping () async -> Output) -> Effect
static func all(_ effects: [Effect]) -> Effect<[Output]>
static func race(_ effects: [Effect]) -> Effect

// Transformations
func map<B>(_ transform: @escaping (Output) -> B) -> Effect<B>
func flatMap<B>(_ transform: @escaping (Output) -> Effect<B>) -> Effect<B>
func mapError(_ transform: @escaping (Error) -> Error) -> Effect
func catchError(_ recover: @escaping (Error) -> Effect) -> Effect
func tap(_ action: @escaping (Output) -> Void) -> Effect

// Parallelism
func zip<B>(_ other: Effect<B>) -> Effect<(Output, B)>
func zip<B, C>(_ other: Effect<B>, with transform: @escaping (Output, B) -> C) -> Effect<C>

// Resilience
func retry(_ count: Int, delay: Duration = .zero, when: ...) -> Effect
func retryWithBackoff(maxAttempts: Int, initialDelay: Duration, ...) -> Effect
func timeout(_ duration: Duration) -> Effect

// Execution
func run() async throws -> Output
func runEither() async -> Either<Error, Output>
func toEither() -> Effect<Either<Error, Output>>
```
