extension Optional {
    /// Converts to Either, using the provided left value when nil.
    public func toEither<L>(_ error: @autoclosure () -> L) -> Either<L, Wrapped> {
        switch self {
        case .none:        return .left(error())
        case .some(let v): return .right(v)
        }
    }

    /// Converts to Arc's Option type.
    public func toOption() -> Option<Wrapped> {
        Option(self)
    }

    /// Returns the value or throws the provided error.
    public func orThrow(_ error: @autoclosure () -> Error) throws -> Wrapped {
        guard let value = self else { throw error() }
        return value
    }

    /// Applies a side effect if the value is present, returns self.
    @discardableResult
    public func ifPresent(_ action: (Wrapped) -> Void) -> Wrapped? {
        if let v = self { action(v) }
        return self
    }

    /// Applies a side effect if absent, returns self.
    @discardableResult
    public func ifAbsent(_ action: () -> Void) -> Wrapped? {
        if self == nil { action() }
        return self
    }
}
