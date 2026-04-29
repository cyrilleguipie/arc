/// An explicit Option type that mirrors Swift's Optional with a consistent Arc API.
/// Use this when you want API symmetry with Either and Validated in pipelines.
public enum Option<Wrapped> {
    case none
    case some(Wrapped)

    public init(_ value: Wrapped?) {
        if let v = value { self = .some(v) } else { self = .none }
    }

    public static func of(_ value: Wrapped) -> Option<Wrapped> { .some(value) }
    public static var empty: Option<Wrapped> { .none }
}

// MARK: - Core transformations

extension Option {
    @inlinable
    public func map<B>(_ transform: (Wrapped) -> B) -> Option<B> {
        switch self {
        case .none:        return .none
        case .some(let v): return .some(transform(v))
        }
    }

    @inlinable
    public func flatMap<B>(_ transform: (Wrapped) -> Option<B>) -> Option<B> {
        switch self {
        case .none:        return .none
        case .some(let v): return transform(v)
        }
    }

    @inlinable
    public func filter(_ predicate: (Wrapped) -> Bool) -> Option<Wrapped> {
        switch self {
        case .none:        return .none
        case .some(let v): return predicate(v) ? .some(v) : .none
        }
    }

    @inlinable
    public func getOrElse(_ default: Wrapped) -> Wrapped {
        switch self {
        case .none:        return `default`
        case .some(let v): return v
        }
    }

    @inlinable
    public func getOrElse(_ fallback: () -> Wrapped) -> Wrapped {
        switch self {
        case .none:        return fallback()
        case .some(let v): return v
        }
    }

    /// Converts to Either, using the provided left value when empty.
    @inlinable
    public func toEither<L>(_ leftValue: @autoclosure () -> L) -> Either<L, Wrapped> {
        switch self {
        case .none:        return .left(leftValue())
        case .some(let v): return .right(v)
        }
    }

    /// Converts to Swift Optional.
    @inlinable
    public func toOptional() -> Wrapped? {
        switch self {
        case .none:        return nil
        case .some(let v): return v
        }
    }

    public var isSome: Bool {
        if case .some = self { return true }
        return false
    }

    public var isNone: Bool { !isSome }

    public var value: Wrapped? {
        if case .some(let v) = self { return v }
        return nil
    }
}

// MARK: - Async variants

extension Option {
    @inlinable
    public func asyncMap<B>(_ transform: (Wrapped) async -> B) async -> Option<B> {
        switch self {
        case .none:        return .none
        case .some(let v): return .some(await transform(v))
        }
    }

    @inlinable
    public func asyncFlatMap<B>(_ transform: (Wrapped) async -> Option<B>) async -> Option<B> {
        switch self {
        case .none:        return .none
        case .some(let v): return await transform(v)
        }
    }
}

// MARK: - Equatable / Hashable / Sendable

extension Option: Equatable where Wrapped: Equatable {}
extension Option: Hashable where Wrapped: Hashable {}
extension Option: Sendable where Wrapped: Sendable {}

extension Option: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none:        return "none"
        case .some(let v): return "some(\(v))"
        }
    }
}
