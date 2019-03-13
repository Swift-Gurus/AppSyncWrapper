//
//  GraphQLResultConverter.swift
//  AppSyncWrapper
//
//  Created by Alex Hmelevski on 2019-01-14.
//

import Foundation
import AWSAppSync
import EitherResult


public protocol GraphQLInitializable {
    associatedtype Set: GraphQLSelectionSet
    init(selectionSet: Set)
}

protocol ResultConverter {
    func convert<O: GraphQLOperation, T: GraphQLInitializable>(response: GraphQLResult<O.Data>,
                                                           ofOperation operation: O) -> ALResult<T> where O.Data == T.Set
}

final class GraphQLResultConverter: ResultConverter {
    
    func convert<O: GraphQLOperation, T: GraphQLInitializable>(response: GraphQLResult<O.Data>,
                                                           ofOperation operation: O) -> ALResult<T> where O.Data == T.Set {
        guard let data = response.data else { return .wrong(AppSyncWrapperError.nullObject) }
        return ALResult(data).map(T.init)
    }
}
