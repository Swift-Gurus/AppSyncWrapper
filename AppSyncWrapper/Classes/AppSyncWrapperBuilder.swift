//
//  AppSyncWrapperBuilder.swift
//  AppSyncWrapper
//
//  Created by Alex Hmelevski on 2019-01-14.
//

import Foundation
import AWSAppSync
import EitherResult

public protocol LatestTokenReader {
    func getLatestToken() -> String
}

public protocol TokenRefresher {
    func refreshSessionForCurrentUser(completion: @escaping (ALResult<String>) -> Void)
}

enum AppSyncWrapperBuilderError: LocalizedError {
    case urlNotSet
    case tokenReaderNotSet
    case tokenRefresherNotSet
}

public enum AppSyncSenderType {
    case normal
    case tokenRefreshing
}

public final class AppSyncWrapperBuilder {
    
    public var tokenReader: LatestTokenReader!
    public var tokenRefresher: TokenRefresher!
    public var region: AWSRegionType = .APNortheast1
    public var url: URL!
    public var headerInfos: [String:String] = [:]
    public var cachePolicy: CachePolicy = .fetchIgnoringCacheData
    public var processQueue: DispatchQueue = .main
    
    public init() {} 
    
    public func getSender(type: AppSyncSenderType = .normal) throws -> GraphQLQuerySender & GraphQLMutationPerformer {
        let sender = AppSyncWrapper(config: try getWrapperConfig())
        switch type {
        case .normal: return sender
        case .tokenRefreshing: return AppSyncWrapperRefresher(decorated: sender,
                                                              tokenRefresher: try getTokenRefresher())
        }
    }
    
    private func getWrapperConfig() throws -> AppSyncWrapperConfig {
        return AppSyncWrapperConfig(cachePolicy: cachePolicy,
                                    processQueue: processQueue,
                                    resultConverter: GraphQLResultConverter(),
                                    appsyncClient:  try getClient() )
    }
    
    private func getClient() throws -> AWSAppSyncClient {
        return try AWSAppSyncClient(appSyncConfig: try getConfig())
    }
    
    private func getConfig() throws ->  AWSAppSyncClientConfiguration {
        do {
            let url = try getURL()
            let bridge = AWSCognitoUserPoolsAuthProviderBridge(latestTokenReader: try getLatestTokenReader())
            return try AWSAppSyncClientConfiguration(url: url,
                                                     serviceRegion: region,
                                                     userPoolsAuthProvider: bridge,
                                                     urlSessionConfiguration: getUrlSessionConfig())
        } catch {
            throw error
        }
    }
    
    private func getUrlSessionConfig() -> URLSessionConfiguration {
        let urlSessionConfiguration = URLSessionConfiguration.default
        urlSessionConfiguration.httpAdditionalHeaders = headerInfos
        return urlSessionConfiguration
    }
    
    
    private func getLatestTokenReader() throws  -> LatestTokenReader {
        guard let reader = tokenReader else { throw AppSyncWrapperBuilderError.tokenReaderNotSet }
        return reader
    }
    
    private func getTokenRefresher() throws  -> TokenRefresher {
        guard let refresher = tokenRefresher else { throw AppSyncWrapperBuilderError.tokenRefresherNotSet }
        return refresher
    }
    
    private func getURL() throws -> URL {
        guard let url = self.url else { throw AppSyncWrapperBuilderError.urlNotSet }
        return url
    }
    
}
