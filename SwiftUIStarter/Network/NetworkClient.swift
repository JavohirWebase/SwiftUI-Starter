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
        
        // Handle non-success status codes
        if httpResponse.statusCode != 200 {
            // Log raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                logger.error("Error response: \(responseString)")
            }
            
            // Parse error response
            throw try parseErrorResponse(data: data, statusCode: httpResponse.statusCode)
        }
        
        // Success - decode normal response
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            if let responseString = String(data: data, encoding: .utf8) {
                logger.error("Failed to decode success response: \(responseString)")
            }
            throw NetworkError.decodingError
        }
    }
    
    private func parseErrorResponse(data: Data, statusCode: Int) throws -> NetworkError {
        // Try to decode server error response
        if let errorResponse = try? decoder.decode(ServerErrorResponse.self, from: data) {
            logger.error("Parsed error: \(errorResponse.userMessage)")
            
            switch statusCode {
            case 400:
                // Validation error - return user-friendly message
                return .validationError(errorResponse.userMessage)
            case 401:
                return .unauthorized
            case 403:
                return .forbidden
            case 404:
                return .notFound
            case 500...599:
                return .serverError(errorResponse.userMessage)
            default:
                return .serverError(errorResponse.userMessage)
            }
        }
        
        // If can't parse error response, return generic error based on status code
        switch statusCode {
        case 400:
            return .validationError("Ma'lumotlar noto'g'ri")
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 500...599:
            return .serverError("Server xatosi: \(statusCode)")
        default:
            return .unknown
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
}
