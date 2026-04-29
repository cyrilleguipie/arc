# NonEmptyArray

```swift
public struct NonEmptyArray<Element>
```

An array guaranteed to have at least one element. All operations are safe — no force-unwraps, no optionals, no `precondition` crashes at runtime.

---

## Why

Standard Swift:

```swift
func processItems(_ items: [Item]) {
    guard let first = items.first else { return }  // caller shouldn't have passed []
    // ...
}
```

With `NonEmptyArray`, the contract is in the type:

```swift
func processItems(_ items: NonEmptyArray<Item>) {
    let first = items.first  // Item — not Optional<Item>
}
```

---

## Construction

```swift
// Direct
let nea = NonEmptyArray(1, 2, 3)
let one = NonEmptyArray(42)

// From array (failable)
let nea = NonEmptyArray([1, 2, 3])  // NonEmptyArray<Int>?

// Array literal
let nea: NonEmptyArray<Int> = [1, 2, 3]

// With explicit tail
let nea = NonEmptyArray(1, tail: [2, 3])
```

---

## Safe properties

```swift
nea.head       // Element     — always exists
nea.first      // Element     — same as head
nea.last       // Element     — always exists
nea.count      // Int
nea.toArray    // [Element]
```

---

## Functional operations

### `map`

Returns a `NonEmptyArray` — not an optional.

```swift
let strings: NonEmptyArray<String> = names.map { $0.uppercased() }
```

### `flatMap`

```swift
let doubled = NonEmptyArray(1, 2).flatMap { NonEmptyArray($0, $0 * 10) }
// NonEmptyArray(1, 10, 2, 20)
```

### `filter`

Returns a regular `[Element]` since filtering may produce an empty result.

```swift
let evens: [Int] = numbers.filter { $0.isMultiple(of: 2) }
```

### `sorted`

Returns a `NonEmptyArray`:

```swift
let sorted = NonEmptyArray(3, 1, 2).sorted()  // NonEmptyArray(1, 2, 3)
```

### `min` / `max`

Safe — no optional:

```swift
numbers.min  // Element
numbers.max  // Element
```

---

## Sequence conformance

`NonEmptyArray` conforms to `Sequence`, so all standard library algorithms work:

```swift
for element in nea { ... }
nea.reduce(0, +)
nea.contains(where: ...)
```

---

## Full API reference

```swift
// Construction
init(_ head: Element, _ tail: Element...)
init(_ head: Element, tail: [Element])
init?(_ array: [Element])

// Properties
var head: Element
var tail: [Element]
var first: Element
var last: Element
var count: Int
var toArray: [Element]

// Transformations
func map<B>(_ transform: (Element) -> B) -> NonEmptyArray<B>
func flatMap<B>(_ transform: (Element) -> NonEmptyArray<B>) -> NonEmptyArray<B>
func filter(_ predicate: (Element) -> Bool) -> [Element]
func sorted(by: (Element, Element) -> Bool) -> NonEmptyArray<Element>
func sorted() -> NonEmptyArray<Element>       // where Element: Comparable

// Building
func prepending(_ element: Element) -> NonEmptyArray
func appending(_ element: Element) -> NonEmptyArray
func appending(contentsOf: [Element]) -> NonEmptyArray

// Comparable extras
var min: Element   // where Element: Comparable
var max: Element   // where Element: Comparable
```
