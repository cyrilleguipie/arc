import XCTest
@testable import Arc

final class EffectTests: XCTestCase {

    func testSuccessEffect() async throws {
        let result = try await Effect.success(42).run()
        XCTAssertEqual(result, 42)
    }

    func testFailureEffect() async {
        let effect = Effect<Int>.failure(TestError.sample)
        let either = await effect.runEither()
        XCTAssertTrue(either.isLeft)
    }

    func testMapTransformsOutput() async throws {
        let result = try await Effect.success(5).map { $0 * 2 }.run()
        XCTAssertEqual(result, 10)
    }

    func testFlatMapChains() async throws {
        let result = try await Effect.success(3)
            .flatMap { n in Effect.success(n + 1) }
            .flatMap { n in Effect.success(n * 10) }
            .run()
        XCTAssertEqual(result, 40)
    }

    func testZipRunsInParallel() async throws {
        let a = Effect.success(1)
        let b = Effect.success("hello")
        let (n, s) = try await a.zip(b).run()
        XCTAssertEqual(n, 1)
        XCTAssertEqual(s, "hello")
    }

    func testRetrySucceedsAfterFailures() async throws {
        var attempts = 0
        let effect = Effect<Int> {
            attempts += 1
            if attempts < 3 { throw TestError.sample }
            return attempts
        }
        let result = try await effect.retry(5).run()
        XCTAssertEqual(result, 3)
    }

    func testRetryExhausts() async {
        let effect = Effect<Int> { throw TestError.sample }
        let either = await effect.retry(2).runEither()
        XCTAssertTrue(either.isLeft)
    }

    func testTapRunsSideEffect() async throws {
        var captured: Int?
        let result = try await Effect.success(7)
            .tap { captured = $0 }
            .run()
        XCTAssertEqual(result, 7)
        XCTAssertEqual(captured, 7)
    }

    func testCatchErrorRecovers() async throws {
        let effect = Effect<Int> { throw TestError.sample }
        let result = try await effect.catchError { _ in Effect.success(99) }.run()
        XCTAssertEqual(result, 99)
    }

    func testAllRunsConcurrently() async throws {
        let effects = [1, 2, 3].map { Effect.success($0) }
        let results = try await Effect.all(effects).run()
        XCTAssertEqual(results, [1, 2, 3])
    }

    func testTimeout() async {
        let slow = Effect<Int> {
            try await Task.sleep(for: .seconds(10))
            return 1
        }
        let either = await slow.timeout(.milliseconds(50)).runEither()
        XCTAssertTrue(either.isLeft)
    }

    func testToEither() async throws {
        let result = try await Effect.success(42).toEither().run()
        XCTAssertEqual(result.rightValue, 42)
    }

    func testLazyExecution() async {
        var executed = false
        let effect = Effect<Void> { executed = true }
        XCTAssertFalse(executed)
        _ = try? await effect.run()
        XCTAssertTrue(executed)
    }
}

enum TestError: Error { case sample }
