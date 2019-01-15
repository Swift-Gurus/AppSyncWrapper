//
//  AppSyncWrapperBuilder.swift
//  AppSyncWrapper
//
//  Created by Alex Hmelevski on 2019-01-14.
//

import Foundation
import AWSAppSync

public protocol LatestTokenReader {
    func getLatestToken() -> String
}

enum AppSyncWrapperBuilderError: LocalizedError {
    case urlNotSet
    case tokenReaderNotSet
}

public final class AppSyncWrapperBuilder {
    
    public var tokenReader: LatestTokenReader!
    public var region: AWSRegionType = .APNortheast1
    public var url: URL!
    public var cachePolicy: CachePolicy = .fetchIgnoringCacheData
    public var processQueue: DispatchQueue = .main
    
    public init() {} 
    
    public func getSender() throws -> GraphQLQuerySender {
        return AppSyncWrapper(config: try getWrapperConfig())
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
                                                     userPoolsAuthProvider: bridge)
        } catch {
            throw error
        }
    }
    
    
    private func getLatestTokenReader() throws  -> LatestTokenReader {
        guard let reader = tokenReader else { throw AppSyncWrapperBuilderError.tokenReaderNotSet }
        return reader
    }
    
    private func getURL() throws -> URL {
        guard let url = self.url else { throw AppSyncWrapperBuilderError.urlNotSet }
        return url
    }
    
}
