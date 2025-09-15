import Foundation
import Combine
import OSLog

protocol NetworkClientProtocol {
    func requestAsync<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

final class NetworkClient: NetworkClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Network")
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        // Important: The API returns camelCase, not snake_case
        // Remove this line: self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    func requestAsync<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        guard NetworkMonitor.shared.isConnected else {
            throw NetworkError.noConnection
        }
        
        let request = try buildRequest(for: endpoint)
        
        logger.debug("Request URL: \(request.url?.absoluteString ?? "no url")")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }
        
        logger.debug("Response Status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            if let responseString = String(data: data, encoding: .utf8) {
                logger.error("Error response: \(responseString)")
            }
        }
        
        try handleHTTPResponse(httpResponse, data: data)
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            if let responseString = String(data: data, encoding: .utf8) {
                logger.error("Failed to decode response: \(responseString)")
            }
            logger.error("Decoding error: \(error)")
            throw NetworkError.decodingError
        }
    }
    
    private func buildRequest(for endpoint: Endpoint) throws -> URLRequest {
        guard let url = buildURL(for: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        var headers = endpoint.headers ?? [:]
        headers["Content-Type"] = "application/json"
        headers["Accept"] = "application/json"
        
        if endpoint.requiresAuth {
            if let token = TokenManager.shared.getAccessToken() {
                headers["Authorization"] = "Bearer \(token)"
            }
        }
        
        request.allHTTPHeaderFields = headers
        
        if let parameters = endpoint.parameters {
            request.httpBody = try JSONEncoder().encode(parameters)
            
            if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
                logger.debug("Request body: \(bodyString)")
            }
        }
        
        return request
    }
    
    private func buildURL(for endpoint: Endpoint) -> URL? {
        let urlString = AppEnvironment.current.baseURL + endpoint.path
        logger.debug("Building URL: \(urlString)")
        
        guard var components = URLComponents(string: urlString) else {
            logger.error("Failed to create URL from: \(urlString)")
            return nil
        }
        
        if let queryItems = endpoint.queryItems {
            components.queryItems = queryItems
        }
        
        return components.url
    }
    
    private func handleHTTPResponse(_ response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 401:
            NotificationCenter.default.post(name: .unauthorized, object: nil)
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 500...599:
            throw NetworkError.serverError("Server error: \(response.statusCode)")
        default:
            throw NetworkError.unknown
        }
    }
}
