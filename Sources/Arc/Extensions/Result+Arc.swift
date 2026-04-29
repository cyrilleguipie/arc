extension Result {
    /// Converts Result to Either.
    public func toEither() -> Either<Failure, Success> {
        switch self {
        case .failure(let e): return .left(e)
        case .success(let v): return .right(v)
        }
    }

    /// Wraps the Result in an Effect.
    public func toEffect() -> Effect<Success> {
        Effect {
            switch self {
            case .success(let v): return v
            case .failure(let e): throw e
            }
        }
    }

    /// Converts to Arc's Validated, treating failure as a single error.
    public func toValidated() -> Validated<Failure, Success> {
        switch self {
        case .failure(let e): return .invalid([e])
        case .success(let v): return .valid(v)
        }
    }
}
