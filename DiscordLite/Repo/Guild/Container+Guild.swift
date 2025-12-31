import FactoryKit

extension Container {
    // MARK: - Guild Datasource
    var guildGRPCDatasource: Factory<GuildGRPCDatasource> {
        self {
            GuildGRPCDatasourceImpl(
                grpcClient: self.grpcClient(),
                logger: self.logger()
            )
        }
        .singleton
    }

    // MARK: - Guild Repository
    var guildRepository: Factory<GuildRepository> {
        self {
            GuildRepositoryImpl(
                guildGRPCDatasource: self.guildGRPCDatasource(),
                logger: self.logger()
            )
        }
        .singleton
    }
}
