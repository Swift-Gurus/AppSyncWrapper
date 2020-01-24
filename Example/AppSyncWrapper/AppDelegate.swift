//
//  AppDelegate.swift
//  AppSyncWrapper
//
//  Created by AlexHmelevski on 01/14/2019.
//  Copyright (c) 2019 AlexHmelevski. All rights reserved.
//

import UIKit
import AppSyncWrapper
import AWSAppSync
import EitherResult

final class MyRefresher: TokenRefresher {
    func refreshSessionForCurrentUser(completion: @escaping (ALResult<String>) -> Void) {
        completion(.right("aToken123"))
    }
}

final class MyWriter: LatestTokenWriter {
    func saveToken(_ string: String) {
        print("Saving token: \(string)")
    }
}

final class TokenStorage: LatestTokenReader {
    var token = ""
    func getLatestToken() -> String {
        return token
    }
}

final class MyQuery: GraphQLQuery {
    static var operationString: String = "operationString"
    
    typealias Data = MySet
    
    
}

final class MySet: GraphQLSelectionSet {
    init(snapshot: Snapshot) {
        //done through autogeneration
    }
    
    static var selections: [GraphQLSelection] = []
    
    var snapshot: Snapshot = [:]
    
}

struct MyNetworkModel: GraphQLInitializable {
    init(selectionSet: MySet) {
        //assign properties from MySet to self
    }
    
    typealias Set = MySet
    
}

enum QueryType {
    case myQuery
}


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let tokenRefresher: TokenRefresher = MyRefresher()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
      
        let builder = AppSyncWrapperBuilder()
        builder.url = URL.init(string: "https://www.google.com")!
        builder.region = .APNortheast1
        builder.processQueue = .global()
        builder.tokenReader = TokenStorage()
        builder.tokenRefresher = tokenRefresher
        builder.tokenWriter = MyWriter()
        do {
            let sender = try builder.getSender()
            sender.sendQuery(MyQuery()) { (result: ALResult<MyNetworkModel>) in
                result.do(work: { (model) in
                    //process model
                })
            }
        } catch {
            fatalError()
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

