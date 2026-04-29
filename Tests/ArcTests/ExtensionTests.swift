import XCTest
@testable import Arc

final class ExtensionTests: XCTestCase {

    // MARK: Optional

    func testOptionalToEither() {
        let present: Int? = 5
        XCTAssertEqual(present.toEither("missing"), Either<String, Int>.right(5))

        let absent: Int? = nil
        XCTAssertEqual(absent.toEither("missing"), Either<String, Int>.left("missing"))
    }

    func testOptionalToOption() {
        XCTAssertEqual(Optional(3).toOption(), Option.some(3))
        XCTAssertEqual(Optional<Int>.none.toOption(), Option.none)
    }

    func testOptionalOrThrow() throws {
        let value: Int? = 42
        XCTAssertEqual(try value.orThrow(TestErr.x), 42)
    }

    func testOptionalOrThrowThrows() {
        let value: Int? = nil
        XCTAssertThrowsError(try value.orThrow(TestErr.x))
    }

    // MARK: Result

    func testResultToEither() {
        XCTAssertEqual(Result<Int, TestErr>.success(1).toEither(), Either<TestErr, Int>.right(1))
        XCTAssertEqual(Result<Int, TestErr>.failure(.x).toEither(), Either<TestErr, Int>.left(.x))
    }

    func testResultToValidated() {
        XCTAssertEqual(Result<Int, TestErr>.success(10).toValidated(), Validated<TestErr, Int>.valid(10))
        XCTAssertEqual(Result<Int, TestErr>.failure(.x).toValidated(), Validated<TestErr, Int>.invalid([.x]))
    }

    func testResultToEffect() async throws {
        let result: Result<Int, TestErr> = .success(7)
        let value = try await result.toEffect().run()
        XCTAssertEqual(value, 7)
    }

    // MARK: Array

    func testArrayToNonEmpty() {
        XCTAssertNotNil([1, 2].toNonEmpty())
        XCTAssertNil([Int]().toNonEmpty())
    }

    func testArrayTraverseEither() {
        let result = [1, 2, 3].traverse { n -> Either<String, Int> in .right(n * 2) }
        XCTAssertEqual(result, .right([2, 4, 6]))
    }

    func testArrayTraverseEitherShortCircuits() {
        let result = [1, 2, 3].traverse { n -> Either<String, Int> in
            n == 2 ? .left("bad") : .right(n)
        }
        XCTAssertEqual(result, .left("bad"))
    }

    func testArrayTraverseValidatedAccumulates() {
        let result = [1, -2, 3, -4].traverseValidated { n -> Validated<String, Int> in
            n > 0 ? .valid(n) : .failure("negative: \(n)")
        }
        XCTAssertEqual(result.errors, ["negative: -2", "negative: -4"])
    }

    func testGroupBy() {
        let words = ["apple", "ant", "banana", "avocado"]
        let grouped = words.groupBy { String($0.prefix(1)) }
        XCTAssertEqual(grouped["a"]?.count, 3)
        XCTAssertEqual(grouped["b"]?.count, 1)
    }

    // MARK: Throwing

    func testCatchingSuccess() {
        let result: Either<Error, Int> = catching { 42 }
        XCTAssertEqual(result.rightValue, 42)
    }

    func testCatchingFailure() {
        let result: Either<Error, Int> = catching { () throws -> Int in throw TestErr.x }
        XCTAssertTrue(result.isLeft)
    }

    func testEffectFromThrowing() async throws {
        let e = effect { 99 }
        let result = try await e.run()
        XCTAssertEqual(result, 99)
    }
}

enum TestErr: Error, Equatable { case x }
