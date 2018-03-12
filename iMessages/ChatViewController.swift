//
//  ChatViewController.swift
//  iMessages
//
//  Created by Sirin on 31/01/2018.
//  Copyright © 2018 Sirin. All rights reserved.
//

import UIKit
import Firebase
import JSQMessagesViewController
import Flurry_iOS_SDK

class ChatViewController: JSQMessagesViewController {
    
    var messages = [JSQMessage]()
    var outgoingMessageBubbleImage: JSQMessagesBubbleImage!
    var incomingMessageBubbleImage: JSQMessagesBubbleImage!
    private var databaseHandle: DatabaseHandle!
    var ref : DatabaseReference!
    var currentUser: UserChat?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        senderId = AuthenticationManager.sharedInstance.userId
        senderDisplayName = AuthenticationManager.sharedInstance.userName
        
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        setupMessageBubbles()
        ref = Database.database().reference()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func setupMessageBubbles() {
        let factory = JSQMessagesBubbleImageFactory()
        outgoingMessageBubbleImage = factory?.outgoingMessagesBubbleImage(
            with: UIColor(red: 0.01, green: 0.57, blue: 0.70, alpha: 1.00))
        incomingMessageBubbleImage = factory?.incomingMessagesBubbleImage(
            with: .jsq_messageBubbleLightGray())
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        if message.senderId == senderId {
            return outgoingMessageBubbleImage
        } else {
            return incomingMessageBubbleImage
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            cell.textView!.textColor = .white
        } else {
            cell.textView!.textColor = .black
        }
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        switch message.senderId {
        case senderId:
            return nil
        default:
            guard let senderDisplayName = message.senderDisplayName else {
                assertionFailure()
                return nil
            }
            return NSAttributedString(string: senderDisplayName)
            
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return 20.0
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let messageRef = ref.child("messages").childByAutoId()
        let message = [
            "text": text!,
            "senderId": senderId!,
            "senderDisplayName": senderDisplayName!
        ]
        Flurry.logEvent("MessageSent", withParameters: ["senderName": senderDisplayName])
        //MARK: Add message to database
        messageRef.setValue(message)
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        finishSendingMessage()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        messages.removeAll()
        databaseHandle = ref.child("messages").observe(.childAdded, with: { (snapshot) -> Void in
            if let value = snapshot.value as? [String:AnyObject] {
                let id = value["senderId"] as! String
                
                //MARK: Messages from friendList
                if (self.currentUser?.friendList.contains(where: {$0 == id}))! || AuthenticationManager.sharedInstance.userId == id {
                    let text = value["text"] as! String
                    let name = value["senderDisplayName"] as! String
                    self.addMessage(id: id, text: text, name: name)
                    self.finishReceivingMessage()
                }else{
                    print("User not a friend! Messages hidden")
                }
            }
        })
    }
    
    func addMessage(id: String, text: String, name: String) {
        let message = JSQMessage(senderId: id, displayName: name, text: text)
        messages.append(message!)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.ref.removeObserver(withHandle: databaseHandle)
    }
}
