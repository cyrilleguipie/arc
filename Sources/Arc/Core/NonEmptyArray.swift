/// An array guaranteed to have at least one element.
/// All operations are safe — no optionals needed.
public struct NonEmptyArray<Element> {
    public let head: Element
    public let tail: [Element]

    public init(_ head: Element, _ tail: Element...) {
        self.head = head
        self.tail = tail
    }

    public init(_ head: Element, tail: [Element]) {
        self.head = head
        self.tail = tail
    }

    /// Creates from a regular array. Returns nil if the array is empty.
    public init?(_ array: [Element]) {
        guard let first = array.first else { return nil }
        self.head = first
        self.tail = Array(array.dropFirst())
    }
}

// MARK: - Collection interface

extension NonEmptyArray {
    public var first: Element { head }

    public var last: Element { tail.last ?? head }

    public var count: Int { 1 + tail.count }

    public var toArray: [Element] { [head] + tail }

    public subscript(index: Int) -> Element {
        toArray[index]
    }
}

// MARK: - Functional operations

extension NonEmptyArray {
    @inlinable
    public func map<B>(_ transform: (Element) -> B) -> NonEmptyArray<B> {
        NonEmptyArray<B>(transform(head), tail: tail.map(transform))
    }

    @inlinable
    public func flatMap<B>(_ transform: (Element) -> NonEmptyArray<B>) -> NonEmptyArray<B> {
        let headResult = transform(head)
        let tailResult = tail.flatMap { transform($0).toArray }
        return NonEmptyArray<B>(headResult.head, tail: headResult.tail + tailResult)
    }

    @inlinable
    public func filter(_ predicate: (Element) -> Bool) -> [Element] {
        toArray.filter(predicate)
    }

    @inlinable
    public func forEach(_ body: (Element) -> Void) {
        body(head)
        tail.forEach(body)
    }

    @inlinable
    public func reduce<Result>(_ initial: Result, _ combine: (Result, Element) -> Result) -> Result {
        toArray.reduce(initial, combine)
    }

    public func prepending(_ element: Element) -> NonEmptyArray {
        NonEmptyArray(element, tail: toArray)
    }

    public func appending(_ element: Element) -> NonEmptyArray {
        NonEmptyArray(head, tail: tail + [element])
    }

    public func appending(contentsOf elements: [Element]) -> NonEmptyArray {
        NonEmptyArray(head, tail: tail + elements)
    }

    @inlinable
    public func sorted(by areInIncreasingOrder: (Element, Element) -> Bool) -> NonEmptyArray {
        NonEmptyArray(toArray.sorted(by: areInIncreasingOrder))!
    }
}

extension NonEmptyArray where Element: Comparable {
    public func sorted() -> NonEmptyArray { sorted(by: <) }
    public var min: Element { toArray.min()! }
    public var max: Element { toArray.max()! }
}

// MARK: - Sequence conformance

extension NonEmptyArray: Sequence {
    public func makeIterator() -> IndexingIterator<[Element]> {
        toArray.makeIterator()
    }
}

// MARK: - ExpressibleByArrayLiteral

extension NonEmptyArray: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        precondition(!elements.isEmpty, "NonEmptyArray requires at least one element")
        self.head = elements[0]
        self.tail = Array(elements.dropFirst())
    }
}

// MARK: - Equatable / Hashable / Sendable

extension NonEmptyArray: Equatable where Element: Equatable {}
extension NonEmptyArray: Hashable where Element: Hashable {}
extension NonEmptyArray: Sendable where Element: Sendable {}

extension NonEmptyArray: CustomStringConvertible {
    public var description: String { "NonEmptyArray(\(toArray))" }
}
