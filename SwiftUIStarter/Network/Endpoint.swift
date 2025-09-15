import Foundation

struct Endpoint {
    let path: String
    let method: HTTPMethod
    let parameters: Encodable?
    let queryItems: [URLQueryItem]?
    let headers: [String: String]?
    let requiresAuth: Bool
    
    init(
        path: String,
        method: HTTPMethod = .get,
        parameters: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil,
        headers: [String: String]? = nil,
        requiresAuth: Bool = true
    ) {
        self.path = path
        self.method = method
        self.parameters = parameters
        self.queryItems = queryItems
        self.headers = headers
        self.requiresAuth = requiresAuth
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}
