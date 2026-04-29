# Option

```swift
public enum Option<Wrapped>
```

An explicit option type with a consistent Arc API — designed for pipelines that mix `Either`, `Validated`, and optionality.

Swift's `Optional` is great, but its `map`/`flatMap` methods don't compose cleanly with Arc's other types. `Option` gives you the same power with a uniform interface.

!!! note
    `Option` and Swift's `Optional` are interchangeable. Use `Option` in Arc pipelines, `Optional` everywhere else.

---

## Construction

```swift
Option.some(42)          // .some(42)
Option<Int>.none         // .none
Option(optionalValue)    // wraps a Swift Optional
Option.of(42)            // .some(42)
```

---

## Core operations

### `map`

```swift
Option.some("hello")
    .map { $0.uppercased() }  // .some("HELLO")

Option<String>.none
    .map { $0.uppercased() }  // .none
```

### `flatMap`

```swift
Option.some("42")
    .flatMap { Int($0).toOption() }  // .some(42)

Option.some("abc")
    .flatMap { Int($0).toOption() }  // .none
```

### `filter`

```swift
Option.some(4)
    .filter { $0.isMultiple(of: 2) }  // .some(4)

Option.some(3)
    .filter { $0.isMultiple(of: 2) }  // .none
```

### `getOrElse`

```swift
Option<Int>.none.getOrElse(0)     // 0
Option.some(7).getOrElse(0)       // 7
Option<Int>.none.getOrElse { 42 } // 42
```

### `toEither`

Converts to `Either`, using a provided left value when empty.

```swift
let result: Either<String, Int> = Option.some(1).toEither("missing")
// .right(1)

let missing: Either<String, Int> = Option<Int>.none.toEither("missing")
// .left("missing")
```

---

## Full API reference

```swift
// Construction
static func of(_ value: Wrapped) -> Option<Wrapped>
static var empty: Option<Wrapped>
init(_ value: Wrapped?)

// Transformations
func map<B>(_ transform: (Wrapped) -> B) -> Option<B>
func flatMap<B>(_ transform: (Wrapped) -> Option<B>) -> Option<B>
func filter(_ predicate: (Wrapped) -> Bool) -> Option<Wrapped>

// Async
func asyncMap<B>(_ transform: (Wrapped) async -> B) async -> Option<B>
func asyncFlatMap<B>(_ transform: (Wrapped) async -> Option<B>) async -> Option<B>

// Consuming
func getOrElse(_ default: Wrapped) -> Wrapped
func getOrElse(_ fallback: () -> Wrapped) -> Wrapped
func toEither<L>(_ leftValue: @autoclosure () -> L) -> Either<L, Wrapped>
func toOptional() -> Wrapped?

// Properties
var isSome: Bool
var isNone: Bool
var value: Wrapped?
```
