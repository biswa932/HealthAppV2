//
//  healthAppv2App.swift
//  healthAppv2
//
//  Created by Biswajyoti Saha on 18/04/25.
//

import SwiftUI

@main
struct healthAppv2App: App {
    @StateObject private var authManager = AuthManager.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .onOpenURL { url in
                    // This won't be needed for ASWebAuthenticationSession,
                    // but useful if you ever need to catch URLs like logout callbacks
                    print("Received URL: \(url)")
                }
        }
    }
}
