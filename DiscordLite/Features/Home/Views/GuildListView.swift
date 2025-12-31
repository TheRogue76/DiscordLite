import SwiftUI

struct GuildListView: View {
    @ObservedObject var viewModel: GuildViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Servers")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

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
            .padding()
            .background(Color(.windowBackgroundColor))

            Divider()

            // Content
            Group {
                switch viewModel.state {
                case .idle:
                    ContentUnavailableView(
                        "No Servers",
                        systemImage: "square.stack.3d.up.slash",
                        description: Text("Load servers to get started")
                    )

                case .loading:
                    ProgressView("Loading servers...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .loaded(let guilds):
                    if guilds.isEmpty {
                        ContentUnavailableView(
                            "No Servers",
                            systemImage: "square.stack.3d.up.slash",
                            description: Text("You're not a member of any servers")
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 2) {
                                ForEach(guilds) { guild in
                                    GuildRow(
                                        guild: guild,
                                        isSelected: viewModel.selectedGuild?.id == guild.id
                                    )
                                    .onTapGesture {
                                        viewModel.selectGuild(guild)
                                    }
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
        .frame(width: 240)
        .background(Color(.controlBackgroundColor))
    }
}

struct GuildRow: View {
    let guild: Guild
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Guild icon placeholder (use first letter of name)
            Circle()
                .fill(isSelected ? Color.accentColor : Color.gray)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(guild.name.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.white)
                )

            Text(guild.name)
                .font(.body)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
    }
}
