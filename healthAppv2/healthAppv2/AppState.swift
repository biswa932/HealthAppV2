//
//  AppState.swift
//  healthAppv2
//
//  Created by Biswajyoti Saha on 20/04/25.
//
import SwiftUI

class AppState: ObservableObject {
    enum Flow {
        case login
        case profileCreation
        case home
    }

    @Published var flow: Flow = .login
    @Published var currentUser: User?
    @Published var prefilledEmail: String?
}

