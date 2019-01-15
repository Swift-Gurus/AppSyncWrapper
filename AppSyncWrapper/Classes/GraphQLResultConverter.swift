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
    func convert<Q: GraphQLQuery, T: GraphQLInitializable>(response: GraphQLResult<Q.Data>,
                                                           ofQuery query: Q) -> ALResult<T> where Q.Data == T.Set
}

final class GraphQLResultConverter: ResultConverter {
    
    func convert<Q: GraphQLQuery, T: GraphQLInitializable>(response: GraphQLResult<Q.Data>,
                                                           ofQuery query: Q) -> ALResult<T> where Q.Data == T.Set {
        guard let data = response.data else { return .wrong(AppSyncWrapperError.nullObject) }
        return ALResult(data).map(T.init)
    }
}
