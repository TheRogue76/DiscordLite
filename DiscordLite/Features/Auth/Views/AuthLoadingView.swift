import SwiftUI

struct AuthLoadingView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView()
                .controlSize(.large)
                .scaleEffect(1.5)

            Text("Waiting for authentication...")
                .font(.title2)
                .fontWeight(.medium)

            Text("Please complete authentication in your browser")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            Button("Cancel") {
                viewModel.cancelAuth()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(40)
        .frame(minWidth: 500, minHeight: 400)
    }
}

//#Preview { // TODO: break the view model view and the subviews apart so we can set them up for testing
//    AuthLoadingView(viewModel: AuthViewModel())
//}
