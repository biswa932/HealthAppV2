import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var appState = AppState()

    var body: some View {
        Group {
            switch appState.flow {
            case .login:
                LoginView()
            case .profileCreation:
                ProfileCreationView(
                    prefilledEmail: appState.prefilledEmail ?? ""
                )
            case .home:
                TabView {
                    HomeView()
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                    
                    HealthView()
                        .tabItem {
                            Label("Health", systemImage: "heart.fill")
                        }
                    
                    MilestoneView()
                        .tabItem {
                            Label("Milestone", systemImage: "star.fill")
                        }
                }
            }
        }
        .environmentObject(appState)

        // ✅ Handle login notification
        .onReceive(NotificationCenter.default.publisher(for: .loginCompleted)) { _ in
            Task {
                do {
                    // ✅ Get ID Token instead of Access Token
                    guard let idToken = KeychainHelper.read("idToken") else {
                        print("Missing ID token")
                        return
                    }
                    
                    let claims = UserAPIService.shared.decodeJWT(token: idToken)

                    if let email = claims["email"] as? String {
                        appState.prefilledEmail = email
                    }

                    if let email = appState.prefilledEmail {
                        do {
                            let user = try await UserAPIService.shared.getUser(email: email)
                            print("User: \(user)")
                            appState.currentUser = user
                            appState.flow = .home
                        } catch {
                            print("API Error: \(error.localizedDescription)")
                            appState.flow = .profileCreation
                        }
                    }
                }
            }
        }

        // ✅ Restore session if app launches with saved token
        .onAppear {
            if let token = KeychainHelper.read("accessToken") {
                print("access token: \(token)")
                authManager.accessToken = token
                authManager.isLoggedIn = true
                NotificationCenter.default.post(name: .loginCompleted, object: nil) // Trigger flow if already logged in
            }
        }
    }
}
