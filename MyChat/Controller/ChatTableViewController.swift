//
//  ChatTableViewController.swift
//  MyChat
//
//  Created by Yuanyuan Zhang on 27/02/2018.
//  Copyright © 2018 Ithink Team. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

class ChatTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UIPopoverPresentationControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {

    var lastMessages: [LastMessageMO] = []
    var fetchResultController: NSFetchedResultsController<LastMessageMO>!
    var filteredLastMessages: [LastMessageMO] = []
    
    @IBOutlet var emptyChatTableView: UIView!
    
    var searchController = UISearchController(searchResultsController: nil)
    
    static weak var noticeDelegate: TabbarDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.isTranslucent = false
        
        setUpSearchBar()
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        
        tableView.backgroundView = emptyChatTableView
        tableView.backgroundView?.isHidden = true
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        
        SocketIOUtil.initialize()
        if Config.DEVICE_TOKEN != nil { uploadDeviceToken() }
        Utils.fetchAllNewMessages()
    }
    
    private func uploadDeviceToken() {
        let url = "/users/device_token"
        let parameters: [String: Any] = [
            "userid": Global.user.id!,
            "device_token": Config.DEVICE_TOKEN
        ]
        let doNothing = { (data: [String: Any]) in }
        HttpUtil.post(url: url, parameters: parameters, onSuccess: doNothing, onFailure: doNothing)
    }
    
    private func setUpSearchBar() {
        searchController.searchBar.setValue("取消", forKey: "cancelButtonText")
        searchController.searchBar.placeholder = "搜索"
        searchController.searchBar.barTintColor = .white
        searchController.searchBar.tintColor = UIColor(hex: "#777777")
        searchController.searchBar.backgroundImage = UIImage()
        searchController.searchBar.backgroundColor = .white
        let searchField = searchController.searchBar.value(forKey: "searchField") as? UITextField
        searchField?.backgroundColor = UIColor(hex: "#f1f1f1")
        searchField?.layer.cornerRadius = (searchField?.layer.bounds.height)! / 2
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchTxt = searchController.searchBar.text {
            if searchTxt == "" {
                filteredLastMessages = lastMessages
            } else {
                filteredLastMessages = lastMessages.filter({ (($0.friend?.name?.lowercased().contains(searchTxt.lowercased()))! || $0.content!.lowercased().contains(searchTxt.lowercased()) )})
            }
        }
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);

        getData()
        filteredLastMessages = lastMessages
        tableView.reloadData()
        
        hideSearchbarIfTableEmpty()
        
        setDelegate()
        setUnreadMessagesDelegate()
        // 更新tabbar
        updateTabbar()
    }
    
    func hideSearchbarIfTableEmpty() {
        // 没有消息的时候，没有搜索栏
        tableView.tableHeaderView?.isHidden = lastMessages.count == 0 ? true : false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if lastMessages.count > 0 {
            tableView.backgroundView?.isHidden = true
        } else {
            tableView.backgroundView?.isHidden = false
            tableView.separatorStyle = .none
        }
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchController.searchBar.text == "" ? lastMessages.count : filteredLastMessages.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cellIdentifier = "ChatTableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ChatTableViewCell
        
        let theLastMessages = searchController.searchBar.text == "" ? lastMessages : filteredLastMessages
        let friend = theLastMessages[indexPath.row].friend
        cell.nameLabel.text = friend?.name
        cell.chatsliceLabel.text = theLastMessages[indexPath.row].content
        cell.badgeValue = Int(theLastMessages[indexPath.row].unreadCount)
        cell.dateLabel.text = theLastMessages[indexPath.row].date?.relativeTime
        cell.stickOnTop = theLastMessages[indexPath.row].stickOnTop
        if let avatar = friend?.avatar {
            cell.thumbnailImageView.image = UIImage(data: avatar as Data)
        }

        return cell
    }

    // MARK: - UITableViewDelegate Protocol

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let isSticky = self.lastMessages[indexPath.row].stickOnTop
        // stick or unstick
        let stickAction = UIContextualAction(style: .normal, title: isSticky ? "取消置顶" : "置顶") { (action, sourceView, completionHandler) in
            // stick the lastmessage
            if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
                self.lastMessages[indexPath.row].stickOnTop = isSticky ? false : true
                self.lastMessages[indexPath.row].sticktime = Date()
                appDelegate.saveContext()
            }
            let lastmessage = self.lastMessages[indexPath.row]
            self.lastMessages.remove(at: indexPath.row)
            var targetRow = 0
            if !isSticky {
                targetRow = 0
            } else {
                targetRow = self.lastMessages.count
                for i in 0..<self.lastMessages.count {
                    if !self.lastMessages[i].stickOnTop && self.lastMessages[i].date! < lastmessage.date! {
                        targetRow = i
                        break
                    }
                }
            }
            self.lastMessages.insert(lastmessage, at: targetRow)
            self.tableView.moveRow(at: indexPath, to: IndexPath(row: targetRow, section: 0))
            self.tableView.reloadRows(at: [IndexPath(row:targetRow, section:0)], with: .fade)
            
            // Call completion handler with true to indicate
            completionHandler(true)
        }
        
        let deleteAction = UIContextualAction(style: .destructive, title: "删除") { (action, sourceView, completionHandler) in
            
            // delete the lastmessage
            if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
                let context = appDelegate.persistentContainer.viewContext
                context.delete(self.lastMessages[indexPath.row])
                appDelegate.saveContext()
            }
            // Delete the row from the data source
            self.lastMessages.remove(at: indexPath.row)

            self.tableView.deleteRows(at: [indexPath], with: .fade)

            self.hideSearchbarIfTableEmpty()
            
            // Call completion handler with true to indicate
            completionHandler(true)
        }

        // Customize the action buttons
        stickAction.backgroundColor = UIColor(hex: "#0D98FF")
        deleteAction.backgroundColor = UIColor(red: 231.0/255.0, green: 76.0/255.0, blue: 60.0/255.0, alpha: 1.0)

        let swipeConfiguration = UISwipeActionsConfiguration(actions: [deleteAction, stickAction])

        return swipeConfiguration
    }

    func getData() {
        lastMessages = []
        var stickLastMessages: [LastMessageMO] = []
        var normalLastMessages: [LastMessageMO] = []
        for friend in Global.user.friends!.array as! [FriendMO] {
            if let lastmessage = friend.lastMessage {
                if lastmessage.stickOnTop {
                    stickLastMessages.append(lastmessage)
                } else {
                    normalLastMessages.append(lastmessage)
                }
            }
        }
        stickLastMessages = stickLastMessages.sorted(by: {$0.sticktime! > $1.sticktime!})
        normalLastMessages = normalLastMessages.sorted(by: {$0.date! > $1.date!})
        lastMessages = stickLastMessages + normalLastMessages
    }
    
    // MARK: - SearchBar
    
    //    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    //        filtered = lastMessages.filter { (lastMessage) -> Bool in
    //            guard let text = searchBar.text else { return false }
    //            return lastMessage.content!.contains(text)
    //        }
    //    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showChatPage" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let destinationViewController = segue.destination as! ChatPageTableViewController
                destinationViewController.friend = lastMessages[indexPath.row].friend!
            }
        }
        
        if segue.identifier == "showPopover" {
            let popoverViewController = segue.destination
            popoverViewController.popoverPresentationController?.delegate = self
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    @IBAction func AddFriendUnwindSegue(_ sender: UIStoryboardSegue) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.performSegue(withIdentifier: "showAddFriend", sender: self)
        }
    }
    
    @IBAction func NewFriendUnwindSegue(_ sender: UIStoryboardSegue) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.performSegue(withIdentifier: "showNewFriend", sender: self)
        }
    }
    
    @IBAction func returnToMyChatPageUnwindSegue(_ sender: UIStoryboardSegue) {
    }

}
