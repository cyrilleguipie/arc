import XCTest
@testable import Arc

final class ValidatedTests: XCTestCase {

    func testValidMap() {
        let v: Validated<String, Int> = .valid(5)
        XCTAssertEqual(v.map { $0 * 2 }, .valid(10))
    }

    func testInvalidMapIgnored() {
        let v: Validated<String, Int> = .invalid(["err"])
        XCTAssertEqual(v.map { $0 * 2 }, .invalid(["err"]))
    }

    func testZipAccumulatesErrors() {
        let a: Validated<String, Int> = .invalid(["bad name"])
        let b: Validated<String, Int> = .invalid(["bad age"])
        let combined = a.zip(b)
        XCTAssertEqual(combined.errors, ["bad name", "bad age"])
        XCTAssertTrue(combined.isInvalid)
    }

    func testZipBothValid() {
        let a: Validated<String, Int> = .valid(1)
        let b: Validated<String, String> = .valid("ok")
        let combined = a.zip(b)
        switch combined {
        case .valid(let (n, s)):
            XCTAssertEqual(n, 1)
            XCTAssertEqual(s, "ok")
        case .invalid:
            XCTFail("Expected valid")
        }
    }

    func testZipOneValidOneInvalid() {
        let a: Validated<String, Int> = .valid(1)
        let b: Validated<String, Int> = .invalid(["error"])
        XCTAssertEqual(a.zip(b).errors, ["error"])
    }

    func testCombineThreeAccumulatesErrors() {
        let result = Validated<String, String>.combine(
            Validated<String, Int>.invalid(["bad name"]),
            Validated<String, Int>.invalid(["bad age"]),
            Validated<String, Bool>.invalid(["bad email"]),
            with: { _, _, _ in "ok" }
        )
        XCTAssertEqual(result.errors.count, 3)
    }

    func testValidateFromPredicate() {
        let ok = Validated<String, Int>.validate(10, { $0 > 0 }, onFailure: "must be positive")
        XCTAssertEqual(ok, .valid(10))

        let fail = Validated<String, Int>.validate(-1, { $0 > 0 }, onFailure: "must be positive")
        XCTAssertEqual(fail, .invalid(["must be positive"]))
    }

    func testToEither() {
        XCTAssertEqual(Validated<String, Int>.valid(42).toEither(), .right(42))
        XCTAssertEqual(Validated<String, Int>.invalid(["err"]).toEither(), .left(["err"]))
    }

    func testFailureConvenience() {
        let v: Validated<String, Int> = .failure("one error")
        XCTAssertEqual(v.errors, ["one error"])
    }

    func testRealWorldFormValidation() {
        struct Form { let name: String; let age: Int; let email: String }

        func validateName(_ s: String) -> Validated<String, String> {
            s.count >= 2 ? .valid(s) : .failure("Name too short")
        }
        func validateAge(_ n: Int) -> Validated<String, Int> {
            (0...120).contains(n) ? .valid(n) : .failure("Age out of range")
        }
        func validateEmail(_ s: String) -> Validated<String, String> {
            s.contains("@") ? .valid(s) : .failure("Invalid email")
        }

        let result = Validated<String, Form>.combine(
            validateName(""),
            validateAge(200),
            validateEmail("notanemail"),
            with: { Form(name: $0, age: $1, email: $2) }
        )
        XCTAssertEqual(result.errors.count, 3)
        XCTAssertTrue(result.isInvalid)
    }
}
