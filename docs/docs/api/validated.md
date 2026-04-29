# Validated

```swift
public enum Validated<Failure, Success>
```

A type for validation that **accumulates errors** instead of stopping at the first failure.

This is the key difference from `Either`:

| | On first error | On multiple errors |
|---|---|---|
| `Either` | Returns immediately | Only sees the first |
| `Validated` | Continues checking | Collects **all** of them |

---

## Construction

```swift
Validated<String, Int>.valid(42)
Validated<String, Int>.invalid(["bad input"])
Validated<String, Int>.failure("bad input")  // convenience — wraps in array
```

---

## Combining validations

The real power of `Validated` is combining multiple independent checks:

### `combine`

Runs 2–4 validations in parallel and accumulates all errors:

```swift
let result = Validated<String, User>.combine(
    validateName(form.name),
    validateEmail(form.email),
    validateAge(form.age),
    with: { User(name: $0, email: $1, age: $2) }
)
```

If all pass → `.valid(user)`.  
If any fail → `.invalid([...all errors...])`.

### `zip`

Lower-level combine for two validations:

```swift
let a: Validated<String, String> = validateName(name)
let b: Validated<String, Int>    = validateAge(age)
let combined = a.zip(b)  // Validated<String, (String, Int)>
```

### `validate`

Build a `Validated` from a predicate:

```swift
Validated<String, Int>.validate(age, { $0 >= 18 }, onFailure: "Must be 18+")
```

---

## Other operations

### `map`

```swift
Validated<String, Int>.valid(5).map { $0 * 2 }  // .valid(10)
```

### `flatMap`

!!! warning
    `flatMap` on `Validated` does **not** accumulate errors — it short-circuits like `Either`.  
    Use `zip` / `combine` for true error accumulation.

### `toEither`

```swift
let result: Either<[String], User> = validated.toEither()
```

---

## Real-world example

```swift
struct RegistrationForm {
    let name: String
    let email: String
    let password: String
    let age: Int
}

func validate(_ form: RegistrationForm) -> Validated<String, User> {
    Validated.combine(
        Validated.validate(form.name,     { $0.count >= 2 },          onFailure: "Name must be at least 2 characters"),
        Validated.validate(form.email,    { $0.contains("@") },        onFailure: "Invalid email address"),
        Validated.validate(form.password, { $0.count >= 8 },           onFailure: "Password must be at least 8 characters"),
        Validated.validate(form.age,      { (18...120).contains($0) }, onFailure: "Must be at least 18 years old")
    ) { name, email, age, _ in
        User(name: name, email: email, age: age)
    }
}
```

Wait — `combine` only goes up to 4. For more fields, chain `zip`:

```swift
let nameAndEmail = validateName(name).zip(validateEmail(email))
let ageAndRole   = validateAge(age).zip(validateRole(role))
let combined     = nameAndEmail.zip(ageAndRole).map { ... }
```

---

## Full API reference

```swift
// Construction
static func failure(_ error: Failure) -> Validated
case valid(Success)
case invalid([Failure])

// Combining (error-accumulating)
func zip<B>(_ other: Validated<Failure, B>) -> Validated<Failure, (Success, B)>
static func combine<A, B>(...)    with: (A, B) -> Success) -> Validated
static func combine<A, B, C>(... with: (A, B, C) -> Success) -> Validated
static func combine<A, B, C, D>(...with: (A, B, C, D) -> Success) -> Validated
static func validate(_ value: Success, _ condition: ..., onFailure: Failure) -> Validated

// Transformations
func map<B>(_ transform: (Success) -> B) -> Validated<Failure, B>
func flatMap<B>(_ transform: (Success) -> Validated<Failure, B>) -> Validated<Failure, B>
func fold<B>(ifInvalid: ([Failure]) -> B, ifValid: (Success) -> B) -> B

// Converting
func toEither() -> Either<[Failure], Success>

// Properties
var isValid: Bool
var isInvalid: Bool
var errors: [Failure]
var value: Success?
```
