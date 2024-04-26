import XCTest
import InlineSnapshotTesting
@testable import PapyrusCore

final class ResponseDecoderTests: XCTestCase {
    func testWithKeyMappingDoesntMutate() throws {
        let decoder = JSONDecoder()
        let snakeDecoder = decoder.with(keyMapping: .snakeCase)
        
        switch decoder.keyDecodingStrategy {
        case .useDefaultKeys: break
        default: XCTFail("Should be default keys")
        }
        
        switch snakeDecoder.keyDecodingStrategy {
        case .convertFromSnakeCase: break
        default: XCTFail("Should be snake_case keys")
        }
    }
    
    func testResponseWithOptionalTypeAndNilBody() throws {
        // Arrange
        let response = _Response(body: nil)
        
        // Act
        let decoded = try response.decode(_Person?.self, using: JSONDecoder())
        
        assertInlineSnapshot(of: response, as: .dump) {
            """
            - Response
            request: nil
            statusCode: nil
            headers: nil
            body: nil
            error: nil
            
            """
        }
        
        XCTAssertNil(decoded)
    }
    
    func testResponseWithOptionalTypeAndEmptyBody() throws {
        // Arrange
        let response = _Response(body: "".data(using: .utf8))
        
        // Act
        let decoded = try response.decode(_Person?.self, using: JSONDecoder())
        
        assertInlineSnapshot(of: response, as: .dump) {
            """
            - Response
            request: nil
            statusCode: nil
            headers: nil
            body: 
            error: nil
            
            """
        }
        
        XCTAssertNil(decoded)
    }
    
    func testResponseWithOptionalTypeAndNonNilBody() throws {
        // Arrange
        let response = _Response(body: "{ \"name\": \"Petru\" }".data(using: .utf8))
        
        // Act
        let decoded = try response.decode(_Person?.self, using: JSONDecoder())
        
        
        assertInlineSnapshot(of: response, as: .dump) {
            """
            - Response
            request: nil
            statusCode: nil
            headers: nil
            body: { "name": "Petru" }
            error: nil
            
            """
        }
        
        assertInlineSnapshot(of: decoded, as: .description) {
            """
            _Person(name: "Petru")
            """
        }
        
        //Assert
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.name, "Petru")
    }
    
    func testResponseWithNonOptionalTypeAndNonNilBody() throws {
        // Arrange
        let response = _Response(body: "{ \"name\": \"Petru\" }".data(using: .utf8))
        
        // Act
        let decoded = try response.decode(_Person.self, using: JSONDecoder())
        
        assertInlineSnapshot(of: response, as: .dump) {
            """
            - Response
            request: nil
            statusCode: nil
            headers: nil
            body: { "name": "Petru" }
            error: nil
            
            """
        }
        
        assertInlineSnapshot(of: decoded, as: .description) {
            """
            _Person(name: "Petru")
            """
        }
    }
    
    func testResponseWithExtraFieldsInJSON() throws {
        // Arrange
        let response = _Response(body: "{ \"name\": \"Petru\", \"age\": 25 }".data(using: .utf8)) // JSON with an extra field
        
        // Act
        let decoded = try response.decode(_Person.self, using: JSONDecoder())
        
        assertInlineSnapshot(of: response, as: .dump) {
            """
            - Response
            request: nil
            statusCode: nil
            headers: nil
            body: { "name": "Petru", "age": 25 }
            error: nil
            
            """
        }
        
        assertInlineSnapshot(of: decoded, as: .description) {
            """
            _Person(name: "Petru")
            """
        }
    }
    
    func testResponseWithDifferentDateFormats() throws {
        // Arrange
        let response = _Response(body: "{ \"name\": \"Petru\", \"birthday\": \"2000-01-01T00:00:00Z\" }".data(using: .utf8))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Act
        let decoded = try response.decode(_PersonWithBirthday.self, using: decoder)
        
        assertInlineSnapshot(of: response, as: .dump) {
            """
            - Response
            request: nil
            statusCode: nil
            headers: nil
            body: { "name": "Petru", "birthday": "2000-01-01T00:00:00Z" }
            error: nil
            
            """
        }
        
        assertInlineSnapshot(of: decoded, as: .description) {
            """
            _PersonWithBirthday(name: "Petru", birthday: 2000-01-01 00:00:00 +0000)
            """
        }
    }
    
    func testResponseWithMalformedJSON() throws {
        // Arrange
        let response = _Response(body: "{ \"name\": \"Petru\", ".data(using: .utf8))
        
        XCTAssertThrowsError(try response.decode(_Person.self, using: JSONDecoder()), "Decoding should fail for malformed JSON") { error in
            
            assertInlineSnapshot(of: response, as: .dump) {
                """
                - Response
                request: nil
                statusCode: nil
                headers: nil
                body: { "name": "Petru", 
                error: nil
                
                """
            }
            
            assertInlineSnapshot(of: error, as: .dump) {
                """
                ▿ DecodingError
                  ▿ dataCorrupted: Context
                    - codingPath: 0 elements
                    - debugDescription: "The given data was not valid JSON."
                    ▿ underlyingError: Optional<Error>
                      - some: Error Domain=NSCocoaErrorDomain Code=3840 "Unexpected end of file" UserInfo={NSDebugDescription=Unexpected end of file}
                
                """
            }
        }
    }
    
    func testResponseWithErrorPropagation() throws {
        // Arrange
        let error = NSError(domain: "Network", code: 404, userInfo: [NSLocalizedDescriptionKey: "Not Found"])
        let response = _Response(error: error)
        
        // Act & Assert
        XCTAssertThrowsError(try response.decode(_Person.self, using: JSONDecoder()), "Decoding should recognize and propagate response error") { error in
            
            assertInlineSnapshot(of: response, as: .dump) {
                """
                - Response
                request: nil
                statusCode: nil
                headers: nil
                body: nil
                error: Error Domain=Network Code=404 "Not Found" UserInfo={NSLocalizedDescription=Not Found}
                
                """
            }
            
            assertInlineSnapshot(of: error, as: .dump) {
                """
                ▿ PapyrusError
                  - message: "Unable to decode `_Response` from a `Response`; body was nil."
                  - request: Optional<Request>.none
                  ▿ response: Optional<Response>
                    - some: Response
                request: nil
                statusCode: nil
                headers: nil
                body: nil
                error: Error Domain=Network Code=404 "Not Found" UserInfo={NSLocalizedDescription=Not Found}
                
                """
            }
        }
    }
    
    func testResponseHandlingBasedOnStatusCode() throws {
        // Arrange
        let response = _Response(body: nil, statusCode: 204)

        // Act
        let decoded = try response.decode(_Person?.self, using: JSONDecoder())
        
        XCTAssertNil(decoded)

        assertInlineSnapshot(of: response, as: .dump) {
            """
            - Response
            request: nil
            statusCode: 204
            headers: nil
            body: nil
            error: nil

            """
        }
    }
}
