/// A type for validation that accumulates errors instead of short-circuiting.
/// Use this over Either when you want all validation failures at once.
public enum Validated<Failure, Success> {
    case invalid([Failure])
    case valid(Success)

    /// Convenience constructor for a single error.
    public static func failure(_ error: Failure) -> Validated {
        .invalid([error])
    }
}

// MARK: - Core transformations

extension Validated {
    /// Transforms the valid value, leaving errors unchanged.
    @inlinable
    public func map<B>(_ transform: (Success) -> B) -> Validated<Failure, B> {
        switch self {
        case .invalid(let errs): return .invalid(errs)
        case .valid(let v):      return .valid(transform(v))
        }
    }

    /// Combines two Validated values, accumulating all failures.
    public func zip<B>(_ other: Validated<Failure, B>) -> Validated<Failure, (Success, B)> {
        switch (self, other) {
        case (.valid(let a), .valid(let b)):
            return .valid((a, b))
        case (.invalid(let e1), .invalid(let e2)):
            return .invalid(e1 + e2)
        case (.invalid(let errs), _):
            return .invalid(errs)
        case (_, .invalid(let errs)):
            return .invalid(errs)
        }
    }

    /// Applies a validated function to a validated value, accumulating errors.
    public func apply<B>(_ validatedTransform: Validated<Failure, (Success) -> B>) -> Validated<Failure, B> {
        switch (validatedTransform, self) {
        case (.valid(let f), .valid(let a)):
            return .valid(f(a))
        case (.invalid(let e1), .invalid(let e2)):
            return .invalid(e1 + e2)
        case (.invalid(let errs), _):
            return .invalid(errs)
        case (_, .invalid(let errs)):
            return .invalid(errs)
        }
    }

    /// NOTE: flatMap breaks error accumulation — use zip/combine for that.
    /// This is provided for compatibility in sequential flows.
    @inlinable
    public func flatMap<B>(_ transform: (Success) -> Validated<Failure, B>) -> Validated<Failure, B> {
        switch self {
        case .invalid(let errs): return .invalid(errs)
        case .valid(let v):      return transform(v)
        }
    }

    public var isValid: Bool {
        if case .valid = self { return true }
        return false
    }

    public var isInvalid: Bool { !isValid }

    public var errors: [Failure] {
        if case .invalid(let errs) = self { return errs }
        return []
    }

    public var value: Success? {
        if case .valid(let v) = self { return v }
        return nil
    }

    /// Converts to Either, collapsing errors into a single array.
    public func toEither() -> Either<[Failure], Success> {
        switch self {
        case .invalid(let errs): return .left(errs)
        case .valid(let v):      return .right(v)
        }
    }

    /// Applies one of two functions depending on validity.
    @inlinable
    public func fold<B>(ifInvalid: ([Failure]) -> B, ifValid: (Success) -> B) -> B {
        switch self {
        case .invalid(let errs): return ifInvalid(errs)
        case .valid(let v):      return ifValid(v)
        }
    }
}

// MARK: - Combining multiple Validated values

extension Validated {
    /// Combines two Validated values using a mapping function, accumulating all errors.
    public static func combine<A, B>(
        _ a: Validated<Failure, A>,
        _ b: Validated<Failure, B>,
        with transform: (A, B) -> Success
    ) -> Validated<Failure, Success> {
        a.zip(b).map(transform)
    }

    /// Combines three Validated values, accumulating all errors.
    public static func combine<A, B, C>(
        _ a: Validated<Failure, A>,
        _ b: Validated<Failure, B>,
        _ c: Validated<Failure, C>,
        with transform: (A, B, C) -> Success
    ) -> Validated<Failure, Success> {
        a.zip(b).zip(c).map { ab, cv in transform(ab.0, ab.1, cv) }
    }

    /// Combines four Validated values, accumulating all errors.
    public static func combine<A, B, C, D>(
        _ a: Validated<Failure, A>,
        _ b: Validated<Failure, B>,
        _ c: Validated<Failure, C>,
        _ d: Validated<Failure, D>,
        with transform: (A, B, C, D) -> Success
    ) -> Validated<Failure, Success> {
        a.zip(b).zip(c).zip(d).map { abc, dv in
            let (ab, cv) = abc
            return transform(ab.0, ab.1, cv, dv)
        }
    }
}

// MARK: - Convenience: validate from a condition

extension Validated {
    /// Creates a Validated from a predicate.
    public static func validate(
        _ value: Success,
        _ condition: (Success) -> Bool,
        onFailure error: Failure
    ) -> Validated<Failure, Success> {
        condition(value) ? .valid(value) : .invalid([error])
    }
}

// MARK: - Equatable / Hashable / Sendable

extension Validated: Equatable where Failure: Equatable, Success: Equatable {}
extension Validated: Hashable where Failure: Hashable, Success: Hashable {}
extension Validated: Sendable where Failure: Sendable, Success: Sendable {}

extension Validated: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalid(let errs): return "invalid(\(errs))"
        case .valid(let v):      return "valid(\(v))"
        }
    }
}
