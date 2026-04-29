---
title: Philosophy — Why Arc Exists
description: Arc is built on three principles — pragmatism over purity, async as the default, and APIs that explain themselves. Learn why Arc takes a different approach from Bow and Arrow.
tags:
  - philosophy
  - functional programming
  - bow
  - arrow
  - swift
---

# Philosophy

## Why Arc exists

Functional programming has a proven track record for building reliable software. Types that make illegal states unrepresentable, composable error handling, explicit effects — these ideas work.

But most FP libraries for Swift carry baggage from Haskell or Scala. They introduce jargon (`Monad`, `Applicative`, `Functor`), complex abstractions (higher-kinded types, typeclasses), and APIs that feel foreign to Swift developers.

The result: the people who need FP tools most — the developers writing iOS apps and Vapor services — don't use them, because the learning curve is too steep.

Arc exists to solve this. It takes the *ideas* that matter and expresses them in idiomatic Swift.

---

## The three principles

### 1. Pragmatism over purity

Arc is not trying to be a Haskell port. There are no `Monad` typeclasses. There is no higher-kinded type machinery. There are no free theorems.

What Arc does instead: take the useful subset of FP — typed errors, error accumulation, lazy effects — and implement them in a way that Swift developers will recognize and adopt immediately.

If you've used `Optional.map` in Swift, you already understand `Either.map`. That's intentional.

### 2. Async is the default

Swift's `async/await` is exceptional. Arc is built on top of it, not around it.

Every type in Arc works naturally with Swift Concurrency. `Effect` is just `async throws` in a value type. `asyncMap` and `asyncFlatMap` are first-class operations on every core type.

Arc doesn't add a parallel concurrency system — it enhances the one Swift already has.

### 3. The API should explain itself

A developer reading Arc code for the first time shouldn't need to look anything up.

- `fetchUser.flatMap(validate).flatMap(save)` — obvious.
- `combine(validateName, validateEmail, validateAge, with: User.init)` — obvious.
- `effect.retry(3).timeout(.seconds(10)).run()` — obvious.

If an Arc API requires reading documentation to understand what it does, it's a design failure.

---

## Comparison with alternatives

### vs Bow

Bow was a serious attempt to bring full category theory to Swift. It succeeded technically but failed practically: almost no one used it in production, and it was abandoned in 2022.

Arc learned from Bow's mistakes:
- No higher-kinded types
- No typeclass hierarchy
- No `Kind<F, A>` encodings
- APIs named after what they do, not what monad they implement

### vs Arrow (Kotlin)

Arrow is excellent — for Kotlin. It's battle-tested, widely adopted, and thoughtfully designed.

Arc is philosophically aligned with Arrow's goals but different in implementation:
- Swift's type system is not Kotlin's — Arc doesn't try to copy Arrow's API directly
- Arc uses `async/await` instead of coroutines
- Arc avoids the complexity of Arrow's effect system (which relies on Kotlin's compiler plugin)

### vs Combine / RxSwift

Combine and RxSwift solve reactive programming — streams of values over time.

Arc solves compositional error handling and async operations — single values with typed failures.

They're complementary, not competing.

---

## The goal

Arc's north star is simple: become the standard for functional programming in Swift.

Not by being the most theoretically complete. Not by supporting every FP abstraction. But by being the library that developers actually reach for — because it solves real problems, speaks Swift, and gets out of the way.
