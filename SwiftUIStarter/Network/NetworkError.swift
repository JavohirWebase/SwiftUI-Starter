import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case noConnection
    case decodingError
    case unauthorized
    case forbidden
    case notFound
    case serverError(String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noConnection:
            return "No internet connection"
        case .decodingError:
            return "Failed to process server response"
        case .unauthorized:
            return "Session expired. Please sign in again"
        case .forbidden:
            return "Access denied"
        case .notFound:
            return "Resource not found"
        case .serverError(let message):
            return message
        case .unknown:
            return "An unexpected error occurred"
        }
    }
}
