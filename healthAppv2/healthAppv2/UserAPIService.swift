//
//  UserAPIService.swift
//  healthAppv2
//
//  Created by Biswajyoti Saha on 20/04/25.
//

import Foundation

struct User: Codable {
    let name: String
    let email: String
    let dob: String
    let gender: String
    let height: String
    let weight: String
}

enum APIServiceError: Error, LocalizedError {
    case httpError(code: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        case .httpError(let code, let message):
            return "HTTP \(code): \(message)"
        }
    }
}

class UserAPIService {
    static let shared = UserAPIService()
    private let baseURL = "https://hrm5n0g2fc.execute-api.ap-southeast-2.amazonaws.com/users"
    
    private init() {}

    func getAccessToken() async throws -> String {
        if let token = KeychainHelper.read("accessToken") {
            return token
        } else if await AuthManager.shared.refreshAccessToken() {
            if let newToken = KeychainHelper.read("accessToken") {
                return newToken
            }
        }
        throw URLError(.userAuthenticationRequired)
    }

    private func performRequestWithRetry(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 401 {
            let refreshed = await AuthManager.shared.refreshAccessToken()
            if refreshed, let newToken = KeychainHelper.read("accessToken") {
                var newRequest = request
                newRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                return try await performRequestWithRetry(newRequest)
            } else {
                throw URLError(.userAuthenticationRequired)
            }
        }

        if !(200...299).contains(httpResponse.statusCode) {
            // Try to decode the error message from response
            let errorMessage = parseErrorMessage(from: data) ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            throw APIServiceError.httpError(code: httpResponse.statusCode, message: errorMessage)
        }

        return data
    }

    private func parseErrorMessage(from data: Data) -> String? {
        // Attempt to decode { "message": "Something went wrong" } or similar
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = json["message"] as? String {
            return message
        }
        return nil
    }

    func createUser(_ user: User) async throws {
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(user)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let token = try await getAccessToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try await performRequestWithRetry(request)
    }

    func getUser(email: String) async throws -> User {
        let url = URL(string: "\(baseURL)?email=\(email)")!  // Use query parameter
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let token = try await getAccessToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await performRequestWithRetry(request)
        return try JSONDecoder().decode(User.self, from: data)
    }

    func updateUser(_ user: User) async throws {
        // Use query parameter for email, as per Postman call
        let url = URL(string: "\(baseURL)?email=\(user.email)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try JSONEncoder().encode(user)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let token = try await getAccessToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try await performRequestWithRetry(request)
    }


    func deleteUser(email: String) async throws {
        // Use query parameter for email, as per Postman call
        let url = URL(string: "\(baseURL)?email=\(email)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let token = try await getAccessToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try await performRequestWithRetry(request)
    }

    // MARK: - JWT Decoding
    func decodeJWT(token: String) -> [String: Any] {
        let segments = token.split(separator: ".")
        guard segments.count > 1 else { return [:] }
        let payloadSegment = segments[1]
        var decodedPayload = payloadSegment.replacingOccurrences(of: "-", with: "+")
        decodedPayload = decodedPayload.replacingOccurrences(of: "_", with: "/")
        while decodedPayload.count % 4 != 0 {
            decodedPayload += "="
        }
        guard let payloadData = Data(base64Encoded: decodedPayload),
              let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            return [:]
        }
        return json
    }

}
