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
    private var tokenWriter: LatestTokenWriter
    private let maxNumberOfRetries = 10

    init(decorated: AppSyncSenderMutator,
         tokenRefresher: TokenRefresher,
         tokenWriter: LatestTokenWriter) {
        self.decorated = decorated
        self.tokenRefresher = tokenRefresher
        self.tokenWriter = tokenWriter
    }

    func sendQuery<Q, T>(_ query: Q, completion: @escaping (ALResult<T>) -> Void)
                        where Q: GraphQLQuery, T: GraphQLInitializable, Q.Data == T.Set {
        self.sendQuery(query, count: maxNumberOfRetries, completion: completion)
    }
    
    func sendQuery<Q, T>(_ query: Q, count: Int, completion: @escaping (ALResult<T>) -> Void)
                        where Q : GraphQLQuery, T : GraphQLInitializable, Q.Data == T.Set {
        
        guard count > 0 else { completion(.wrong(AppSyncError.tooManyRetries)); return }
        
        let proccessErrorClosure = getErrorHandler(using: { [weak self] in self?.sendQuery(query,
                                                                                           count: count-1,
                                                                                           completion: completion) },
                                                   errorCompletion: completion)
        
        self.decorated.sendQuery(query,
                                 completion: { (response: ALResult<T>) in
                                    response.do(work: { _  in completion(response) })
                                            .onError(proccessErrorClosure)
                                 })
    }
    
    func performMutation<M, T>(_ mutation: M, completion: @escaping (ALResult<T>) -> Void)
                              where M : GraphQLMutation, T : GraphQLInitializable, M.Data == T.Set {
        self.performMutation(mutation, count: maxNumberOfRetries, completion: completion)
    }
    
    func performMutation<M, T>(_ mutation: M, count: Int, completion: @escaping (ALResult<T>) -> Void)
    where M : GraphQLMutation, T : GraphQLInitializable, M.Data == T.Set {
        
        guard count > 0 else { completion(.wrong(AppSyncError.tooManyRetries)); return }
        
        let proccessErrorClosure = getErrorHandler(using: { [weak self] in self?.performMutation(mutation,
                                                                                                 count: count-1,
                                                                                                 completion: completion) },
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
        
        let successClosure: Closure<String> = { [weak self] (token) in
            self?.tokenWriter.saveToken(token)
            successCompletion()
        }
        
        self.tokenRefresher.refreshSessionForCurrentUser(completion: { result in
            result.do(work: successClosure)
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
