//
//  HomeView.swift
//  healthAppv2
//
//  Created by Biswajyoti Saha on 20/04/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 12) {
                if let user = appState.currentUser {
                    Text("Welcome, \(user.name)")
                    Text("Email: \(user.email)")
                    Text("DOB: \(user.dob)")
                    Text("Gender: \(user.gender)")
                    Text("Height: \(user.height) cm")
                    Text("Weight: \(user.weight) kg")
                }

                Button("Sign Out") {
                    AuthManager.shared.signOut()
                    appState.flow = .login
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}

