---
title: Either — Typed Error Handling in Swift
description: Arc's Either<Left, Right> type for typed, composable error handling in Swift. Replaces try/catch with map, flatMap, fold, and more.
tags:
  - either
  - error handling
  - functional programming
  - swift
---

# Either

```swift
public enum Either<Left, Right>
```

Represents one of two possible values. By convention:

- `.left` — failure / error
- `.right` — success / result

`Either` short-circuits on the first `.left`, making it ideal for sequential operations where you want to stop at the first error.

!!! tip "When to use Either vs Validated"
    Use `Either` when one failure is enough to abort the pipeline.  
    Use `Validated` when you want to collect **all** failures (e.g. form validation).

---

## Construction

```swift
let success: Either<String, Int> = .right(42)
let failure: Either<String, Int> = .left("not found")
```

---

## Core operations

### `map`

Transforms the right value. Leaves `.left` unchanged.

```swift
let result: Either<String, Int> = .right(5)
result.map { $0 * 2 }  // .right(10)

let failure: Either<String, Int> = .left("error")
failure.map { $0 * 2 } // .left("error")  — unchanged
```

### `flatMap`

Chains two computations that may fail. Stops at the first `.left`.

```swift
fetchUser(id: id)
    .flatMap { user in fetchOrders(userId: user.id) }
    .flatMap { orders in generateInvoice(orders: orders) }
```

### `mapLeft`

Transforms the left (error) value.

```swift
fetchUser(id: id)
    .mapLeft { dbError in AppError.database(dbError) }
```

### `fold(ifLeft:ifRight:)`

Consumes the Either and returns a single value.

```swift
let message = result.fold(
    ifLeft:  { "Error: \($0)" },
    ifRight: { "Success: \($0)" }
)
```

### `getOrElse`

Returns the right value, or a fallback.

```swift
result.getOrElse(0)
result.getOrElse { error in defaultValue(for: error) }
```

### `toOptional()`

Converts to Swift `Optional`. Left becomes `nil`.

```swift
result.toOptional() // Optional<Int>
```

---

## Async variants

All core operations have `async` counterparts:

```swift
await result.asyncMap { value in await transformAsync(value) }
await result.asyncFlatMap { value in await chainAsync(value) }
```

---

## Properties

| Property | Type | Description |
|---|---|---|
| `isLeft` | `Bool` | `true` if `.left` |
| `isRight` | `Bool` | `true` if `.right` |
| `leftValue` | `Left?` | The left value, or `nil` |
| `rightValue` | `Right?` | The right value, or `nil` |

---

## Conformances

- `Equatable` where `Left: Equatable, Right: Equatable`
- `Hashable` where `Left: Hashable, Right: Hashable`
- `Sendable` where `Left: Sendable, Right: Sendable`

---

## Full API reference

```swift
// Transformations
func map<B>(_ transform: (Right) -> B) -> Either<Left, B>
func flatMap<B>(_ transform: (Right) -> Either<Left, B>) -> Either<Left, B>
func mapLeft<B>(_ transform: (Left) -> B) -> Either<B, Right>

// Async
func asyncMap<B>(_ transform: (Right) async -> B) async -> Either<Left, B>
func asyncFlatMap<B>(_ transform: (Right) async -> Either<Left, B>) async -> Either<Left, B>

// Consuming
func fold<B>(ifLeft: (Left) -> B, ifRight: (Right) -> B) -> B
func getOrElse(_ default: Right) -> Right
func getOrElse(_ fallback: (Left) -> Right) -> Right
func toOptional() -> Right?
```
