import XCTest
import InlineSnapshotTesting
@testable import PapyrusCore

final class RequestBuilderTests: XCTestCase {
    func testPath() throws {
        let req = RequestBuilder(baseURL: "foo/", method: "bar", path: "baz")
        XCTAssertEqual(try req.fullURL().absoluteString, "foo/baz")
    }

    func testPathNoTrailingSlash() throws {
        let req = RequestBuilder(baseURL: "foo", method: "bar", path: "/baz")
        XCTAssertEqual(try req.fullURL().absoluteString, "foo/baz")
    }

    func testPathDoubleSlash() throws {
        let req = RequestBuilder(baseURL: "foo/", method: "bar", path: "/baz")
        XCTAssertEqual(try req.fullURL().absoluteString, "foo/baz")
    }

    func testMultipart() throws {
        var req = RequestBuilder(baseURL: "foo/", method: "bar", path: "/baz")
        let encoder = MultipartEncoder(boundary: UUID.mockString)
        req.requestEncoder = encoder
        req.addField("a", value: Part(data: Data("one".utf8), fileName: "one.txt", mimeType: "text/plain"))
        req.addField("b", value: Part(data: Data("two".utf8)))
        let (body, headers) = try req.bodyAndHeaders()
        guard let body else {
            XCTFail()
            return
        }
        
        assertInlineSnapshot(of: headers, as: .json) {
            #"""
            {
              "Content-Length" : "266",
              "Content-Type" : "multipart\/form-data; boundary=00000000-0000-0000-0000-000000000000"
            }
            """#
        }
        
        assertInlineSnapshot(of: body.string, as: .description) {
            """
            --00000000-0000-0000-0000-000000000000\r
            Content-Disposition: form-data; name="a"; filename="one.txt"\r
            Content-Type: text/plain\r
            \r
            one\r
            --00000000-0000-0000-0000-000000000000\r
            Content-Disposition: form-data; name="b"\r
            \r
            two\r
            --00000000-0000-0000-0000-000000000000--\r

            """
        }
    }

    func testJSON() async throws {
        var req = RequestBuilder(baseURL: "foo/", method: "bar", path: "/baz")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        req.requestEncoder = encoder
        req.addField("a", value: "one")
        req.addField("b", value: "two")
        let (body, headers) = try req.bodyAndHeaders()
        
        XCTAssertEqual(headers, [
            "Content-Type": "application/json",
            "Content-Length": "32"
        ])
        
        assertInlineSnapshot(of: body?.string, as: .description) {
            """
            {
              "a" : "one",
              "b" : "two"
            }
            """
        }
    }

    func testURLForm() async throws {
        var req = RequestBuilder(baseURL: "foo/", method: "bar", path: "/baz")
        req.requestEncoder = URLEncodedFormEncoder()
        req.addField("a", value: "one")
        req.addField("b", value: "two")
        let (body, headers) = try req.bodyAndHeaders()
        
        XCTAssertEqual(headers, [
            "Content-Type": "application/x-www-form-urlencoded",
            "Content-Length": "11"
        ])
        
        let normalizedBody = body?.string
            .replacingOccurrences(of: "b=two&a=one", with: "a=one&b=two")
        
        assertInlineSnapshot(of: normalizedBody, as: .description) {
            """
            a=one&b=two
            """
        }
    }
}

extension Data {
     var string: String {
        String(decoding: self, as: UTF8.self)
    }
}
