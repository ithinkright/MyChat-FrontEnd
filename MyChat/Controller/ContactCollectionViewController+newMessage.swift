//
//  ContactCollectionViewController+newMessage.swift
//  MyChat
//
//  Created by Yuanyuan Zhang on 2018/4/13.
//  Copyright © 2018 Ithink Team. All rights reserved.
//

import Foundation

extension ContactCollectionViewController: SocketIODelegate {
    
    func setDelegate() {
        SocketIOUtil.delegate = self
    }
    
    func recieveMessages(messages: [String], from: String) {
        print("在列表收到了：\(messages)")
        saveUnreadMessages(messages: messages, from: from)
        // update UI
        self.viewWillAppear(false)
        print("更新了table")
        // update Tabbar
        ChatTableViewController.noticeDelegate?.updateUnreadMessages()
    }
    
    func saveUnreadMessages(messages: [String], from: String) {
        var friend = FriendMO()
        for friendTemp in Global.user.friends!.array as! [FriendMO] {
            if friendTemp.id == from {
                friend = friendTemp
                break
            }
        }
        
        if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
            for msg in messages {
                Utils.appendDateIndicatorIfNeeded(whenChattingWith: friend)
                
                let message = ChatMessageMO(context: appDelegate.persistentContainer.viewContext)
                message.isSent = false
                message.date = Date()
                message.contentText = msg
                message.friend = friend
                message.isDateIdentifier = false
                
                // delete the old last message and add the new one
                var unread = 0
                let context = appDelegate.persistentContainer.viewContext
                if let unreadCount = friend.lastMessage?.unreadCount {
                    unread = Int(unreadCount)
                }
                if friend.lastMessage != nil {
                    context.delete(friend.lastMessage!)
                }
                // update lastMessage
                let lastmessage = LastMessageMO(context: appDelegate.persistentContainer.viewContext)
                lastmessage.content = msg
                lastmessage.date = Date()
                lastmessage.unreadCount = Int32(1 + unread)
                unread = Int(lastmessage.unreadCount)
                friend.lastMessage = lastmessage
            }
            appDelegate.saveContext()
        }
    }
    
    func updateTabbar() {
        ChatTableViewController.noticeDelegate?.updateUnreadMessages()
    }
}
