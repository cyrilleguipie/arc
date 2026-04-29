# Async Pipelines

Arc's `Effect` type makes async operations composable, lazy, and resilient.

---

## Sequential operations

Each step waits for the previous:

```swift
let pipeline = fetchUser(id: userId)
    .flatMap { user in fetchOrders(userId: user.id) }
    .flatMap { orders in generateReport(orders: orders) }
    .flatMap { report in sendEmail(report: report) }

let result = try await pipeline.run()
```

---

## Parallel operations

### Two effects in parallel with `zip`

```swift
let (user, settings) = try await fetchUser(id: id)
    .zip(fetchSettings(userId: id))
    .run()
```

Both `fetchUser` and `fetchSettings` start at the same time. The result waits for both.

### Many effects in parallel with `Effect.all`

```swift
let users = try await Effect.all(
    ids.map { fetchUser(id: $0) }
).run()
// users is in the same order as ids
```

### Parallel traversal from an array

```swift
let orders = try await orderIds
    .traverseConcurrently { id in fetchOrder(id: id) }
    .run()
```

---

## Mixed sequential + parallel

```swift
// 1. Fetch user (sequential — need it for step 2)
// 2. Fetch user's orders AND profile picture in parallel
// 3. Combine into a dashboard

let dashboard = fetchUser(id: userId)
    .flatMap { user in
        fetchOrders(userId: user.id)
            .zip(fetchAvatar(userId: user.id))
            .map { orders, avatar in Dashboard(user: user, orders: orders, avatar: avatar) }
    }
    .run()
```

---

## Resilience

### Retry with delay

```swift
fetchUser(id: id)
    .retry(3, delay: .seconds(1))
```

### Exponential backoff

```swift
fetchUser(id: id)
    .retryWithBackoff(
        maxAttempts: 5,
        initialDelay: .milliseconds(100),
        multiplier: 2.0,
        maxDelay: .seconds(30)
    )
```

### Timeout

```swift
heavyComputation()
    .timeout(.seconds(10))
```

### Fallback on error

```swift
fetchFromPrimary()
    .catchError { _ in fetchFromReplica() }
```

---

## Testing Effects

Effects are values — inject them:

```swift
struct UserService {
    var fetchUser: (String) -> Effect<User>

    func profile(id: String) -> Effect<Profile> {
        fetchUser(id).map(Profile.init)
    }
}

// In tests:
let service = UserService(fetchUser: { _ in .success(mockUser) })
let profile = try await service.profile(id: "1").run()
```

---

## Full pipeline example

```swift
struct CheckoutService {
    func checkout(cartId: String, userId: String) -> Effect<Order> {
        Effect { try await fetchCart(id: cartId) }
            .zip(Effect { try await fetchUser(id: userId) })
            .flatMap { cart, user in
                Effect { try await validateInventory(cart: cart) }
                    .map { _ in (cart, user) }
            }
            .flatMap { cart, user in
                Effect { try await chargePayment(user: user, amount: cart.total) }
                    .map { paymentId in (cart, user, paymentId) }
            }
            .flatMap { cart, user, paymentId in
                Effect { try await createOrder(cart: cart, user: user, paymentId: paymentId) }
            }
            .tap { order in analytics.track("order_created", id: order.id) }
            .retry(2)
            .timeout(.seconds(30))
    }
}
```
