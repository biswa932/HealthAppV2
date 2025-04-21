//
//  LoginView.swift
//  healthAppv2
//
//  Created by Biswajyoti Saha on 20/04/25.
//
import SwiftUI

struct LoginView: View {
    var body: some View {
        VStack {
            Spacer()

            Text("Welcome to HealthApp")
                .font(.largeTitle)
                .padding()

            Button(action: {
                AuthManager.shared.signIn()
            }) {
                Text("Login or Sign Up")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .onAppear {
            print("Login view appeared")
        }
    }
}

