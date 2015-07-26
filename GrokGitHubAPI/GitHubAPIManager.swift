//
//  GitHubAPIManager.swift NEW!!!
//  GrokGitHubAPI
//
//  Created by Christina Moulton on 2015-07-19.
//  Copyright (c) 2015 Teak Mobile Inc. All rights reserved.
//

import Foundation
import Alamofire
import Locksmith

class GitHubAPIManager
{
  static let sharedInstance = GitHubAPIManager()
  
  var clientID: String = "123456"
  var clientSecret: String = "0b0b0b0b0b0"
  
  var OAuthToken: String?
    {
    set
    {
      if let valueToSave = newValue
      {
        let error = Locksmith.saveData(["token": valueToSave], forUserAccount: "github")
        if let errorReceived = error
        {
          Locksmith.deleteDataForUserAccount("github")
        }
        addSessionHeader("Authorization", value: "token \(valueToSave)")
      }
      else
      {
        Locksmith.deleteDataForUserAccount("github")
        removeSessionHeaderIfExists("Authorization")
      }
    }
    get
    {
      // try to load from keychain
      let (dictionary, error) = Locksmith.loadDataForUserAccount("github")
      if let token =  dictionary?["token"] as? String {
        return token
      }
      removeSessionHeaderIfExists("Authorization")
      return nil
    }
  }
  
  func alamofireManager() -> Manager
  {
    let manager = Alamofire.Manager.sharedInstance
    addSessionHeader("Accept", value: "application/vnd.github.v3+json")
    return manager
  }
  
  func addSessionHeader(key: String, value: String)
  {
    let manager = Alamofire.Manager.sharedInstance
    println(manager.session.configuration.HTTPAdditionalHeaders)
    if var sessionHeaders = manager.session.configuration.HTTPAdditionalHeaders as? Dictionary<String, String>
    {
      sessionHeaders[key] = value
      manager.session.configuration.HTTPAdditionalHeaders = sessionHeaders
    }
    else
    {
      manager.session.configuration.HTTPAdditionalHeaders = [
        key: value
      ]
    }
    println(manager.session.configuration.HTTPAdditionalHeaders)
  }
  
  func removeSessionHeaderIfExists(key: String)
  {
    let manager = Alamofire.Manager.sharedInstance
    if var sessionHeaders = manager.session.configuration.HTTPAdditionalHeaders as? Dictionary<String, String>
    {
      sessionHeaders.removeValueForKey(key)
      manager.session.configuration.HTTPAdditionalHeaders = sessionHeaders
    }
  }
  
  // handlers for the oauth process
  // stored as vars since sometimes it requires a round trip to safari which
  // makes it hard to just keep a reference to it
  var oauthTokenCompletionHandler:(NSError? -> Void)?
  
  func hasOAuthToken() -> Bool
  {
    if let token = self.OAuthToken
    {
      return !token.isEmpty
    }
    return false
  }
  
  // MARK: - OAuth flow
  func startOAuth2Login()
  {
    //removeSessionHeaderIfExists("Authorization")
    let authPath:String = "https://github.com/login/oauth/authorize?client_id=\(clientID)&scope=repo&state=TEST_STATE"
    
    if let authURL:NSURL = NSURL(string: authPath)
    {
      let defaults = NSUserDefaults.standardUserDefaults()
      defaults.setBool(true, forKey: "loadingOauthToken")
      
      UIApplication.sharedApplication().openURL(authURL)
    }
  }
  
  func processOauthStep1Response(url: NSURL)
  {
    println(url)
    let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)
    var code:String?
    if let queryItems = components?.queryItems
    {
      for queryItem in queryItems
      {
        if (queryItem.name.lowercaseString == "code")
        {
          code = queryItem.value
          break
        }
      }
    }
    if let receivedCode = code {
      let getTokenPath:String = "https://github.com/login/oauth/access_token"
      let tokenParams = ["client_id": clientID, "client_secret": clientSecret, "code": receivedCode]
      // don't use sharedManager because we don't want to pass an old, invalid oauthToken if we have one
      Alamofire.request(.POST, getTokenPath, parameters: tokenParams)
        .responseString { (request, response, results, error) in
          if let anError = error
          {
            println(anError)
            if let completionHandler = self.oauthTokenCompletionHandler
            {
              let noAuthError = NSError(domain: AlamofireErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not obtain an Oauth code", NSLocalizedRecoverySuggestionErrorKey: "Please retry your request"])
              let defaults = NSUserDefaults.standardUserDefaults()
              defaults.setBool(false, forKey: "loadingOauthToken")
              completionHandler(noAuthError)
            }
            return
          }
          println(results)
          if let receivedResults = results
          {
            let resultParams:Array<String> = split(receivedResults) {$0 == "&"}
            for param in resultParams
            {
              let resultsSplit = split(param) { $0 == "=" }
              if (resultsSplit.count == 2)
              {
                let key = resultsSplit[0].lowercaseString // access_token, scope, token_type
                let value = resultsSplit[1]
                switch key {
                case "access_token":
                  self.OAuthToken = value
                case "scope":
                  // TODO: verify scope
                  println("SET SCOPE")
                case "token_type":
                  // TODO: verify is bearer
                  println("CHECK IF BEARER")
                default:
                  println("got more than I expected from the oauth token exchange")
                }
              }
            }
          }
          
          let defaults = NSUserDefaults.standardUserDefaults()
          defaults.setBool(false, forKey: "loadingOauthToken")
          
          if self.hasOAuthToken()
          {
            if let completionHandler = self.oauthTokenCompletionHandler
            {
              completionHandler(nil)
            }
          }
          else
          {
            //self.removeSessionHeaderIfExists("Authorization")
            if let completionHandler = self.oauthTokenCompletionHandler
            {
              // TODO: create error "no token" with some way to handle it
              let noAuthError = NSError(domain: AlamofireErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not obtain an Oauth token", NSLocalizedRecoverySuggestionErrorKey: "Please retry your request"])
              completionHandler(noAuthError)
            }
          }
      }
    }
    else
    {
      // no code in URL that we launched with
      let defaults = NSUserDefaults.standardUserDefaults()
      defaults.setBool(false, forKey: "loadingOauthToken")
    }
  }
  
}
