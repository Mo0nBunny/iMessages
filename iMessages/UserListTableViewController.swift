//
//  UserListTableViewController.swift
//  iMessages
//
//  Created by Sirin on 29/01/2018.
//  Copyright © 2018 Sirin. All rights reserved.
//

import UIKit
import Firebase
import GradientLoadingBar
import Flurry_iOS_SDK

class UserListTableViewController: UITableViewController {
    
    let gradientLoadingBar = GradientLoadingBar()
    var refUsers: DatabaseReference!
    let myUser = Auth.auth().currentUser // Firebase user
    var currentUser = UserChat()
    
    var usersList = [UserChat]()
    
    @IBAction func logoutButton(_ sender: Any) {
        gradientLoadingBar.show()
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            AuthenticationManager.sharedInstance.loggedIn = false
            let presentingViewController = self.presentingViewController
            self.dismiss(animated: false, completion: {
                presentingViewController!.dismiss(animated: true, completion: {})
            })
        } catch let signOutError as NSError {
            print ("Error signing out: \(signOutError)")
        }
        Flurry.endTimedEvent("TimeInApp", withParameters: nil)
        gradientLoadingBar.hide()
    }
    
    @IBOutlet var userTableView: UITableView!
    
    @IBAction func addToFriendTapped(_ sender: UIButton) {
        print("button tapped")
        let cell: UserTableViewCell = sender.superview?.superview as! UserTableViewCell
        let table: UITableView = cell.superview as! UITableView
        let buttonIndexPath = table.indexPath(for: cell)
        let user = usersList[(buttonIndexPath?.row)!]
        
        if cell.addToFriend.imageView?.image == #imageLiteral(resourceName: "check- empty") {
            currentUser.friendList.append(user.fid!)
        } else {
            for friendsID in currentUser.friendList {
                if friendsID == user.fid {
                    currentUser.friendList.remove(at: currentUser.friendList.index(of: friendsID)!)
                }
            }
        }
        self.refUsers.child((myUser?.uid)!).child("friendList").setValue(currentUser.friendList)
        getUsers()
    }
    
    @IBAction func chatButton(_ sender: Any) {
        performSegue(withIdentifier: "ChatSegue", sender: usersList)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getUsers()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersList.count
    }
 
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "\(formattedDate())"
    }
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionBackground = UIView()
        let headerText = UILabel()
        headerText.textColor = .white
        headerText.text = self.tableView(self.tableView, titleForHeaderInSection: section)
        headerText.sizeToFit()
        headerText.textAlignment = NSTextAlignment.natural
        sectionBackground.backgroundColor = #colorLiteral(red: 0.1594623327, green: 0.5850729346, blue: 0.7701333165, alpha: 1)
        sectionBackground.addSubview(headerText)
        
        return sectionBackground
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! UserTableViewCell
        cell.nameLabel.text = usersList[indexPath.row].name
        cell.emailLabel.text = usersList[indexPath.row].email
        
        let userFriendID = usersList[indexPath.row].fid
        if currentUser.friendList.contains(userFriendID!) {
            cell.addToFriend.setImage(#imageLiteral(resourceName: "check- done"), for: .normal)
        } else {
            cell.addToFriend.setImage(#imageLiteral(resourceName: "check- empty"), for: .normal)
        }
        cell.backgroundColor = UIColor.clear
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ChatSegue" {
            let chatVC = segue.destination as! ChatViewController
            chatVC.currentUser = currentUser
        }
    }
    
    func getUsers() {
        print("get users start")
        refUsers = Database.database().reference().child("users")
        refUsers.observe(DataEventType.value) { (snapshot) in
            if snapshot.childrenCount > 0 {
                self.usersList.removeAll()
                
                for user in snapshot.children.allObjects as! [DataSnapshot] {
                    let cUser = UserChat()
                    let userObject = user.value as? [String: AnyObject]
                    
                    let userName = userObject?["name"]
                    let userEmail = userObject?["email"]
                    
                    cUser.fid = user.key
                    cUser.name = (userName as! String?)!
                    cUser.email = (userEmail as! String?)!
                    
                    //Getting friendList
                    if(!(cUser.fid?.isEmpty)!) {
                        self.refUsers.child(cUser.fid!).child("friendList").observeSingleEvent(of: .value, with: { snapshot in
                            let enumerator = snapshot.children
                            while let friend = enumerator.nextObject() as? DataSnapshot {
                                cUser.friendList.append(friend.value as! String)
                            }
                            if self.myUser?.email == cUser.email {
                                self.currentUser = cUser
                            }
                        })
                    }
                    
                    if self.myUser?.email != cUser.email {
                        self.usersList.append(cUser)
                    }
                }
                self.userTableView.reloadData()
            }
        }
        print("get users done")
    }
    
    func formattedDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: Date())
    }
}
