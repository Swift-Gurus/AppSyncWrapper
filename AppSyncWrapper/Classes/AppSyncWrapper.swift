//
//  AppSyncWrapper.swift
//  AppSyncWrapper
//
//  Created by Alex Hmelevski on 2019-01-14.
//

import Foundation
import AWSAppSync
import EitherResult


enum AppSyncWrapperError: LocalizedError {
    case nullObject
}

struct AppSyncWrapperConfig {
    var cachePolicy: CachePolicy = .fetchIgnoringCacheData
    var processQueue: DispatchQueue = .main
    var resultConverter: ResultConverter = GraphQLResultConverter()
    var appsyncClient: AWSAppSyncClient
}



public protocol GraphQLQuerySender {
    func sendQuery<Q: GraphQLQuery, T: GraphQLInitializable>(_ query: Q, completion: @escaping (ALResult<T>) -> Void) where Q.Data == T.Set
}

final class AppSyncWrapper: GraphQLQuerySender {
    
    let cachePolicy: CachePolicy
    let appsyncClient: AWSAppSyncClient
    let processQueue: DispatchQueue
    let resultConverter: ResultConverter
    
    init(config: AppSyncWrapperConfig) {
        self.cachePolicy = config.cachePolicy
        self.processQueue = config.processQueue
        self.resultConverter = config.resultConverter
        self.appsyncClient = config.appsyncClient
    }
    
    func sendQuery<Q: GraphQLQuery, T: GraphQLInitializable>(_ query: Q, completion: @escaping (ALResult<T>) -> Void) where Q.Data == T.Set {
        appsyncClient.fetch(query: query,
                            cachePolicy: cachePolicy,
                            queue: processQueue) {[weak self] (response, error) in
                                guard let `self` = self else { return }
                                let result = ALResult(value: response, error: error)
                                result.map({ ($0, query) }).flatMap(self.resultConverter.convert) » completion
      
        }
    }

}

