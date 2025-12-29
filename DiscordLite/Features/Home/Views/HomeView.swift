import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: AuthViewModel

    var session: AuthSession? {
        if case .authenticated(let session) = viewModel.state {
            return session
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to DiscordLite")
                .font(.largeTitle)
                .fontWeight(.bold)

            if let session = session {
                VStack(spacing: 12) {
                    HStack {
                        Text("Session ID:")
                            .fontWeight(.semibold)
                        Text(session.sessionID)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }

                    HStack {
                        Text("Created:")
                            .fontWeight(.semibold)
                        Text("N/A")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
            }

            Text("Phase 1: Authentication Complete")
                .font(.headline)
                .foregroundStyle(.green)
                .padding(.top)

            Text("More features coming in Phase 2...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Logout") {
                    Task {
                        await viewModel.logout()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

// #Preview { // TODO: break the view model view and the subviews apart so we can set them up for testing
//    HomeView(viewModel: {
//        let vm = AuthViewModel()
//        vm.state = .authenticated(session: AuthSession(
//            sessionID: "preview-session-123",
//        ))
//        return vm
//    }())
// }
