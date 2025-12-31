import FactoryKit
import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: AuthViewModel

    @StateObject private var guildViewModel: GuildViewModel
    @StateObject private var channelViewModel: ChannelViewModel
    @StateObject private var messageViewModel: MessageViewModel

    var session: AuthSession? {
        if case .authenticated(let session) = viewModel.state {
            return session
        }
        return nil
    }

    init(viewModel: AuthViewModel) {
        self.viewModel = viewModel

        // Extract sessionID from AuthViewModel state
        let sessionID: String
        if case .authenticated(let session) = viewModel.state {
            sessionID = session.sessionID
        } else {
            sessionID = ""
        }

        _guildViewModel = StateObject(wrappedValue: GuildViewModel(
            guildRepository: Container.shared.guildRepository(),
            logger: Container.shared.logger(),
            sessionID: sessionID
        ))

        _channelViewModel = StateObject(wrappedValue: ChannelViewModel(
            channelRepository: Container.shared.channelRepository(),
            logger: Container.shared.logger(),
            sessionID: sessionID
        ))

        _messageViewModel = StateObject(wrappedValue: MessageViewModel(
            messageRepository: Container.shared.messageRepository(),
            logger: Container.shared.logger(),
            sessionID: sessionID
        ))
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left pane: Guilds
            GuildListView(viewModel: guildViewModel)

            Divider()

            // Middle pane: Channels
            ChannelListView(
                viewModel: channelViewModel,
                selectedGuild: guildViewModel.selectedGuild
            )

            Divider()

            // Right pane: Messages
            MessageListView(
                viewModel: messageViewModel,
                selectedChannel: channelViewModel.selectedChannel
            )
        }
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
        .task {
            await guildViewModel.loadGuilds()
        }
        .onChange(of: guildViewModel.selectedGuild) { _, newGuild in
            // Load channels when guild selection changes
            if let guild = newGuild {
                Task {
                    await channelViewModel.loadChannels(guildId: guild.id)
                }
            }
        }
        .onChange(of: channelViewModel.selectedChannel) { _, newChannel in
            // Stop streaming for old channel and load messages for new channel
            messageViewModel.stopStreaming()

            if let channel = newChannel {
                Task {
                    await messageViewModel.loadMessages(channelId: channel.id)
                    messageViewModel.startStreaming(channelId: channel.id)
                }
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
