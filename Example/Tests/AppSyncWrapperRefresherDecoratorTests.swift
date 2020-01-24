//
//  AppSyncWrapperRefresherDecoratorTests.swift
//  AppSyncWrapper_Tests
//
//  Created by Esteban on 2020-01-23.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import XCTest
import EitherResult
import AWSAppSync
@testable import AppSyncWrapper

final class TokenReaderWriterMock: LatestTokenReader & LatestTokenWriter {
    private var token: String

    public var getLatestTokenWasCalled = 0
    public var saveTokenWasCalled = 0

    init(initialToken: String) {
        self.token = initialToken
    }
    func getLatestToken() -> String {
        getLatestTokenWasCalled += 1
        return token
    }
    func saveToken(_ string: String) {
        saveTokenWasCalled += 1
        self.token = string
    }
}

final class TokenRefresherMock: TokenRefresher {
    public var refreshSessionWasCalled = 0
    func refreshSessionForCurrentUser(completion: @escaping (ALResult<String>) -> Void) {
        refreshSessionWasCalled += 1
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomToken = String((0..<10).map { _ in letters.randomElement()! })
        completion(.right(randomToken))
    }
}

final class MockQuery: GraphQLQuery {
    public static let operationString = ""
    public struct Data: GraphQLSelectionSet {
        public static var selections: [GraphQLSelection] = []
        public var snapshot: Snapshot
    }
}

struct QueryResponseMock {
    let response: String
    static var empty: QueryResponseMock {
        return QueryResponseMock(response: "Empty response")
    }
}

extension QueryResponseMock: GraphQLInitializable {
    typealias Set = MockQuery.Data
    init(selectionSet: MockQuery.Data) {
        response = ""
    }
}

final class AppSyncWrapperMock<Q: GraphQLQuery, T: GraphQLInitializable>: AppSyncWrapper where Q.Data == T.Set {
    public var desiredResponse: ALResult<T>!
    public var secundaryResponse: ALResult<T>? = nil
    private var shouldSendSecundaryResponse = false

    override func sendQuery<Q, T>(_ query: Q, completion: @escaping (ALResult<T>) -> Void) {
        if shouldSendSecundaryResponse {
            completion(secundaryResponse as! ALResult<T>)
            return
        }
        
        if secundaryResponse != nil {
            shouldSendSecundaryResponse = true
        }
        
        completion(desiredResponse as! ALResult<T>)
    }
}

class AppSyncWrapperRefresherDecoratorTests: XCTestCase {

    private var builder: AppSyncWrapperBuilder!
    private var appSyncMock: AppSyncWrapperMock<MockQuery,QueryResponseMock>!
    private var tokenStorage: (LatestTokenReader & LatestTokenWriter)!
    private var tokenRefresher: TokenRefresherMock!

    override func setUp() {
        builder = AppSyncWrapperBuilder()
        tokenStorage = TokenReaderWriterMock(initialToken: "MyInitialToken")
        tokenRefresher = TokenRefresherMock()
        builder.url = URL(string: "https://www.google.com")
        builder.tokenReader = tokenStorage
        builder.tokenWriter = tokenStorage
        builder.tokenRefresher = tokenRefresher
        
        appSyncMock = AppSyncWrapperMock<MockQuery,QueryResponseMock>()
    }

    func test_sendQuery_token_refresher_retries_10_times_when_token_expired_error_is_returned_multiple_times() {
        appSyncMock.desiredResponse = .wrong(AppSyncError.tokenExpired)
        builder.appSyncWrapperMock = appSyncMock
        
        let sender = try! builder.getSender()

        let query = MockQuery()
        let sendCompletion: Callback<QueryResponseMock> = { _ in }
        sender.sendQuery(query, completion: sendCompletion)
        
        XCTAssertTrue(tokenRefresher.refreshSessionWasCalled == 10, "")
    }
    
    func test_sendQuery_token_refresher_is_not_called_when_a_non_token_expired_error_is_returned() {
        appSyncMock.desiredResponse = .wrong(NSError())
        builder.appSyncWrapperMock = appSyncMock
        
        let sender = try! builder.getSender()

        let query = MockQuery()
        let sendCompletion: Callback<QueryResponseMock> = { _ in }
        sender.sendQuery(query, completion: sendCompletion)
        
        XCTAssertTrue(tokenRefresher.refreshSessionWasCalled == 0, "")
    }
    
    func test_sendQuery_token_refresher_is_called_only_once_after_token_is_refreshed() {
        appSyncMock.desiredResponse = .wrong(AppSyncError.tokenExpired)
        appSyncMock.secundaryResponse = .right(QueryResponseMock.empty)
        builder.appSyncWrapperMock = appSyncMock
        
        let sender = try! builder.getSender()

        let query = MockQuery()
        let sendCompletion: Callback<QueryResponseMock> = { _ in }
        sender.sendQuery(query, completion: sendCompletion)
        
        XCTAssertTrue(tokenRefresher.refreshSessionWasCalled == 1, "")
    }
}
