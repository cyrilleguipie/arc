import XCTest
@testable import Arc

final class OptionTests: XCTestCase {

    func testInitFromOptional() {
        XCTAssertEqual(Option(42), .some(42))
        XCTAssertEqual(Option(nil as Int?), .none)
    }

    func testMapSome() {
        XCTAssertEqual(Option.some(5).map { $0 * 2 }, .some(10))
    }

    func testMapNone() {
        XCTAssertEqual(Option<Int>.none.map { $0 * 2 }, .none)
    }

    func testFlatMapChains() {
        let result = Option.some("hello").flatMap { s -> Option<Int> in
            s.isEmpty ? .none : .some(s.count)
        }
        XCTAssertEqual(result, .some(5))
    }

    func testFilter() {
        XCTAssertEqual(Option.some(4).filter { $0.isMultiple(of: 2) }, .some(4))
        XCTAssertEqual(Option.some(3).filter { $0.isMultiple(of: 2) }, .none)
    }

    func testGetOrElse() {
        XCTAssertEqual(Option<Int>.none.getOrElse(0), 0)
        XCTAssertEqual(Option.some(7).getOrElse(0), 7)
    }

    func testToEither() {
        XCTAssertEqual(Option.some(1).toEither("missing"), Either<String, Int>.right(1))
        XCTAssertEqual(Option<Int>.none.toEither("missing"), Either<String, Int>.left("missing"))
    }

    func testToOptional() {
        XCTAssertEqual(Option.some(3).toOptional(), 3)
        XCTAssertNil(Option<Int>.none.toOptional())
    }

    func testIsSomeIsNone() {
        XCTAssertTrue(Option.some(1).isSome)
        XCTAssertFalse(Option<Int>.none.isSome)
        XCTAssertTrue(Option<Int>.none.isNone)
    }
}
