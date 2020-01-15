//
//  AppSyncWrapperRefresher.swift
//  AppSyncWrapper
//
//  Created by Esteban on 2020-01-14.
//

import Foundation
import AWSAppSync
import EitherResult

typealias VoidClosure = () -> Void
typealias Closure<T>  = (T) -> Void
typealias Callback<T> = (ALResult<T>) -> Void

public typealias AppSyncSenderMutator = GraphQLQuerySender &
                                        GraphQLMutationPerformer

class AppSyncWrapperRefresher: AppSyncSenderMutator {
    private let decorated: AppSyncSenderMutator
    private var tokenRefresher: TokenRefresher

    init(decorated: AppSyncSenderMutator, tokenRefresher: TokenRefresher) {
        self.decorated = decorated
        self.tokenRefresher = tokenRefresher
    }

    func sendQuery<Q, T>(_ query: Q,
                                completion: @escaping (ALResult<T>) -> Void) where Q : GraphQLQuery,
                                                                                   T : GraphQLInitializable,
                                                                                   Q.Data == T.Set {
        let proccessErrorClosure = getErrorHandler(using: { [weak self] in self?.sendQuery(query, completion: completion) },
                                                   errorCompletion: completion)
        
        self.decorated.sendQuery(query,
                                 completion: { (response: ALResult<T>) in
                                    response.do(work: { _  in completion(response) })
                                            .onError(proccessErrorClosure)
                                 })
    }
    
    func performMutation<M, T>(_ mutation: M,
                                      completion: @escaping (ALResult<T>) -> Void) where M : GraphQLMutation,
                                                                                         T : GraphQLInitializable,
                                                                                         M.Data == T.Set {
        let proccessErrorClosure = getErrorHandler(using: { [weak self] in self?.performMutation(mutation, completion: completion) },
                                                   errorCompletion: completion)
        
        self.decorated.performMutation(mutation,
                                       completion: { (response: ALResult<T>) in
                                            response.do(work: { _  in completion(response) })
                                                    .onError(proccessErrorClosure)
                                       })
    }
    
    private func getErrorHandler<T>(using retryFunction: @escaping VoidClosure,
                                    errorCompletion    : @escaping Callback<T>) -> Closure<Error> {
        return { [weak self] (error) in
                    self?.handleError(error: error,
                                      successCompletion: { retryFunction() },
                                      errorCompletion: errorCompletion)
               }
    }
    
    private func sendRefreshTokenRequest(successCompletion: @escaping VoidClosure,
                                         errorCompletion  : @escaping Closure<Error>) {
        
        self.tokenRefresher.refreshSessionForCurrentUser(completion: { result in
            result.do(work: { _ in successCompletion() })
                  .onError(errorCompletion)
        })
    }
    
    private func handleError<T>(error: Error,
                                successCompletion: @escaping VoidClosure,
                                errorCompletion  : @escaping Callback<T>) {
        let callErrorCompletion: Closure<Error> = { errorCompletion(.wrong($0)) }
        if AppSyncError(error: error) == .tokenExpired {
            sendRefreshTokenRequest(successCompletion: successCompletion,
                                    errorCompletion: callErrorCompletion)
        } else {
            callErrorCompletion(error)
        }
    }
 }
