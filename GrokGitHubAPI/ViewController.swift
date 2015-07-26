//
//  ViewController.swift
//  GrokGitHubAPI
//
//  Created by Christina Moulton on 2015-07-17.
//  Copyright (c) 2015 Teak Mobile Inc. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  @IBOutlet weak var tableView: UITableView!
  var repos: Array<Repo>?
  
  // MARK: - Getting Data
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    let defaults = NSUserDefaults.standardUserDefaults()
    if (!defaults.boolForKey("loadingOauthToken"))
    {
      loadInitialData()
    }
  }
  
  func loadInitialData()
  {
    if (!GitHubAPIManager.sharedInstance.hasOAuthToken() || true)
    {
      GitHubAPIManager.sharedInstance.oauthTokenCompletionHandler = {
        (error) -> Void in
        println("handlin stuff")
        if let receivedError = error
        {
          println(error)
          // TODO: handle error
          // TODO: issue: don't get unauthorized if we try this query
          GitHubAPIManager.sharedInstance.startOAuth2Login()
        }
        else
        {
          self.fetchMyRepos()
        }
      }
      GitHubAPIManager.sharedInstance.startOAuth2Login()
    }
    else
    {
      fetchMyRepos()
    }
  }
  
  func fetchMyRepos()
  {
    println(GitHubAPIManager.sharedInstance.alamofireManager().session.configuration.HTTPAdditionalHeaders)
    Repo.getMyRepos( { (fetchedRepos, error) in
      println("got repos:")
      if let receivedError = error
      {
        println(error)
        GitHubAPIManager.sharedInstance.OAuthToken = nil
        // TODO: display error
      }
      else
      {
        self.repos = fetchedRepos
        println(self.repos)
        
        self.tableView.reloadData()
      }
    })
  }
  
  // MARK: - Table View
  
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.repos?.count ?? 0
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
    
    let repo = repos?[indexPath.row]
    cell.textLabel?.text = repo?.description
    if let owner = repo?.ownerLogin
    {
      cell.detailTextLabel?.text = "By " + owner
    }
    else
    {
      cell.detailTextLabel?.text = nil
    }
    return cell
  }
}
