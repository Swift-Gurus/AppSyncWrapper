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
        guard let _ = getAWSAuthError(error: error) else { return nil }
        return .tokenExpired
    }
    
    private static func getAWSAuthError(error: Error) -> Error? {
        guard let awsError = error as? AWSAppSyncClientError else { return nil }
        guard case let .authenticationError(unWrappedError) = awsError else { return nil }
        return unWrappedError
    }
}

