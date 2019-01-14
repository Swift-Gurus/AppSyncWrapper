//
//  AWSCognitoUserPoolsAuthProviderBridge.swift
//  AppSyncWrapper
//
//  Created by Alex Hmelevski on 2019-01-14.
//

import Foundation
import AWSAppSync

final class AWSCognitoUserPoolsAuthProviderBridge: AWSCognitoUserPoolsAuthProvider {
    private let latestTokenReader: LatestTokenReader
    
    init(latestTokenReader: LatestTokenReader) {
        self.latestTokenReader = latestTokenReader
    }
    
    func getLatestAuthToken() -> String {
        return latestTokenReader.getLatestToken()
    }

}
