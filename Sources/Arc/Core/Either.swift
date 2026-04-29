/// A type that represents one of two possible values.
/// By convention, `left` represents failure and `right` represents success.
public enum Either<Left, Right> {
    case left(Left)
    case right(Right)
}

// MARK: - Core transformations

extension Either {
    /// Transforms the right value, leaving left unchanged.
    @inlinable
    public func map<B>(_ transform: (Right) -> B) -> Either<Left, B> {
        switch self {
        case .left(let l):  return .left(l)
        case .right(let r): return .right(transform(r))
        }
    }

    /// Transforms the right value into a new Either, enabling chaining.
    @inlinable
    public func flatMap<B>(_ transform: (Right) -> Either<Left, B>) -> Either<Left, B> {
        switch self {
        case .left(let l):  return .left(l)
        case .right(let r): return transform(r)
        }
    }

    /// Transforms the left value, leaving right unchanged.
    @inlinable
    public func mapLeft<B>(_ transform: (Left) -> B) -> Either<B, Right> {
        switch self {
        case .left(let l):  return .left(transform(l))
        case .right(let r): return .right(r)
        }
    }

    /// Applies one of two functions depending on which side is present.
    @inlinable
    public func fold<B>(ifLeft: (Left) -> B, ifRight: (Right) -> B) -> B {
        switch self {
        case .left(let l):  return ifLeft(l)
        case .right(let r): return ifRight(r)
        }
    }

    /// Returns the right value or a default.
    @inlinable
    public func getOrElse(_ default: Right) -> Right {
        switch self {
        case .left:         return `default`
        case .right(let r): return r
        }
    }

    /// Returns the right value or the result of a closure.
    @inlinable
    public func getOrElse(_ fallback: (Left) -> Right) -> Right {
        switch self {
        case .left(let l):  return fallback(l)
        case .right(let r): return r
        }
    }

    /// Returns `nil` if left, the right value otherwise.
    @inlinable
    public func toOptional() -> Right? {
        switch self {
        case .left:         return nil
        case .right(let r): return r
        }
    }

    public var isLeft: Bool {
        if case .left = self { return true }
        return false
    }

    public var isRight: Bool {
        if case .right = self { return true }
        return false
    }

    public var leftValue: Left? {
        if case .left(let l) = self { return l }
        return nil
    }

    public var rightValue: Right? {
        if case .right(let r) = self { return r }
        return nil
    }
}

// MARK: - Async variants

extension Either {
    @inlinable
    public func asyncMap<B>(_ transform: (Right) async -> B) async -> Either<Left, B> {
        switch self {
        case .left(let l):  return .left(l)
        case .right(let r): return .right(await transform(r))
        }
    }

    @inlinable
    public func asyncFlatMap<B>(_ transform: (Right) async -> Either<Left, B>) async -> Either<Left, B> {
        switch self {
        case .left(let l):  return .left(l)
        case .right(let r): return await transform(r)
        }
    }
}

// MARK: - Equatable / Hashable

extension Either: Equatable where Left: Equatable, Right: Equatable {}
extension Either: Hashable where Left: Hashable, Right: Hashable {}

// MARK: - Sendable

extension Either: Sendable where Left: Sendable, Right: Sendable {}

// MARK: - CustomStringConvertible

extension Either: CustomStringConvertible {
    public var description: String {
        switch self {
        case .left(let l):  return "left(\(l))"
        case .right(let r): return "right(\(r))"
        }
    }
}
