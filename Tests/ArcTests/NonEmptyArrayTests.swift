import XCTest
@testable import Arc

final class NonEmptyArrayTests: XCTestCase {

    func testInitFromElements() {
        let nea = NonEmptyArray(1, 2, 3)
        XCTAssertEqual(nea.head, 1)
        XCTAssertEqual(nea.tail, [2, 3])
        XCTAssertEqual(nea.count, 3)
    }

    func testInitFromArrayFails() {
        XCTAssertNil(NonEmptyArray<Int>([]))
        XCTAssertNotNil(NonEmptyArray([1, 2]))
    }

    func testMap() {
        let nea = NonEmptyArray(1, 2, 3)
        XCTAssertEqual(nea.map { $0 * 2 }.toArray, [2, 4, 6])
    }

    func testFlatMap() {
        let nea = NonEmptyArray(1, 2)
        let result = nea.flatMap { NonEmptyArray($0, $0 * 10) }
        XCTAssertEqual(result.toArray, [1, 10, 2, 20])
    }

    func testPrepend() {
        let nea = NonEmptyArray(2, 3)
        XCTAssertEqual(nea.prepending(1).toArray, [1, 2, 3])
    }

    func testAppend() {
        let nea = NonEmptyArray(1, 2)
        XCTAssertEqual(nea.appending(3).toArray, [1, 2, 3])
    }

    func testFirstAndLast() {
        let nea = NonEmptyArray(1, 2, 3)
        XCTAssertEqual(nea.first, 1)
        XCTAssertEqual(nea.last, 3)
    }

    func testSingleElement() {
        let nea = NonEmptyArray(42)
        XCTAssertEqual(nea.first, 42)
        XCTAssertEqual(nea.last, 42)
        XCTAssertEqual(nea.count, 1)
    }

    func testSorted() {
        let nea = NonEmptyArray(3, 1, 2)
        XCTAssertEqual(nea.sorted().toArray, [1, 2, 3])
    }

    func testArrayLiteralInit() {
        let nea: NonEmptyArray<Int> = [10, 20, 30]
        XCTAssertEqual(nea.head, 10)
        XCTAssertEqual(nea.count, 3)
    }

    func testSequenceReduce() {
        let nea = NonEmptyArray(1, 2, 3)
        XCTAssertEqual(nea.reduce(0, +), 6)
    }
}
