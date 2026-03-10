import Core
import XCTest

final class PasswordHasherTests: XCTestCase {
    func testPasswordPolicy() {
        XCTAssertTrue(PasswordHasher.validatePolicy("abc12345"))
        XCTAssertFalse(PasswordHasher.validatePolicy("abcdefghi"))
        XCTAssertFalse(PasswordHasher.validatePolicy("12345678"))
        XCTAssertFalse(PasswordHasher.validatePolicy("ab12"))
    }

    func testCreateAndVerifyRecord() throws {
        let record = try PasswordHasher.createRecord(password: "abc12345")
        XCTAssertTrue(try PasswordHasher.verify(password: "abc12345", against: record))
        XCTAssertFalse(try PasswordHasher.verify(password: "wrong123", against: record))
    }
}
