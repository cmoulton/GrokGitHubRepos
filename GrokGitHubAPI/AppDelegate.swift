//
//  AppDelegate.swift
//  GrokGitHubAPI
//
//  Created by Christina Moulton on 2015-07-17.
//  Copyright (c) 2015 Teak Mobile Inc. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Override point for customization after application launch.
    return true
  }

  func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
    GitHubAPIManager.sharedInstance.processOauthStep1Response(url)
    return true
  }
}

