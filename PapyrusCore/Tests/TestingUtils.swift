import XCTest
import InlineSnapshotTesting
@testable import PapyrusCore

extension UUID {
    static let mockString = "00000000-0000-0000-0000-000000000000"
}

struct _Person: Decodable {
    let name: String
}

struct _PersonWithBirthday: Decodable {
    let name: String
    let birthday: Date
}


class _HTTPServiceMock: HTTPService {
    enum ResponseType {
        case `nil`
        case empty
        case person
        
        var value: String? {
            switch self {
            case .nil:
                nil
            case .empty:
                ""
            case .person:
                "{\"name\": \"Petru\"}"
            }
        }
    }
    
    private let _responseType: ResponseType
    
    init(responseType: ResponseType) {
        _responseType = responseType
    }
    
    func build(method: String, url: URL, headers: [String : String], body: Data?) -> Request {
        _Request(method: "", headers: [:])
    }
    
    func request(_ req: PapyrusCore.Request) async -> PapyrusCore.Response {
        _Response(body: _responseType.value?.data(using: .utf8), statusCode: 200)
    }
    
    func request(_ req: PapyrusCore.Request, completionHandler: @escaping (PapyrusCore.Response) -> Void) {
        completionHandler(_Response(body: "".data(using: .utf8)))
    }
}

struct _Request: Request {
    var url: URL?
    var method: String
    var headers: [String : String]
    var body: Data?
}

struct _Response : Response, AnySnapshotStringConvertible {
    var request: PapyrusCore.Request?
    var body: Data?
    var headers: [String : String]?
    var statusCode: Int?
    var error: Error?
    
    var snapshotDescription: String {
        """
        Response
        request: \(request.map { String(reflecting: $0) } ?? "nil")
        statusCode: \(statusCode.map { "\($0)" } ?? "nil")
        headers: \(String(reflecting: headers))
        body: \(body.map { $0.string } ?? "nil")
        error: \(error.map { String(reflecting: $0) } ?? "nil")
        """
    }
}
