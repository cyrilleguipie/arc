---
title: Form Validation in Swift and SwiftUI with Validated
description: Collect all form errors at once using Arc's Validated type in Swift and SwiftUI. No more showing one error at a time — accumulate every field failure.
tags:
  - form validation
  - validated
  - swiftui
  - swift
---

# Form Validation

`Validated` is built for this exact use case: collecting every field error at once, so users don't have to submit a form multiple times.

---

## The pattern

```
User input → validate each field → combine errors → show all at once
```

---

## Basic example

```swift
import Arc

struct RegistrationInput {
    let name: String
    let email: String
    let password: String
    let age: Int
}

struct User {
    let name: String
    let email: String
    let age: Int
}

func validateRegistration(_ input: RegistrationInput) -> Validated<String, User> {
    Validated.combine(
        Validated.validate(input.name,     { $0.count >= 2 },           onFailure: "Name must be at least 2 characters"),
        Validated.validate(input.email,    { $0.contains("@") },         onFailure: "Email is invalid"),
        Validated.validate(input.age,      { (18...120).contains($0) },  onFailure: "Must be at least 18 years old"),
        with: { name, email, age in User(name: name, email: email, age: age) }
    )
}
```

---

## Using in a SwiftUI ViewModel

```swift
import Arc
import SwiftUI

@MainActor
class RegistrationViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var ageText = ""
    @Published var errors: [String] = []
    @Published var isSubmitting = false

    func submit() async {
        let age = Int(ageText) ?? -1
        let validation = validateRegistration(RegistrationInput(
            name: name,
            email: email,
            password: "",
            age: age
        ))

        switch validation {
        case .invalid(let errs):
            errors = errs  // show ALL errors at once
        case .valid(let user):
            errors = []
            isSubmitting = true
            await save(user)
            isSubmitting = false
        }
    }

    private func save(_ user: User) async {
        _ = try? await Effect { try await api.createUser(user) }
            .retry(2)
            .run()
    }
}
```

---

## Composing validators

Build reusable validators and compose them:

```swift
enum ValidationError: String {
    case tooShort       = "Too short"
    case tooLong        = "Too long"
    case invalidFormat  = "Invalid format"
    case alreadyTaken   = "Already taken"
}

func minLength(_ min: Int) -> (String) -> Validated<ValidationError, String> {
    { value in Validated.validate(value, { $0.count >= min }, onFailure: .tooShort) }
}

func maxLength(_ max: Int) -> (String) -> Validated<ValidationError, String> {
    { value in Validated.validate(value, { $0.count <= max }, onFailure: .tooLong) }
}

func matches(_ regex: String) -> (String) -> Validated<ValidationError, String> {
    { value in
        let passes = value.range(of: regex, options: .regularExpression) != nil
        return Validated.validate(value, { _ in passes }, onFailure: .invalidFormat)
    }
}

// Compose them for a field:
func validateUsername(_ s: String) -> Validated<ValidationError, String> {
    minLength(3)(s)
        .zip(maxLength(20)(s))
        .zip(matches("^[a-z0-9_]+$")(s))
        .map { _ in s }
}
```

---

## Connecting to async validation

Use `Effect` for server-side checks (username uniqueness, etc.):

```swift
func checkUsernameAvailability(_ username: String) -> Effect<Validated<String, String>> {
    Effect {
        let taken = try await api.isUsernameTaken(username)
        return taken
            ? .failure("Username is already taken")
            : .valid(username)
    }
}

func fullValidation(input: RegistrationInput) -> Effect<Validated<String, User>> {
    let localValidation = validateRegistration(input)

    guard localValidation.isValid else {
        return .success(localValidation)
    }

    return checkUsernameAvailability(input.name)
        .map { remoteValidation in
            remoteValidation.zip(localValidation).map { _, user in user }
        }
}
```

---

## Displaying errors in SwiftUI

```swift
struct ErrorList: View {
    let errors: [String]

    var body: some View {
        if !errors.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(errors, id: \.self) { error in
                    Label(error, systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.callout)
                }
            }
            .padding()
            .background(.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
```
