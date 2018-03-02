//
//  ChatPageViewController.swift
//  MyChat
//
//  Created by Yuanyuan Zhang on 27/02/2018.
//  Copyright © 2018 Ithink Team. All rights reserved.
//

import UIKit

class ChatPageTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var friend = ChatOutline()
    var me = User()
    
    var chatMessages: [ChatMessage] = []
    
    func getData() {
        // clearData()
        chatMessages = [
            ChatMessage(msgType: MsgType.Received, contentText: "你好呀"),
            ChatMessage(isDateIndicator: true),
            ChatMessage(msgType: MsgType.Sent, contentText: "今天遇见了老朋友，一时间竟叫不出名字"),
            ChatMessage(msgType: MsgType.Sent, contentText: "Mary，你还记得那年的女孩吗？"),
            ChatMessage(msgType: MsgType.Received, contentText: "好呀"),
            ChatMessage(isDateIndicator: true),
            ChatMessage(msgType: MsgType.Sent, contentText: "今天傍晚，雷雨中传来一阵丁香花的香味"),
            ChatMessage(msgType: MsgType.Received, contentText: "我想起了故乡的山楂花树篱")
        ]
        
        me = User(userId: "123", name: "palominoespresso", gender: "male", birthday: Date(), avatar: "palominoespresso", email: "12@asd.com", password: "luanMa")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        getData()
        
        // Configure the table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatMessages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if chatMessages[indexPath.row].isDateIndicator == false {
            let cellIdentifier = "ChatMessageCell"
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ChatMessageCell
            
            cell.friend = friend
            cell.me = me
            cell.message = chatMessages[indexPath.row]
            return cell
        } else {
            let cellIdentifier = "ChatDateIndicatorCell"
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ChatDateIndicatorCell

            cell.dateLabel.text = chatMessages[indexPath.row].date.description
            
            return cell
        }
    }
    
    // MARK: - UITableViewDelegate Protocol
    
   /*
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    }
    */
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}