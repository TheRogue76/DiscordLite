import FactoryKit

extension Container {
    var channelGRPCDatasource: Factory<ChannelGRPCDatasource> {
        self {
            ChannelGRPCDatasourceImpl(
                grpcClient: self.grpcClient(),
                logger: self.logger()
            )
        }
        .singleton
    }

    var channelRepository: Factory<ChannelRepository> {
        self {
            ChannelRepositoryImpl(
                channelGRPCDatasource: self.channelGRPCDatasource(),
                logger: self.logger()
            )
        }
        .singleton
    }
}
