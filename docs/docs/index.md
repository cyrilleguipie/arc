# Arc

<div align="center" markdown>

**Pragmatic functional programming for Swift.**  
Async-first. Production-ready. Native.

[Get Started](getting-started/installation.md){ .md-button .md-button--primary }
[View on GitHub](https://github.com/yourorg/arc){ .md-button }

</div>

---

## The problem

Swift has `Optional`. Swift has `Result`. Swift has `async/await`.  
But it doesn't have a consistent, ergonomic story for **composing** all of these.

You end up with guard ladders:

```swift
guard let user = try? await fetchUser(id) else { return }
guard case .success(let valid) = validate(user) else { return }
let saved = try await save(valid)
```

Or nested closures. Or scattered `do/catch`. Or missing errors entirely.

## The solution

Arc gives you a unified language for typed errors, validation, and async — designed to feel native to Swift, not ported from Haskell:

```swift
fetchUser(id: id)
    .flatMap(validate)
    .flatMap(save)
    .map(transform)
```

## Core types at a glance

| Type | Use when |
|---|---|
| [`Either<L, R>`](api/either.md) | A computation that can fail with a typed error |
| [`Option<A>`](api/option.md) | An explicit, pipeable optional |
| [`Validated<E, A>`](api/validated.md) | Collecting **all** validation failures |
| [`NonEmptyArray<A>`](api/non-empty-array.md) | A list that is guaranteed non-empty |
| [`Effect<A>`](api/effect.md) | A lazy, composable async operation |

## Quick example

```swift
// Validate all fields at once — see every error, not just the first
let result = Validated<String, User>.combine(
    validateName(form.name),
    validateEmail(form.email),
    validateAge(form.age),
    with: User.init
)

switch result {
case .valid(let user):   save(user)
case .invalid(let errs): showErrors(errs)
}
```

```swift
// Chain async operations with typed errors
let effect = fetchUser(id: id)
    .flatMap(fetchOrders)
    .flatMap(generateInvoice)
    .retry(3)
    .timeout(.seconds(10))

let invoice = try await effect.run()
```

```swift
// Sequential pipeline with early exit
let result: Either<AppError, Receipt> = await either { ctx in
    let user    = try ctx.bind(await fetchUser(id))
    let order   = try ctx.bind(await createOrder(user: user))
    return       try ctx.bind(await processPayment(order: order))
}
```
