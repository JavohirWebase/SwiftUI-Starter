import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case noConnection
    case decodingError
    case unauthorized
    case forbidden
    case notFound
    case serverError(String)
    case validationError(String)
    case unknown
    
    var errorDescription: String? {
         switch self {
         case .invalidURL:
             return "Invalid URL"
         case .noConnection:
             return "Internet ulanishi yo'q"
         case .decodingError:
             return "Ma'lumotlarni o'qishda xatolik"
         case .unauthorized:
             return "Sessiya tugadi. Qayta kiring"
         case .forbidden:
             return "Ruxsat yo'q"
         case .notFound:
             return "Ma'lumot topilmadi"
         case .serverError(let message):
             return message
         case .validationError(let message):
             return message
         case .unknown:
             return "Noma'lum xatolik"
         }
     }
}

struct ServerErrorResponse: Decodable {
    let errors: [String: [String]]?
    let type: String?
    let title: String?
    let status: Int?
    let traceId: String?
    
    var userMessage: String {
        if let errors = errors {
            let allMessages = errors.values.flatMap { $0 }
            if !allMessages.isEmpty {
                return allMessages.joined(separator: ". ")
            }
        }
        
        if let title = title, !title.isEmpty {
            return title
        }
        
        return "Xatolik yuz berdi"
    }
    
    var allErrors: [String] {
        guard let errors = errors else { return [] }
        return errors.values.flatMap { $0 }
    }
}
