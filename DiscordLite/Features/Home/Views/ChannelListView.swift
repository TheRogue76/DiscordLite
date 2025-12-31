import SwiftUI

struct ChannelListView: View {
    @ObservedObject var viewModel: ChannelViewModel
    let selectedGuild: Guild?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                if let guild = selectedGuild {
                    Text(guild.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                } else {
                    Text("No Server Selected")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if selectedGuild != nil {
                    Button(action: {
                        if let guildId = selectedGuild?.id {
                            Task {
                                await viewModel.refresh(guildId: guildId)
                            }
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
                        "No Server Selected",
                        systemImage: "sidebar.left",
                        description: Text("Select a server to view channels")
                    )

                case .loading:
                    ProgressView("Loading channels...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .loaded(let channels):
                    if channels.isEmpty {
                        ContentUnavailableView(
                            "No Channels",
                            systemImage: "number.square",
                            description: Text("This server has no text channels")
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 1, pinnedViews: [.sectionHeaders]) {
                                Section {
                                    ForEach(channels) { channel in
                                        ChannelRow(
                                            channel: channel,
                                            isSelected: viewModel.selectedChannel?.id == channel.id
                                        )
                                        .onTapGesture {
                                            viewModel.selectChannel(channel)
                                        }
                                    }
                                } header: {
                                    HStack {
                                        Text("TEXT CHANNELS")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(.controlBackgroundColor))
                                }
                            }
                            .padding(.vertical, 8)
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
        .frame(width: 220)
        .background(Color(.controlBackgroundColor).opacity(0.5))
    }
}

struct ChannelRow: View {
    let channel: Channel
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: channel.type.icon)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 16)

            Text(channel.name)
                .font(.body)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .contentShape(Rectangle())
    }
}
