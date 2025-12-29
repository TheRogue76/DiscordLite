import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // App Logo/Title
            VStack(spacing: 12) {
                Image(systemName: "message.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("DiscordLite")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("A native Discord client for macOS")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Sign in button
            Button(action: {
                isLoading = true
                Task {
                    await viewModel.startAuth()
                    isLoading = false
                }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.trailing, 8)
                    }
                    Text("Sign in with Discord")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(red: 0x58/255, green: 0x65/255, blue: 0xF2/255))
                .foregroundStyle(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
            .frame(width: 300)

            Spacer()
        }
        .padding(40)
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview {
    LoginView(viewModel: AuthViewModel())
}
