import XCTest
@testable import Arc

final class EitherDSLTests: XCTestCase {

    func testSuccessfulPipeline() {
        let result: Either<String, Int> = either { ctx in
            let a = try ctx.bind(Either<String, Int>.right(10))
            let b = try ctx.bind(Either<String, Int>.right(5))
            return a + b
        }
        XCTAssertEqual(result, .right(15))
    }

    func testEarlyExitOnLeft() {
        var reachedSecondBind = false
        let result: Either<String, Int> = either { ctx in
            _ = try ctx.bind(Either<String, Int>.left("oops"))
            reachedSecondBind = true
            return try ctx.bind(Either<String, Int>.right(99))
        }
        XCTAssertEqual(result, .left("oops"))
        XCTAssertFalse(reachedSecondBind)
    }

    func testBindOptional() {
        let result: Either<String, Int> = either { ctx in
            try ctx.bind(Optional<Int>.none, orFailWith: "was nil")
        }
        XCTAssertEqual(result, .left("was nil"))
    }

    func testAsyncPipeline() async {
        let result: Either<String, String> = await either { (ctx: EitherContext<String>) async throws -> String in
            let n = try ctx.bind(Either<String, Int>.right(42))
            return "value: \(n)"
        }
        XCTAssertEqual(result, .right("value: 42"))
    }
}
