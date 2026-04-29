/// Converts a throwing closure into Either<Error, R>.
public func catching<R>(_ work: () throws -> R) -> Either<Error, R> {
    do {
        return .right(try work())
    } catch {
        return .left(error)
    }
}

/// Converts an async throwing closure into Either<Error, R>.
public func catching<R>(_ work: () async throws -> R) async -> Either<Error, R> {
    do {
        return .right(try await work())
    } catch {
        return .left(error)
    }
}

/// Wraps a throwing closure in an Effect.
public func effect<R>(_ work: @escaping () throws -> R) -> Effect<R> {
    Effect(work)
}

/// Wraps an async throwing closure in an Effect.
public func effect<R>(_ work: @escaping () async throws -> R) -> Effect<R> {
    Effect(work)
}
