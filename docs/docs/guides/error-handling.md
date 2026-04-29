---
title: Functional Error Handling in Swift — Beyond try/catch
description: Replace Swift's try/catch with composable, typed error handling using Arc's Either and Effect. Convert Optional, Result, and throwing functions into pipelines.
tags:
  - error handling
  - either
  - effect
  - swift
  - vapor
---

# Error Handling

Arc replaces scattered `try/catch` blocks with a composable, typed approach.

---

## The problem with try/catch

```swift
func processOrder(userId: String, productId: String) async throws -> Receipt {
    let user: User
    do {
        user = try await fetchUser(id: userId)
    } catch {
        throw AppError.userNotFound(userId)
    }

    let product: Product
    do {
        product = try await fetchProduct(id: productId)
    } catch {
        throw AppError.productNotFound(productId)
    }

    // ... more try/catch nesting ...
}
```

Problems:

- Error type is `Error` (untyped at the call site)
- Easy to accidentally swallow errors
- Hard to compose or test
- Doesn't scale to parallel operations

---

## Arc's approach: `Either`

```swift
func processOrder(userId: String, productId: String) -> Effect<Receipt> {
    fetchUser(id: userId)
        .flatMap { user in fetchProduct(id: productId).map { (user, $0) } }
        .flatMap { user, product in createOrder(user: user, product: product) }
        .flatMap { order in processPayment(order: order) }
        .flatMap { payment in generateReceipt(payment: payment) }
}
```

The error type is explicit in the return type. No hidden exceptions.

---

## Converting existing code

### Optional → Either

```swift
// Before
guard let user = db.find(id) else { throw AppError.notFound }

// After
let result: Either<AppError, User> = db.find(id).toEither(AppError.notFound)
```

### Result → Either

```swift
let either: Either<MyError, Data> = result.toEither()
```

### Throwing function → Either

```swift
let either: Either<Error, Data> = catching { try Data(contentsOf: url) }
```

### Throwing function → Effect

```swift
let effect: Effect<Data> = effect { try Data(contentsOf: url) }
```

---

## Handling errors at the boundary

Arc pipelines produce typed errors. Handle them at the top level — view model, controller, or use case:

```swift
// SwiftUI ViewModel
func loadProfile() async {
    let result = await fetchProfile(userId: currentUser.id).runEither()
    switch result {
    case .right(let profile): self.profile = profile
    case .left(let error):    self.errorMessage = error.localizedDescription
    }
}
```

```swift
// Vapor route
app.get("users", ":id") { req async throws -> User in
    let id = try req.parameters.require("id")
    return try await fetchUser(id: id)
        .mapError { _ in Abort(.notFound) }
        .run()
}
```

---

## Error transformation

Transform errors as they cross layer boundaries:

```swift
// Database layer returns DatabaseError
// Service layer returns ServiceError
// API layer returns HTTPError

func getUser(id: String) -> Effect<User> {
    database.find(id)
        .mapError { dbErr in ServiceError.userNotFound(id, cause: dbErr) }
}

func handleRequest(_ req: Request) -> Effect<Response> {
    getUser(id: req.params.id)
        .mapError { serviceErr in HTTPError.from(serviceErr) }
        .map { user in Response(body: user.json) }
}
```
