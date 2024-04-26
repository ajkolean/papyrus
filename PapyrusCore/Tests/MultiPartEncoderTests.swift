import XCTest
@testable import PapyrusCore
import InlineSnapshotTesting

final class MultipartEncoderTests: XCTestCase {
    /// Tests the basic functionality of the MultipartEncoder by encoding a simple dictionary of parts.
    /// Ensures that the encoded data is formatted correctly with appropriate boundaries and content disposals.
    func testBasicFunctionality() throws {
        let encoder = MultipartEncoder(boundary: "test")
        let parts = [
            "field1": Part(data: Data("value1".utf8), name: "field1"),
            "field2": Part(data: Data("value2".utf8), name: "field2")
        ]
        let encodedData = try encoder.encode(parts)
        
        assertInlineSnapshot(of: encodedData.string, as: .dump) {
            #"""
            - "--test\r\nContent-Disposition: form-data; name=\"field1\"\r\n\r\nvalue1\r\n--test\r\nContent-Disposition: form-data; name=\"field2\"\r\n\r\nvalue2\r\n--test--\r\n"

            """#
        }
    }

    /// Tests encoding of file attachments to ensure the encoder correctly handles file data and headers,
    /// including content type and filename in the Content-Disposition header.
    func testFileAttachment() throws {
        let encoder = MultipartEncoder(boundary: "test")
        let fileData = Data("file content".utf8)
        let parts = [
            "file": Part(data: fileData, name: "upload", fileName: "test.txt", mimeType: "text/plain")
        ]
        let encodedData = try encoder.encode(parts)
        
        assertInlineSnapshot(of: encodedData.string, as: .dump) {
            #"""
            - "--test\r\nContent-Disposition: form-data; name=\"upload\"; filename=\"test.txt\"\r\nContent-Type: text/plain\r\n\r\nfile content\r\n--test--\r\n"

            """#
        }
    }

    /// Tests the encoder's ability to maintain the integrity of the boundary when the boundary text
    /// appears within the encoded data, ensuring the boundary delimiter is unique and does not corrupt the data.
    func testBoundaryIntegrity() throws {
        let encoder = MultipartEncoder(boundary: "boundary123")
        let parts = [
            "field": Part(data: Data("boundary123".utf8), name: "field")
        ]
        let encodedData = try encoder.encode(parts)
  
        assertInlineSnapshot(of: encodedData.string, as: .dump) {
            #"""
            - "--boundary123\r\nContent-Disposition: form-data; name=\"field\"\r\n\r\nboundary123\r\n--boundary123--\r\n"

            """#
        }
    }
    
    func testRandomBoundary() throws {
        let encoder = MultipartEncoder()
        let parts = [
            "field": Part(data: Data("testRandomBoundaryData".utf8), name: "field")
        ]
        let encodedData = try encoder.encode(parts)
        let encodedString = String(decoding: encodedData, as: UTF8.self)

        let expectedOccurrences = encodedString.components(separatedBy: encoder.boundary).count - 1
        XCTAssertEqual(expectedOccurrences, 2, "Random Boundary should appear as part of the delimiter")
    }


    /// Tests that the encoder preserves the order of form fields as they are added,
    /// which is important for forms where the order of fields may affect processing.
    func testOrderPreservation() throws {
        let encoder = MultipartEncoder(boundary: "test")
        let parts = [
            "a": Part(data: Data("First".utf8), name: "a"),
            "b": Part(data: Data("Second".utf8), name: "b")
        ]
        let encodedData = try encoder.encode(parts)

        assertInlineSnapshot(of: encodedData.string, as: .dump) {
            #"""
            - "--test\r\nContent-Disposition: form-data; name=\"a\"\r\n\r\nFirst\r\n--test\r\nContent-Disposition: form-data; name=\"b\"\r\n\r\nSecond\r\n--test--\r\n"

            """#
        }
    }
}
