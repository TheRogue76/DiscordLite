//
//  ContentView.swift
//  DiscordLite
//
//  Created by Parsa's Content Creation Corner on 2025-12-25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            switch authViewModel.state {
            case .unauthenticated:
                LoginView(viewModel: authViewModel)

            case .authenticating:
                AuthLoadingView(viewModel: authViewModel)

            case .authenticated:
                HomeView(viewModel: authViewModel)

            case .error(let error):
                AuthErrorView(viewModel: authViewModel, error: error)
            }
        }
        .task {
            await authViewModel.checkExistingSession()
        }
    }
}

#Preview {
    ContentView()
}
