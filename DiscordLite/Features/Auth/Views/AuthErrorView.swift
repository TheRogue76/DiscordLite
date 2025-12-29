import SwiftUI

struct AuthErrorView: View {
    @ObservedObject var viewModel: AuthViewModel
    let error: LocalizedStringKey

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red)

            Text("Authentication Error")
                .font(.title)
                .fontWeight(.bold)

            Text(error)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            HStack(spacing: 16) {
                Button("Cancel") {
                    viewModel.cancelAuth()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button("Try Again") {
                    Task {
                        await viewModel.startAuth()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(40)
        .frame(minWidth: 500, minHeight: 400)
    }
}

// #Preview { // TODO: break the view model view and the subviews apart so we can set them up for testing
//    AuthErrorView(
//        viewModel: AuthViewModel(),
//        error: "Random Error"
//    )
// }
