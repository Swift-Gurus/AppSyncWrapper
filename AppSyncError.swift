//
//  AppSyncError.swift
//  AppSyncWrapper
//
//  Created by Esteban on 2020-01-14.
//

import Foundation
import AWSAppSync

/// Error That represents any AppSync Errors
///
/// - subscriptionFailed: subscription fails
enum AppSyncError: Error, Equatable {
    case subscriptionFailed
    case tokenExpired
    case refreshTokenNotSet
    case unknown
    
    init(error: Error) {
        self =  AppSyncError.convertIntoSelf(error: error) ??
                AppSyncError.convertIntoTokenExpired(error: error) ?? .unknown
    }

    private static func convertIntoSelf(error: Error) -> AppSyncError? {
        return error as? AppSyncError
    }
    
    private static func convertIntoTokenExpired(error: Error) -> AppSyncError? {
        guard let resp = (error as? AWSAppSyncClientError)?.response,
                let header = resp.allHeaderFields["x-amzn-errortype"] as? String,
                resp.statusCode == 401, header == "UnauthorizedException" else {
                    return nil
        }
        return .tokenExpired
    }
}

extension AWSAppSyncClientError {
    var response: HTTPURLResponse? {
        switch self {
        case .parseError(_, let response, _):
            return response
        case .requestFailed(_, let response, _):
            return response
        case .noData, .authenticationError: return nil
        }
    }
}

