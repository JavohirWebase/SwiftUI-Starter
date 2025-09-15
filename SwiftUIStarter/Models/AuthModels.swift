import Foundation

struct SignInRequest: Encodable {
    let username: String
    let password: String
}

struct SignInResponse: Decodable {
    let token: String
    let accessToken: String
    let accessTokenExpireAt: String
    let refreshToken: String
    let refreshTokenExpireAt: String
    let userInfo: User
}

struct User: Codable {
    let id: Int?
    let inn: String?
    let userName: String?
    let fullName: String?
    let shortName: String?
    let middleName: String?
    let lastName: String?
    let firstName: String?
    let isAdmin: Bool
    let languageId: Int?
    let languageCode: String?
    let language: String?
    let pinfl: String?
    let organizationId: Int?
    let positionId: Int?
    let stateId: Int?
    let email: String?
    let phoneNumber: String?
    let position: String?
    let organization: String?
    let organizationInn: String?
    let organizationVatCode: String?
    let organizationAddress: String?
    let hasSecondUnitOfMeasure: Bool
    let userTypeId: Int?
    let isSimpleUser: Bool
    let isOrgAdmin: Bool
    let isSuperAdmin: Bool
    let userType: String?
    let employeeId: Int?
    let organizationCurrencyId: Int?
    let userOrgAreasOfActivities: [Int]?
    let modules: [String]?
    let roles: [String]?
    let userFirebaseDeviceTokens: [DeviceToken]?
    
    var displayName: String {
        fullName ?? shortName ?? userName ?? "User"
    }
    
    var initials: String {
        guard let firstName = firstName?.first,
              let lastName = lastName?.first else {
            return displayName.prefix(2).uppercased()
        }
        return "\(firstName)\(lastName)".uppercased()
    }
}

struct DeviceToken: Codable {
    let deviceKey: String?
    let deviceToken: String?
}
