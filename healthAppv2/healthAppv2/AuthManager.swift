//
//  AuthManager.swift
//  healthAppv2
//
//  Created by Biswajyoti Saha on 18/04/25.
//

import Foundation
import SafariServices
import UIKit
import SwiftUI
import AuthenticationServices

@MainActor
class AuthManager: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = AuthManager()

    let clientId = "3qsuhghh7deonv78rcqtrgpe52"
    let redirectUri = "myapp://callback"
    let domain = "https://ap-southeast-24hnx0bumu.auth.ap-southeast-2.amazoncognito.com"

    @Published var accessToken: String?
    @Published var isLoggedIn: Bool = false

    private var authSession: ASWebAuthenticationSession?

    func signIn() {
        let scope = "openid+email+profile"
        let responseType = "code"
        let state = UUID().uuidString

        let urlString = "\(domain)/login?client_id=\(clientId)&response_type=\(responseType)&scope=\(scope)&redirect_uri=\(redirectUri)&state=\(state)"

        guard let authURL = URL(string: urlString),
              let callbackURLScheme = URL(string: redirectUri)?.scheme else {
            return
        }

        authSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: callbackURLScheme
        ) { callbackURL, error in
            guard error == nil,
                  let callbackURL = callbackURL,
                  let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                  let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                print("Authentication failed or was cancelled.")
                return
            }
            Task {
                await self.exchangeCodeForToken(code: code)
            }
        }

        authSession?.presentationContextProvider = self
        authSession?.prefersEphemeralWebBrowserSession = true
        authSession?.start()
    }

    func exchangeCodeForToken(code: String) async {
        let url = URL(string: "\(domain)/oauth2/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let body = "grant_type=authorization_code&client_id=\(clientId)&code=\(code)&redirect_uri=\(redirectUri)"
        request.httpBody = body.data(using: .utf8)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let accessToken = json["access_token"] as? String,
                  let refreshToken = json["refresh_token"] as? String,
                  let idToken = json["id_token"] as? String else {
                return
            }

            self.accessToken = accessToken
            self.isLoggedIn = true
            KeychainHelper.save("accessToken", value: accessToken)
            KeychainHelper.save("refreshToken", value: refreshToken)
            KeychainHelper.save("idToken", value: idToken) // ✅ Save ID token

            // ✅ Notify login success
            NotificationCenter.default.post(name: .loginCompleted, object: nil)
        } catch {
            print("Token exchange failed: \(error)")
        }
    }

    func refreshAccessToken() async -> Bool {
        guard let refreshToken = KeychainHelper.read("refreshToken") else {
            return false
        }

        let url = URL(string: "\(domain)/oauth2/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let body = "grant_type=refresh_token&client_id=\(clientId)&refresh_token=\(refreshToken)"
        request.httpBody = body.data(using: .utf8)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let newAccessToken = json["access_token"] as? String else {
                return false
            }

            self.accessToken = newAccessToken
            KeychainHelper.save("accessToken", value: newAccessToken)
            return true
        } catch {
            print("Refresh token failed: \(error)")
            return false
        }
    }

    func signOut() {
        let logoutRedirectUri = "myapp://signout"
        let logoutURLString = "\(domain)/logout?client_id=\(clientId)&logout_uri=\(logoutRedirectUri)"

        guard let logoutURL = URL(string: logoutURLString),
              let callbackURLScheme = URL(string: logoutRedirectUri)?.scheme else {
            return
        }

        authSession = ASWebAuthenticationSession(
            url: logoutURL,
            callbackURLScheme: callbackURLScheme
        ) { callbackURL, error in
            if let error = error {
                print("Logout session error: \(error)")
            }
            Task {
                self.accessToken = nil
                self.isLoggedIn = false
                KeychainHelper.delete("accessToken")
                KeychainHelper.delete("refreshToken")
            }
        }

        authSession?.presentationContextProvider = self
        authSession?.prefersEphemeralWebBrowserSession = true
        authSession?.start()
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            return windowScene.windows.first { $0.isKeyWindow } ?? UIWindow()
        }
        return UIWindow()
    }
}

// MARK: - Notification Name Extension
extension Notification.Name {
    static let loginCompleted = Notification.Name("LoginCompleted")
}
