import SwiftUI

struct MessageListView: View {
    @ObservedObject var viewModel: MessageViewModel
    let selectedChannel: Channel?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                if let channel = selectedChannel {
                    Image(systemName: channel.type.icon)
                        .foregroundStyle(.secondary)
                    Text(channel.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                } else {
                    Text("No Channel Selected")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if selectedChannel != nil {
                    Button(action: {
                        Task {
                            await viewModel.refresh()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.state == .loading)
                }
            }
            .padding()
            .background(Color(.windowBackgroundColor))

            Divider()

            // Content
            Group {
                switch viewModel.state {
                case .idle:
                    ContentUnavailableView(
                        "No Channel Selected",
                        systemImage: "message",
                        description: Text("Select a channel to view messages")
                    )

                case .loading:
                    ProgressView("Loading messages...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .loaded(let messages, let hasMore):
                    if messages.isEmpty {
                        ContentUnavailableView(
                            "No Messages",
                            systemImage: "message.slash",
                            description: Text("This channel has no messages yet")
                        )
                    } else {
                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 0) {
                                    if hasMore {
                                        Button(action: {
                                            Task {
                                                await viewModel.loadMoreMessages()
                                            }
                                        }) {
                                            HStack {
                                                if case .loadingMore = viewModel.state {
                                                    ProgressView()
                                                        .scaleEffect(0.8)
                                                }
                                                Text("Load older messages")
                                                    .font(.subheadline)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(viewModel.state == .loadingMore)
                                        .id("loadMore")
                                    }

                                    ForEach(messages) { message in
                                        MessageRow(message: message)
                                            .id(message.id)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .onAppear {
                                if let lastMessage = messages.last {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                case .loadingMore:
                    // Use viewModel.messages for loadingMore state
                    if viewModel.messages.isEmpty {
                        ContentUnavailableView(
                            "No Messages",
                            systemImage: "message.slash",
                            description: Text("This channel has no messages yet")
                        )
                    } else {
                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 0) {
                                    Button(action: {
                                        Task {
                                            await viewModel.loadMoreMessages()
                                        }
                                    }) {
                                        HStack {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                            Text("Load older messages")
                                                .font(.subheadline)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(true)
                                    .id("loadMore")

                                    ForEach(viewModel.messages) { message in
                                        MessageRow(message: message)
                                            .id(message.id)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .onAppear {
                                if let lastMessage = viewModel.messages.last {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                case .error(let message):
                    ContentUnavailableView(
                        "Error",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message)
                    )
                }
            }
        }
        .background(Color(.textBackgroundColor))
        .onAppear {
            if let channel = selectedChannel {
                viewModel.startStreaming(channelId: channel.id)
            }
        }
        .onDisappear {
            viewModel.stopStreaming()
        }
    }
}

struct MessageRow: View {
    let message: Message

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(message.author.initial)
                        .font(.headline)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(message.author.username)
                        .font(.body)
                        .fontWeight(.semibold)

                    Text(message.formattedTimestamp)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(message.content)
                    .font(.body)
                    .textSelection(.enabled)
            }
        }
        .padding(.vertical, 8)
    }
}
