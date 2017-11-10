//
//  MenuController.swift
//  Found
//
//  Created by Sergio Hernandez on 27/09/2017.
//  Copyright © 2017 Sergio Hernandez. All rights reserved.
//

import UIKit
import Firebase

class MenuController: UITabBarController {
    
    var user: User!
    
    var feedPosts = [Post]()
    var userPosts = [Post]()
    
    typealias FinishedDownload = () -> ()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        checkIfUserIsLoggedIn()
    }
    
    func addControllers() {
        
        let feed = PostListController()
        let feedNavigationController = UINavigationController(rootViewController: feed)
        feedNavigationController.navigationBar.isTranslucent = true
        feed.title = "Feed"
        feed.tabBarItem = UITabBarItem(title: "Feed", image: nil, tag: 0)
        feed.tabBarItem.titlePositionAdjustment = UIOffsetMake(0.0, -10.0)
        
        let messages = MessagesController()
        let messagesNavigationController = UINavigationController(rootViewController: messages)
        messagesNavigationController.navigationBar.isTranslucent = true
        messages.fetchUserAndSetupNavBarTitle()
        messages.title = "Messages"
        messages.tabBarItem = UITabBarItem(title: "Messages", image: nil, tag: 1)
        
        let newPost = NewPostController()
        newPost.user = user
        newPost.title = "+"
        newPost.tabBarItem = UITabBarItem(title: "+", image: nil, tag: 2)
        
        let userPosts = PostListController()
        let userPostsNavigationController = UINavigationController(rootViewController: userPosts)
        userPostsNavigationController.navigationBar.isTranslucent = true
        userPosts.title = "Your Posts"
        userPosts.tabBarItem = UITabBarItem(title: "Your Posts", image: nil, tag: 3)
        
        let profile = ProfileController()
        let profileNavigationController = UINavigationController(rootViewController: profile)
        profileNavigationController.navigationBar.isTranslucent = true
        profile.user = user
        profile.mainProfile = true
        profile.title = "Profile"
        profile.tabBarItem = UITabBarItem(title: "Profile", image: nil, tag: 4)
            
        self.retrievePosts { () -> () in
            
            self.downloadPictures { () -> () in
                
                feed.posts = self.feedPosts
                
                userPosts.posts = self.userPosts
                
                self.viewControllers = [ feedNavigationController, messagesNavigationController, newPost, userPostsNavigationController, profileNavigationController ]
            }
        }
    }
    
    // This function prevents the app from crashing in low internet speeds if the pictures are retrieved faster than they are downloaded
    func downloadPictures(completed: @escaping FinishedDownload) {
        
        for post in userPosts {
            let url = URL(string: post.userPictureURL)
            let data = try? Data(contentsOf: url!)
            post.userPicture = UIImage(data: data!)
        }
        for post in feedPosts {
            let url = URL(string: post.userPictureURL)
            let data = try? Data(contentsOf: url!)
            post.userPicture = UIImage(data: data!)
        }
        completed()
    }
    
    // Posts will need to be retrieved using pagination when the scope of the app scalates. If not, the time needed to download all the posts will be too large
    func retrievePosts(completed: @escaping FinishedDownload) {
        
        let ref = FIRDatabase.database().reference().child("posts")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            for post in snapshot.children.allObjects as! [FIRDataSnapshot] {
                if post.childSnapshot(forPath: "userID").value as? String != self.user.id {
                    self.feedPosts.append(Post(post))
                } else {
                    self.userPosts.append(Post(post))
                }
            }
            print("\nFeed posts were successfully downloaded. \(self.feedPosts.count) posts were found.\n")
            completed()
        })
    }
    
//    func getNumberOfPosts(completed: @escaping FinishedDownload) {
//        // Get the number of total posts and then get the number of current user's posts and subtract it to the first one, because we do not want to show the user's posts in the feed
//
//        let userID = FIRAuth.auth()?.currentUser?.uid
//        var n: Int!
//
//        let ref1 = FIRDatabase.database().reference(fromURL: "https://found-87b59.firebaseio.com/").child("posts")
//        let ref2 = FIRDatabase.database().reference(fromURL: "https://found-87b59.firebaseio.com/").child("users").child(userID!).child("posts")
//
//        ref1.observe(.value, with: { (snapshot: FIRDataSnapshot!) in
//            n = Int(snapshot.childrenCount)
//            ref2.observe(.value, with: { (snapshot: FIRDataSnapshot!) in
//                self.numberOfUserPosts = Int(snapshot.childrenCount)
//                self.numberOfFeedPosts = n - self.numberOfUserPosts
//                print("\nI finished calculating number of feed posts. \(self.numberOfFeedPosts!) posts were found\n")
//                completed()
//            })
//        })
//
//    }
    
    func checkIfUserIsLoggedIn() {
        if FIRAuth.auth()?.currentUser?.uid == nil {
            print("\nUser is not logged in\n")
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        } else {
            print("\nUser is successfully logged in\n")
            user = User(id: (FIRAuth.auth()?.currentUser?.uid)!, completion: { () -> () in
                self.addControllers()
            })
        }
    }
    
    @objc func handleLogout() {
        // Sign Out
        do {
            try FIRAuth.auth()?.signOut()
        } catch let logoutError {
            print(logoutError)
        }
        
        let loginController = LoginController()
        present(loginController, animated: true, completion: nil)
    }
}