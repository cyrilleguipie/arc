---
title: Swift Extensions — Optional, Result, Array & Arc
description: Arc extends Optional, Result, and Array with toEither, toEffect, toValidated, traverse, traverseValidated, traverseConcurrently, and groupBy.
tags:
  - extensions
  - optional
  - result
  - array
  - traverse
  - swift
---

# Extensions

Arc extends Swift's built-in types to integrate seamlessly into Arc pipelines.

---

## Optional

```swift
extension Optional
```

### `toEither`

```swift
let id: String? = request.params["id"]
let result: Either<AppError, String> = id.toEither(AppError.missingId)
```

### `toOption`

```swift
let option: Option<Int> = someOptional.toOption()
```

### `orThrow`

```swift
let value = try optionalValue.orThrow(AppError.missing)
```

### `ifPresent` / `ifAbsent`

Side effects without changing the value:

```swift
optionalUser
    .ifPresent { log("User found: \($0.id)") }
    .ifAbsent  { log("User not found") }
```

---

## Result

```swift
extension Result
```

### `toEither`

```swift
let either: Either<MyError, Int> = result.toEither()
```

### `toEffect`

```swift
let effect: Effect<Int> = result.toEffect()
```

### `toValidated`

```swift
let validated: Validated<MyError, Int> = result.toValidated()
```

---

## Array

```swift
extension Array
```

### `traverse` (Either)

Applies a function to each element, returning the first `.left` or all right values.

```swift
let result: Either<AppError, [User]> = ids.traverse { id in
    fetchUser(id: id)
}
```

### `traverseValidated`

Applies a function to each element and **accumulates all errors**:

```swift
let result: Validated<String, [User]> = inputs.traverseValidated { input in
    validate(input)
}
// result.errors contains all validation failures
```

### `traverse` (Effect — sequential)

```swift
let effect: Effect<[User]> = ids.traverse { id in
    fetchUser(id: id)  // runs one at a time
}
```

### `traverseConcurrently` (Effect — parallel)

```swift
let effect: Effect<[User]> = ids.traverseConcurrently { id in
    fetchUser(id: id)  // runs all at once
}
```

### `toNonEmpty`

```swift
let nea: NonEmptyArray<Int>? = [1, 2, 3].toNonEmpty()
```

### `groupBy`

```swift
let grouped: [String: [User]] = users.groupBy { $0.role }
```

---

## Free functions

### `catching`

Converts a throwing closure to `Either<Error, R>`:

```swift
let result: Either<Error, Data> = catching { try Data(contentsOf: url) }
```

Async version:

```swift
let result: Either<Error, Data> = await catching { try await download(url) }
```

### `effect`

Wraps a throwing closure in an `Effect`:

```swift
let e: Effect<Data> = effect { try Data(contentsOf: url) }
let eAsync: Effect<Data> = effect { try await download(url) }
```
