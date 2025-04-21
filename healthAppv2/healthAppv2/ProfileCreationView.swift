//
//  ProfileCreationView.swift
//  healthAppv2
//
//  Created by Biswajyoti Saha on 20/04/25.
//

import SwiftUI

struct ProfileCreationView: View {
    @EnvironmentObject var appState: AppState

    var prefilledEmail: String

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var dob: String = ""
    @State private var gender: String = ""
    @State private var height: String = ""
    @State private var weight: String = ""

    var body: some View {
        Form {
            TextField("Name", text: $name)
            TextField("Email", text: $email)
                .disabled(true) // make read-only

            TextField("DOB (yyyy-mm-dd)", text: $dob)
            TextField("Gender", text: $gender)
            TextField("Height (cm)", text: $height)
            TextField("Weight (kg)", text: $weight)

            Button("Submit") {
                Task {
                    let newUser = User(
                        name: name,
                        email: email,
                        dob: dob,
                        gender: gender,
                        height: height,
                        weight: weight
                    )
                    do {
                        try await UserAPIService.shared.createUser(newUser)
                        appState.currentUser = newUser
                        appState.flow = .home
                    } catch {
                        print("API Error: \(error.localizedDescription)")
                        print("Error creating user: \(error)")
                    }
                }
            }
        }
        .navigationTitle("Create Profile")
        .onAppear {
            email = prefilledEmail
        }
    }
}
