//
//  Repo.swift
//  GrokGitHubAPI
//
//  Created by Christina Moulton on 2015-07-17.
//  Copyright (c) 2015 Teak Mobile Inc. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class Repo {
  var id: String?
  var name: String?
  var description: String?
  var ownerLogin: String?
  var url: String?
  
  required init(json: JSON) {
    self.description = json["description"].string
    self.id = json["id"].string
    self.name = json["name"].string
    self.ownerLogin = json["owner"]["login"].string
    self.url = json["url"].string
  }
  
  class func getMyRepos(completionHandler: (Array<Repo>?, NSError?) -> Void)
  {
    let path = "https://api.github.com/user/repos"
    GitHubAPIManager.sharedInstance.alamofireManager().request(.GET, path)
      .validate()
      .responseRepoArray { (request, response, repos, error) in
        if let anError = error
        {
          println(anError)
          // TODO: parse out errors more specifically
          // for now, let's just wipe out the oauth token so they'll get forced to redo it
          //GitHubAPIManager.sharedInstance.OAuthToken = nil
          completionHandler(nil, error)
          return
        }
        println(response)
        println(request)
        completionHandler(repos, nil)
    }
  }
}

extension Alamofire.Request {
  class func repoArrayResponseSerializer() -> Serializer {
    return { request, response, data in
      if data == nil {
        return (nil, nil)
      }
      
      var jsonError: NSError?
      let jsonData:AnyObject? = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: &jsonError)
      if jsonData == nil || jsonError != nil
      {
        return (nil, jsonError)
      }
      let json = JSON(jsonData!)
      if json.error != nil || json == nil
      {
        return (nil, json.error)
      }
      
      var repos:Array = Array<Repo>()
      for (key, jsonRepo) in json
      {
        println(key)
        println(jsonRepo)
        let repo = Repo(json: jsonRepo)
        repos.append(repo)
      }
      return (repos, nil)
    }
  }
  
  func responseRepoArray(completionHandler: (NSURLRequest, NSHTTPURLResponse?, Array<Repo>?, NSError?) -> Void) -> Self {
    return response(serializer: Request.repoArrayResponseSerializer(), completionHandler: { (request, response, repos, error) in
      completionHandler(request, response, repos as? Array<Repo>, error)
    })
  }
}
