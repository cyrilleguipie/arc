import XCTest
@testable import Arc

final class EitherTests: XCTestCase {

    func testMapTransformsRight() {
        let result: Either<String, Int> = .right(5)
        XCTAssertEqual(result.map { $0 * 2 }, .right(10))
    }

    func testMapIgnoresLeft() {
        let result: Either<String, Int> = .left("error")
        XCTAssertEqual(result.map { $0 * 2 }, .left("error"))
    }

    func testFlatMapChains() {
        let result: Either<String, Int> = .right(5)
        let chained = result.flatMap { n -> Either<String, String> in
            n > 0 ? .right("positive") : .left("non-positive")
        }
        XCTAssertEqual(chained, .right("positive"))
    }

    func testFlatMapShortCircuitsOnLeft() {
        let result: Either<String, Int> = .left("oops")
        var sideEffectRan = false
        let chained = result.flatMap { _ -> Either<String, String> in
            sideEffectRan = true
            return .right("never")
        }
        XCTAssertEqual(chained, .left("oops"))
        XCTAssertFalse(sideEffectRan)
    }

    func testMapLeftTransformsLeft() {
        let result: Either<String, Int> = .left("error")
        XCTAssertEqual(result.mapLeft { $0.count }, .left(5))
    }

    func testFold() {
        let left: Either<String, Int> = .left("nope")
        let right: Either<String, Int> = .right(42)
        XCTAssertEqual(left.fold(ifLeft: { "L:\($0)" }, ifRight: { "R:\($0)" }), "L:nope")
        XCTAssertEqual(right.fold(ifLeft: { "L:\($0)" }, ifRight: { "R:\($0)" }), "R:42")
    }

    func testGetOrElse() {
        XCTAssertEqual(Either<String, Int>.left("x").getOrElse(99), 99)
        XCTAssertEqual(Either<String, Int>.right(7).getOrElse(99), 7)
    }

    func testToOptional() {
        XCTAssertEqual(Either<String, Int>.right(1).toOptional(), 1)
        XCTAssertNil(Either<String, Int>.left("e").toOptional())
    }

    func testIsLeftIsRight() {
        XCTAssertTrue(Either<String, Int>.left("x").isLeft)
        XCTAssertFalse(Either<String, Int>.left("x").isRight)
        XCTAssertTrue(Either<String, Int>.right(1).isRight)
        XCTAssertFalse(Either<String, Int>.right(1).isLeft)
    }

    func testAsyncMap() async {
        let result: Either<String, Int> = .right(3)
        let mapped = await result.asyncMap { n in n * 10 }
        XCTAssertEqual(mapped, .right(30))
    }

    func testAsyncFlatMap() async {
        let result: Either<String, Int> = .right(5)
        let chained = await result.asyncFlatMap { n -> Either<String, Int> in .right(n + 1) }
        XCTAssertEqual(chained, .right(6))
    }
}
