import FactoryKit

extension Container {
    // MARK: - Config
    var appConfig: Factory<AppConfig> {
        self { AppConfig.default }
            .singleton
    }
}
