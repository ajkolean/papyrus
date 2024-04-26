import InlineSnapshotTesting
import XCTest
@testable import PapyrusCore

final class ResponseTests: XCTestCase {
    /// Test to ensure that the `validate()` method correctly throws an error when the `Response` instance contains an error.
    /// This checks that errors embedded within a response are properly propagated and not silently ignored.
    func testValidate() {
        enum TestError: Error {
            case test
        }
        
        let res: Response = .error(TestError.test)
        
        XCTAssertThrowsError(try res.validate(), "Better description") { error in
            assertInlineSnapshot(of: error, as: .dump) {
                """
                - TestError.test
                
                """
            }
        }
    }
    
    /// Test that `validate()` throws a `PapyrusError` when the status code indicates a client or server error (i.e., not in the range 200-299).
    /// This ensures that `validate()` correctly identifies and handles HTTP response status codes that denote failure.
    func testValidateWithUnsuccessfulStatusCode() throws {
        var response = _Response()
        response.statusCode = 404
        
        XCTAssertThrowsError(try response.validate()) { error in
            XCTAssertTrue(error is PapyrusError, "Expected a PapyrusError for unsuccessful status codes.")
            
            assertInlineSnapshot(of: error, as: .dump) {
                """
                ▿ PapyrusError
                  - message: "Unsuccessful status code: 404."
                  - request: Optional<Request>.none
                  ▿ response: Optional<Response>
                    - some: Response
                request: nil
                statusCode: 404
                headers: nil
                body: nil
                error: nil

                """
            }
        }
    }
    
    /// Test to ensure that the `validate()` method successfully validates a response with a 200 status code without throwing any errors.
    /// This test checks that `validate()` appropriately handles HTTP 200 OK responses, confirming normal operation and correct response handling.
    func testValidateWithSuccessStatusCode() throws {
        let response = _Response(statusCode: 200)
        
        assertInlineSnapshot(of: try response.validate(), as: .dump) {
            """
            - Response
            request: nil
            statusCode: 200
            headers: nil
            body: nil
            error: nil

            """
        }
    }
}
