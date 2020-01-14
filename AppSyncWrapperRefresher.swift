//
//  AppSyncWrapperRefresher.swift
//  AppSyncWrapper
//
//  Created by Esteban on 2020-01-14.
//

import Foundation
import AWSAppSync
import EitherResult

public typealias VoidClosure = () -> Void
public typealias AppSyncSenderMutator = GraphQLQuerySender &
                                        GraphQLMutationPerformer

public protocol TokenRefresher {
    func refreshSessionForCurrentUser(completion: @escaping (ALResult<String>) -> Void)
}

public class AppSyncWrapperRefresher: AppSyncSenderMutator {
    private let decorated: AppSyncSenderMutator
    private var tokenRefresher: TokenRefresher

    init(decorated: AppSyncSenderMutator, tokenRefresher: TokenRefresher) {
        self.decorated = decorated
        self.tokenRefresher = tokenRefresher
    }

    public func sendQuery<Q, T>(_ query: Q, completion: @escaping (ALResult<T>) -> Void) where Q : GraphQLQuery, T : GraphQLInitializable, Q.Data == T.Set {
        self.decorated.sendQuery(query, completion: { [weak self] (response: ALResult<T>) in
            response.do(work: { _ in completion(response) })
                    .onError({
                        self?.handleRefresh(error: $0,
                        successCompletion: { self?.sendQuery(query, completion: completion) },
                        errorCompletion: {
                            completion(ALResult($0))
                        })
                    })
        })
    }
    
    public func performMutation<M, T>(_ mutation: M, completion: @escaping (ALResult<T>) -> Void) where M : GraphQLMutation, T : GraphQLInitializable, M.Data == T.Set {
        self.decorated.performMutation(mutation, completion: { [weak self] (response: ALResult<T>) in
          response.do(work: { _ in completion(response) })
          .onError({
              self?.handleRefresh(error: $0,
              successCompletion: { self?.performMutation(mutation, completion: completion) },
              errorCompletion: {
                  completion(ALResult($0))
              })
          })
        })
    }
    
    private func sendRefreshTokenRequest(successCompletion: @escaping VoidClosure,
                                         errorCompletion  : @escaping ((Error) -> Void)) {
        self.tokenRefresher.refreshSessionForCurrentUser(completion: { result in
            result.do(work: { _ in successCompletion() })
                  .onError(errorCompletion)
        })
    }
    
    private func handleRefresh(error: Error,
                               successCompletion: @escaping VoidClosure,
                               errorCompletion  : @escaping ((Error) -> Void)) {
                
        if AppSyncError(error: error) == .tokenExpired {
            sendRefreshTokenRequest(successCompletion: successCompletion, errorCompletion: errorCompletion)
        } else {
            errorCompletion(error)
        }
    }
}
