/// DSL for writing sequential Either-based pipelines without nested flatMaps.
///
/// Usage:
///   let result: Either<MyError, User> = either {
///       let id = try $0.bind(parseId(rawInput))
///       let user = try $0.bind(fetchUser(id))
///       return user
///   }
///
public func either<L, R>(_ body: (EitherContext<L>) throws -> R) -> Either<L, R> {
    let ctx = EitherContext<L>()
    do {
        let value = try body(ctx)
        return .right(value)
    } catch let err as EitherContext<L>.EarlyExit {
        return .left(err.value)
    } catch {
        // Only EarlyExit is expected; anything else is a programming error
        fatalError("Unexpected error thrown from `either` block: \(error)")
    }
}

public final class EitherContext<Failure> {
    struct EarlyExit: Error {
        let value: Failure
    }

    /// Unwraps a successful Either or throws, causing early exit with the left value.
    @discardableResult
    public func bind<Success>(_ either: Either<Failure, Success>) throws -> Success {
        switch either {
        case .left(let l): throw EarlyExit(value: l)
        case .right(let r): return r
        }
    }

    /// Unwraps an optional or throws, causing early exit with the provided left value.
    @discardableResult
    public func bind<Success>(
        _ optional: Success?,
        orFailWith error: @autoclosure () -> Failure
    ) throws -> Success {
        guard let v = optional else { throw EarlyExit(value: error()) }
        return v
    }
}

// MARK: - Async variant

public func either<L, R>(_ body: @escaping (EitherContext<L>) async throws -> R) async -> Either<L, R> {
    let ctx = EitherContext<L>()
    do {
        let value = try await body(ctx)
        return .right(value)
    } catch let err as EitherContext<L>.EarlyExit {
        return .left(err.value)
    } catch {
        fatalError("Unexpected error thrown from async `either` block: \(error)")
    }
}
