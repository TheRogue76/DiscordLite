import FactoryKit

extension Container {
    var messageGRPCDatasource: Factory<MessageGRPCDatasource> {
        self {
            MessageGRPCDatasourceImpl(
                grpcClient: self.grpcClient(),
                logger: self.logger()
            )
        }
        .singleton
    }

    var messageRepository: Factory<MessageRepository> {
        self {
            MessageRepositoryImpl(
                messageGRPCDatasource: self.messageGRPCDatasource(),
                logger: self.logger()
            )
        }
        .singleton
    }
}
