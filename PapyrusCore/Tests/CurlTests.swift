import XCTest
@testable import PapyrusCore
import InlineSnapshotTesting

final class CurlTests: XCTestCase {
    func testConvertPath() throws {
        let req = RequestBuilder(baseURL: "foo/", method: "bar", path: "baz")

        let request = try TestRequest(from: req)
        
        assertInlineSnapshot(of: request.curl(sortedHeaders: true), as: .description) {
            #"""
            curl 'foo/baz' \
            -X bar \
            -H 'Content-Length: 0' \
            -H 'Content-Type: application/json'
            """#
        }
    }

    func testConvertHeaders() async throws {
        var req = RequestBuilder(baseURL: "foo/", method: "GET", path: "/baz")
        req.addHeader("Hello", value: "There")
        req.addHeader("High", value: "Ground")

        let request = try TestRequest(from: req)
        
        assertInlineSnapshot(of: request.curl(sortedHeaders: true), as: .description) {
            #"""
            curl 'foo/baz' \
            -X GET \
            -H 'Content-Length: 0' \
            -H 'Content-Type: application/json' \
            -H 'Hello: There' \
            -H 'High: Ground'
            """#
        }
    }

    func testConvertMultipart() throws {
        var req = RequestBuilder(baseURL: "foo/", method: "bar", path: "/baz")
        let encoder = MultipartEncoder(boundary: UUID.mockString)
        req.requestEncoder = encoder
        req.addField("a", value: Part(data: Data("one".utf8), fileName: "one.txt", mimeType: "text/plain"))
        req.addField("b", value: Part(data: Data("two".utf8)))

        let request = try TestRequest(from: req)
        
        assertInlineSnapshot(of: request.curl(sortedHeaders: true), as: .description) {
            #"""
            curl 'foo/baz' \
            -X bar \
            -H 'Content-Length: 266' \
            -H 'Content-Type: multipart/form-data; boundary=00000000-0000-0000-0000-000000000000' \
            -d '--00000000-0000-0000-0000-000000000000\#r
            Content-Disposition: form-data; name="a"; filename="one.txt"\#r
            Content-Type: text/plain\#r
            \#r
            one\#r
            --00000000-0000-0000-0000-000000000000\#r
            Content-Disposition: form-data; name="b"\#r
            \#r
            two\#r
            --00000000-0000-0000-0000-000000000000--\#r
            '
            """#
        }
    }

    func testConvertJSON() async throws {
        var req = RequestBuilder(baseURL: "foo/", method: "bar", path: "/baz")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        req.requestEncoder = encoder
        req.addField("a", value: "one")
        req.addField("b", value: "two")

        let request = try TestRequest(from: req)
        
        assertInlineSnapshot(of: request.curl(sortedHeaders: true), as: .description) {
            #"""
            curl 'foo/baz' \
            -X bar \
            -H 'Content-Length: 32' \
            -H 'Content-Type: application/json' \
            -d '{
              "a" : "one",
              "b" : "two"
            }'
            """#
        }
    }

    func testConvertURLForm() async throws {
        var req = RequestBuilder(baseURL: "foo/", method: "bar", path: "/baz")
        req.requestEncoder = URLEncodedFormEncoder()
        req.addField("a", value: "one")
        req.addField("b", value: "two")

        let request = try TestRequest(from: req)
        
        let normalizedCurl = request.curl(sortedHeaders: true)
            .replacingOccurrences(of: "b=two&a=one", with: "a=one&b=two")

        assertInlineSnapshot(of: normalizedCurl, as: .description) {
            #"""
            curl 'foo/baz' \
            -X bar \
            -H 'Content-Length: 11' \
            -H 'Content-Type: application/x-www-form-urlencoded' \
            -d 'a=one&b=two'
            """#
        }
    }

    func testInterceptorAlways() async throws {
        var req = RequestBuilder(baseURL: "foo/", method: "GET", path: "/baz")
        req.addQuery("Hello", value: "There")
        req.addHeader("High", value: "Ground")
        let request = try TestRequest(from: req)

        var message: String? = nil

        let logger = CurlLogger(when: .always, using: {
            message = $0
        })

        _ = try await logger.intercept(req: request) { req in
            return TestResponse(request: req)
        }

        XCTAssertNotNil(message, "Logger did not output")
        
        guard let message else { return }
        
        assertInlineSnapshot(of: message, as: .description) {
            #"""
            curl 'foo/baz?Hello=There' \
            -X GET \
            -H 'Content-Length: 0' \
            -H 'Content-Type: application/json' \
            -H 'High: Ground'
            """#
        }
    }

    func testInterceptorOnError() async throws {
        var req = RequestBuilder(baseURL: "foo/", method: "GET", path: "/baz")
        req.addQuery("Hello", value: "There")
        req.addHeader("High", value: "Ground")
        let request = try TestRequest(from: req)

        var message: String? = nil

        let logger = CurlLogger(when: .onError, using: {
            print("WHAT?")
            message = $0
        })

        _ = try? await logger.intercept(req: request) { req in
            throw PapyrusError("")
        }

        XCTAssertNotNil(message, "Logger did not output")
        guard let message else { return }
        
        assertInlineSnapshot(of: message, as: .description) {
            #"""
            curl 'foo/baz?Hello=There' \
            -X GET \
            -H 'Content-Length: 0' \
            -H 'Content-Type: application/json' \
            -H 'High: Ground'
            """#
        }
    }

    func testInterceptorOnErrorNoError() async throws {
        var req = RequestBuilder(baseURL: "foo/", method: "GET", path: "/baz")
        req.addQuery("Hello", value: "There")
        req.addHeader("High", value: "Ground")

        let request = try TestRequest(from: req)

        var message: String? = nil

        let logger = CurlLogger(when: .onError, using: {
            message = $0
        })

        _ = try await logger.intercept(req: request) { req in
            return TestResponse(request: req)
        }

        XCTAssertNil(message, "Logger did output")
            }
}

private struct TestResponse: Response {
    var request: Request? = nil
    var body: Data? = nil
    var headers: [String : String]? = nil
    var statusCode: Int? = nil
    var error: Error? = nil
}


private struct TestRequest: Request {
    var method: String
    var url: URL?
    var headers: [String : String]
    var body: Data?

    init(method: String, url: URL?, headers: [String : String], body: Data?) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
    }

    init(from builder: RequestBuilder) throws {
        let url = try builder.fullURL()
        let (body, headers) = try builder.bodyAndHeaders()

        self.init(
            method: builder.method,
            url: url,
            headers: headers,
            body: body
        )
    }
}
