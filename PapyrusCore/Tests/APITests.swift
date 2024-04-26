import XCTest
import Papyrus
@testable import PapyrusCore

final class APITests: XCTestCase {
    func testApiEndpointReturnsNilForOptionalReturnType_forNilBody() async throws {
        // Arrange
        let sut = _PeopleAPI(provider: .init(baseURL: "", http: _HTTPServiceMock(responseType: .nil)))
        
        // Act
        let person = try await sut.getOptional()
        
        // Assert
        XCTAssertNil(person)
    }
    
    func testApiEndpointThrowsForNonOptionalReturnType_forNilBody() async throws {
        // Arrange
        let sut = _PeopleAPI(provider: .init(baseURL: "", http: _HTTPServiceMock(responseType: .nil)))
        
        // Act
        let expectation = expectation(description: "The endpoint with the non-optional return type should throw an error for an invalid body.")
        do {
            let _ = try await sut.get()
        } catch {
            expectation.fulfill()
        }

        // Assert
        await fulfillment(of: [expectation], timeout: 1)
    }
    
    func testApiEndpointReturnsNilForOptionalReturnType_forEmptyBody() async throws {
        // Arrange
        let sut = _PeopleAPI(provider: .init(baseURL: "", http: _HTTPServiceMock(responseType: .empty)))
        
        // Act
        let person = try await sut.getOptional()
        
        // Assert
        XCTAssertNil(person)
    }
    
    func testApiEndpointThrowsForNonOptionalReturnType_forEmptyBody() async throws {
        // Arrange
        let sut = _PeopleAPI(provider: .init(baseURL: "", http: _HTTPServiceMock(responseType: .empty)))
        
        // Act
        let expectation = expectation(description: "The endpoint with the non-optional return type should throw an error for an invalid body.")
        do {
            let _ = try await sut.get()
        } catch {
            expectation.fulfill()
        }

        // Assert
        await fulfillment(of: [expectation], timeout: 1)
    }
    
    func testApiEndpointReturnsValidObjectForOptionalReturnType() async throws {
        // Arrange
        let sut = _PeopleAPI(provider: .init(baseURL: "", http: _HTTPServiceMock(responseType: .person)))
        
        // Act
        let person = try await sut.getOptional()
        
        // Assert
        XCTAssertNotNil(person)
        XCTAssertEqual(person?.name, "Petru")
    }
    
    func testApiEndpointReturnsValidObjectForNonOptionalReturnType() async throws {
        // Arrange
        let sut = _PeopleAPI(provider: .init(baseURL: "", http: _HTTPServiceMock(responseType: .person)))
        
        // Act
        let person = try await sut.get()
        
        // Assert
        XCTAssertNotNil(person)
        XCTAssertEqual(person.name, "Petru")
    }
}

@API()
fileprivate protocol _People {
    
    @GET("")
    func getOptional() async throws -> _Person?
    
    @GET("")
    func get() async throws -> _Person
}

