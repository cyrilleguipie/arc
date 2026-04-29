import Foundation

/// A lazy, composable unit of async work.
/// Effects are not executed until `run()` is called.
public struct Effect<Output> {
    @usableFromInline let _run: () async throws -> Output

    public init(_ run: @escaping () async throws -> Output) {
        self._run = run
    }

    /// Creates an Effect that immediately succeeds with a value.
    public static func success(_ value: Output) -> Effect {
        Effect { value }
    }

    /// Creates an Effect that immediately fails with an error.
    public static func failure(_ error: Error) -> Effect {
        Effect { throw error }
    }

    /// Creates an Effect from an async closure.
    public static func async(_ work: @escaping () async -> Output) -> Effect {
        Effect { await work() }
    }

    /// Executes the effect and returns the result.
    @discardableResult
    public func run() async throws -> Output {
        try await _run()
    }

    /// Executes the effect and returns Either instead of throwing.
    public func runEither() async -> Either<Error, Output> {
        do {
            return .right(try await _run())
        } catch {
            return .left(error)
        }
    }
}

// MARK: - Transformations

extension Effect {
    @inlinable
    public func map<B>(_ transform: @escaping (Output) -> B) -> Effect<B> {
        Effect<B> { try transform(await self._run()) }
    }

    @inlinable
    public func flatMap<B>(_ transform: @escaping (Output) -> Effect<B>) -> Effect<B> {
        Effect<B> { try await transform(try await self._run()).run() }
    }

    /// Transforms errors using the provided closure.
    @inlinable
    public func mapError(_ transform: @escaping (Error) -> Error) -> Effect<Output> {
        Effect {
            do {
                return try await self._run()
            } catch {
                throw transform(error)
            }
        }
    }

    /// Catches errors and returns a fallback Effect.
    @inlinable
    public func catchError(_ recover: @escaping (Error) -> Effect<Output>) -> Effect<Output> {
        Effect {
            do {
                return try await self._run()
            } catch {
                return try await recover(error).run()
            }
        }
    }

    /// Runs a side effect without changing the output.
    @inlinable
    public func tap(_ action: @escaping (Output) -> Void) -> Effect<Output> {
        map { value in action(value); return value }
    }

    /// Converts to an Effect that returns Either, never throwing.
    public func toEither() -> Effect<Either<Error, Output>> {
        Effect<Either<Error, Output>> {
            do {
                return .right(try await self._run())
            } catch {
                return .left(error)
            }
        }
    }
}

// MARK: - Parallel composition

extension Effect {
    /// Runs two Effects concurrently and returns both results.
    public func zip<B>(_ other: Effect<B>) -> Effect<(Output, B)> {
        Effect<(Output, B)> {
            async let a = self._run()
            async let b = other._run()
            return try await (a, b)
        }
    }

    /// Runs two Effects concurrently and combines results.
    public func zip<B, C>(
        _ other: Effect<B>,
        with transform: @escaping (Output, B) -> C
    ) -> Effect<C> {
        zip(other).map(transform)
    }
}

public extension Effect {
    /// Runs an array of Effects concurrently and returns all results.
    static func all(_ effects: [Effect<Output>]) -> Effect<[Output]> {
        Effect<[Output]> {
            try await withThrowingTaskGroup(of: (Int, Output).self) { group in
                for (index, effect) in effects.enumerated() {
                    group.addTask {
                        let result = try await effect.run()
                        return (index, result)
                    }
                }
                var results = [(Int, Output)]()
                for try await result in group {
                    results.append(result)
                }
                return results.sorted { $0.0 < $1.0 }.map { $0.1 }
            }
        }
    }

    /// Runs an array of Effects concurrently and returns the first to succeed.
    static func race(_ effects: [Effect<Output>]) -> Effect<Output> {
        Effect<Output> {
            try await withThrowingTaskGroup(of: Output.self) { group in
                for effect in effects {
                    group.addTask { try await effect.run() }
                }
                guard let first = try await group.next() else {
                    throw EffectError.noEffects
                }
                group.cancelAll()
                return first
            }
        }
    }
}

// MARK: - Retry

extension Effect {
    /// Retries the effect up to `count` times on failure, with optional delay between attempts.
    public func retry(
        _ count: Int,
        delay: Duration = .zero,
        when shouldRetry: @escaping (Error) -> Bool = { _ in true }
    ) -> Effect<Output> {
        Effect {
            var lastError: Error?
            for attempt in 0...count {
                do {
                    return try await self._run()
                } catch {
                    guard attempt < count, shouldRetry(error) else {
                        throw error
                    }
                    lastError = error
                    if delay > .zero {
                        try await Task.sleep(for: delay)
                    }
                }
            }
            throw lastError ?? EffectError.retryExhausted
        }
    }

    /// Retries with exponential backoff.
    public func retryWithBackoff(
        maxAttempts: Int,
        initialDelay: Duration = .milliseconds(100),
        multiplier: Double = 2.0,
        maxDelay: Duration = .seconds(30)
    ) -> Effect<Output> {
        Effect {
            var currentDelay = initialDelay
            for attempt in 0...maxAttempts {
                do {
                    return try await self._run()
                } catch {
                    guard attempt < maxAttempts else { throw error }
                    try await Task.sleep(for: currentDelay)
                    let nextNanoseconds = Double(currentDelay.components.seconds) * 1_000_000_000
                        + Double(currentDelay.components.attoseconds) / 1_000_000_000
                    let scaled = min(nextNanoseconds * multiplier, Double(maxDelay.components.seconds) * 1_000_000_000)
                    currentDelay = .nanoseconds(Int64(scaled))
                }
            }
            throw EffectError.retryExhausted
        }
    }
}

// MARK: - Timeout

extension Effect {
    /// Fails with `EffectError.timedOut` if the effect takes longer than the given duration.
    public func timeout(_ duration: Duration) -> Effect<Output> {
        Effect {
            try await withThrowingTaskGroup(of: Output.self) { group in
                group.addTask { try await self._run() }
                group.addTask {
                    try await Task.sleep(for: duration)
                    throw EffectError.timedOut
                }
                guard let result = try await group.next() else {
                    throw EffectError.timedOut
                }
                group.cancelAll()
                return result
            }
        }
    }
}

// MARK: - Errors

public enum EffectError: Error, CustomStringConvertible {
    case retryExhausted
    case timedOut
    case noEffects

    public var description: String {
        switch self {
        case .retryExhausted: return "Effect: all retry attempts exhausted"
        case .timedOut:       return "Effect: timed out"
        case .noEffects:      return "Effect: no effects provided to race"
        }
    }
}
