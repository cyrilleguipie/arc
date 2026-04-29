extension Array {
    /// Converts to NonEmptyArray. Returns nil if the array is empty.
    public func toNonEmpty() -> NonEmptyArray<Element>? {
        NonEmptyArray(self)
    }

    /// Traverses an array with a function that returns Either,
    /// collecting all right values or returning the first left.
    public func traverse<L, R>(
        _ transform: (Element) -> Either<L, R>
    ) -> Either<L, [R]> {
        var results = [R]()
        for element in self {
            switch transform(element) {
            case .left(let l): return .left(l)
            case .right(let r): results.append(r)
            }
        }
        return .right(results)
    }

    /// Traverses an array with a function that returns Validated,
    /// accumulating all errors.
    public func traverseValidated<E, A>(
        _ transform: (Element) -> Validated<E, A>
    ) -> Validated<E, [A]> {
        var results = [A]()
        var errors = [E]()
        for element in self {
            switch transform(element) {
            case .invalid(let errs): errors.append(contentsOf: errs)
            case .valid(let a): if errors.isEmpty { results.append(a) }
            }
        }
        return errors.isEmpty ? .valid(results) : .invalid(errors)
    }

    /// Traverses asynchronously with an Effect-returning function, running sequentially.
    public func traverse<B>(
        _ transform: @escaping (Element) -> Effect<B>
    ) -> Effect<[B]> {
        Effect {
            var results = [B]()
            for element in self {
                let b = try await transform(element).run()
                results.append(b)
            }
            return results
        }
    }

    /// Traverses asynchronously with an Effect-returning function, running in parallel.
    public func traverseConcurrently<B>(
        _ transform: @escaping (Element) -> Effect<B>
    ) -> Effect<[B]> {
        Effect.all(self.map(transform))
    }
}

// MARK: - Sequence utilities

extension Array {
    /// Groups elements into a dictionary using a key extractor.
    public func groupBy<K: Hashable>(_ keyFor: (Element) -> K) -> [K: [Element]] {
        reduce(into: [K: [Element]]()) { acc, el in
            acc[keyFor(el), default: []].append(el)
        }
    }
}
