//
//  ChatPageViewController.swift
//  MyChat
//
//  Created by Yuanyuan Zhang on 27/02/2018.
//  Copyright © 2018 Ithink Team. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import SwiftyJSON

class ChatPageTableViewController:
    UIViewController,
    UITableViewDataSource,
    UITableViewDelegate,
    UITextFieldDelegate,
    NSFetchedResultsControllerDelegate,
    IFlySpeechRecognizerDelegate
{
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var keyBaordView: UIView!
    @IBOutlet weak var textField: UITextField!
    
    var iflySpeechRecognizer: IFlySpeechRecognizer = IFlySpeechRecognizer.sharedInstance() as IFlySpeechRecognizer;
    var fetchResultController: NSFetchedResultsController<UserMO>!
    var friend = FriendMO()
    var me = UserMO()
    var chatMessages: [ChatMessageMO] = []
    var hiddenTableCellHeight: CGFloat = 0
    var keyBoardHeight: CGFloat = 0
    var translationY: CGFloat = 0
    var is_recording: Bool = false
    var voice_message: String = ""
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initIfly()
    }
    
    func initIfly() {
        IFlySpeechUtility.createUtility("appid=" + Config.IFLY_APPID);
        self.iflySpeechRecognizer.delegate = self;
        self.iflySpeechRecognizer.setParameter("iat", forKey: IFlySpeechConstant.ifly_DOMAIN())
        self.iflySpeechRecognizer.setParameter("json", forKey: IFlySpeechConstant.result_TYPE())
        
        // 录音设置
        self.iflySpeechRecognizer.setParameter("16000", forKey: IFlySpeechConstant.sample_RATE())
        self.iflySpeechRecognizer.setParameter("asr.pcm", forKey: IFlySpeechConstant.asr_AUDIO_PATH())
        self.iflySpeechRecognizer.setParameter("10000", forKey: IFlySpeechConstant.vad_BOS())
        self.iflySpeechRecognizer.setParameter("10000", forKey: IFlySpeechConstant.vad_EOS())
        
        // 设置音频流
        // self.iflySpeechRecognizer.setParameter("-1", forKey: IFlySpeechConstant.audio_SOURCE())
    }
    
    @IBAction func startRecord() {
        self.iflySpeechRecognizer.startListening()
        self.is_recording = true
        print("startRecord")
    }
    
    @IBAction func stopRecord() {
        self.iflySpeechRecognizer.stopListening()
        self.is_recording = false
        print("stopRecord")
    }
    
    func onError(_ err: IFlySpeechError!) {
        if (err.errorCode == 0) {  // 0 应该是代表服务正常...
            return
        }
        print("识别出错：\(err.errorCode)  \(err.errorDesc!)")
    }
    
    func onResults(_ results: [Any]!, isLast: Bool) {
        var keys = ""
        let dic: Dictionary<String, String> = results[0] as! Dictionary<String, String>
        for key in dic.keys {
            keys += key
        }
        print("识别成功：\(keys)")
        
        let message = keys2Message(keys: keys)
        self.voice_message += message
        if (isLast && !self.is_recording) {
            sendMessageAndWaitForResponse(self.voice_message)
            self.voice_message = ""
        }
    }
    
    func keys2Message(keys: String) -> String {
        var message = ""
        do {
            let json_data = keys.data(using: String.Encoding.utf8, allowLossyConversion: false)
            let json = try JSON(data: json_data!)
            let ws = json["ws"]
            for (_, ws_each): (String, JSON) in ws {
                let cw = ws_each["cw"]
                print(cw)
                for (_, cw_each): (String, JSON) in cw {
                    message += cw_each["w"].string!
                }
            }
        } catch {
            print(error)
        }
        return message
    }
    
    func getData() {
        // Fetch data from data store
        let fetchRequest: NSFetchRequest<UserMO> = UserMO.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]

        if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
            let context = appDelegate.persistentContainer.viewContext
            fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            fetchResultController.delegate = self

            do {
                try fetchResultController.performFetch()
                if let fetchedObjects = fetchResultController.fetchedObjects {
                    me = fetchedObjects[0]
                }
            } catch {
                print(error)
            }
        }

        chatMessages = friend.chatMessages?.array as! [ChatMessageMO]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = friend.name

        getData()
        scrollToBottom(animated: false)

        // Configure the table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = UIColor(displayP3Red: 237/255, green: 235/255, blue: 235/255, alpha: 1)

        // the keyboard view
        textField.delegate = self as UITextFieldDelegate
        textField.returnKeyType = UIReturnKeyType.send
        textField.enablesReturnKeyAutomatically  = true

         NotificationCenter.default.addObserver(self, selector: #selector(self.keyBoardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
         NotificationCenter.default.addObserver(self, selector: #selector(self.keyBoardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTouches))
        tapGestureRecognizer.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGestureRecognizer)
        
        // 关闭屏幕左侧的触碰延迟
        // self.navigationController?.interactivePopGestureRecognizer?.delaysTouchesBegan = false;
        
        if (Config.BAIDU_ACCESS_TOKEN == "") {
            Utils.initBaiduAccessToken()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatMessages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if chatMessages[indexPath.row].isDateIdentifier == false {
            let cellIdentifier = "ChatMessageCell"
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ChatMessageCell

            cell.friend = friend
            cell.me = me
            cell.lastMessage = indexPath.row > 1 ? chatMessages[indexPath.row - 1] : nil
            cell.message = chatMessages[indexPath.row]
            cell.showProfile = { () in
                self.performSegue(withIdentifier: "ShowFriendProfile", sender: self)
            }
            
            return cell
        } else {
            let cellIdentifier = "ChatDateIndicatorCell"
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ChatDateIndicatorCell

            cell.dateLabel.text = chatMessages[indexPath.row].date?.relativeTime

            return cell
        }
    }


    @objc func keyBoardWillShow(note:NSNotification) {
        let userInfo  = note.userInfo! as NSDictionary
        let keyBoardBounds = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let deltaY = keyBoardBounds.size.height
        keyBoardHeight = keyBoardBounds.size.height

        let animations:(() -> Void) = {
            self.keyBaordView.transform = CGAffineTransform(translationX: 0,y: -deltaY)

            let tableViewContentToBottom = self.tableView.bounds.size.height - self.tableView.contentSize.height
            if tableViewContentToBottom > deltaY {
                self.translationY = 0
            } else if tableViewContentToBottom <= 0 {
                self.translationY = -deltaY
            } else {
                self.translationY = tableViewContentToBottom - deltaY
            }
            self.tableView.transform = CGAffineTransform(translationX: 0,y: self.translationY)
        }

        if duration > 0 {
            let options = UIViewAnimationOptions(rawValue: UInt((userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).intValue << 16))
            UIView.animate(withDuration: duration, delay: 0, options:options, animations: animations, completion: nil)
        } else {
            animations()
        }
    }

    @objc func keyBoardWillHide(note:NSNotification) {
        let userInfo  = note.userInfo! as NSDictionary
        let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue

        let animations:(() -> Void) = {
            self.keyBaordView.transform = CGAffineTransform(translationX: 0,y: 0)
            self.tableView.transform = CGAffineTransform(translationX: 0,y: 0)
        }

        if duration > 0 {
            let options = UIViewAnimationOptions(rawValue: UInt((userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).intValue << 16))

            UIView.animate(withDuration: duration, delay: 0, options:options, animations: animations, completion: nil)
        }else{
            animations()
        }
    }

    @objc func handleTouches(sender:UITapGestureRecognizer){
        if sender.location(in: self.view).y < self.view.bounds.height - 250{
            textField.resignFirstResponder()
        }
    }

    func pushTableViewIfHidden() {
        let tableViewContentToBottom = self.tableView.bounds.size.height - self.tableView.contentSize.height
        if tableViewContentToBottom < keyBoardHeight && -keyBoardHeight < translationY {
            if tableViewContentToBottom > hiddenTableCellHeight {
                translationY -= hiddenTableCellHeight
            } else if tableViewContentToBottom > 0 {
                translationY -= tableViewContentToBottom
            } else {
                translationY = -keyBoardHeight
            }
        }
        self.tableView.transform = CGAffineTransform(translationX: 0,y: translationY)
        hiddenTableCellHeight = 0
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        saveMessageToStoreAndShow()
        textField.text = ""
        scrollToBottom(animated: true)
        return false
    }

    func appendDateIndicatorIfNeeded() {
        if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
            // save date indicator if last message is nil or 5 min ago
            if let lastmessageDate = friend.lastMessage?.date {
                if lastmessageDate.timeIntervalSinceNow < -300 {
                    let dateIndicator = ChatMessageMO(context: appDelegate.persistentContainer.viewContext)
                    dateIndicator.date = Date()
                    dateIndicator.contentText = ""
                    dateIndicator.friend = friend
                    dateIndicator.isDateIdentifier = true
                    appendMessageAndShow(message: dateIndicator)
                }
            } else {
                let dateIndicator = ChatMessageMO(context: appDelegate.persistentContainer.viewContext)
                dateIndicator.date = Date()
                dateIndicator.contentText = ""
                dateIndicator.friend = friend
                dateIndicator.isDateIdentifier = true
                appendMessageAndShow(message: dateIndicator)
            }
            appDelegate.saveContext()
        }
    }
    
    func sendMessageAndWaitForResponse(_ message_sent: String) {
        if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
            appendDateIndicatorIfNeeded()
            
            let message = ChatMessageMO(context: appDelegate.persistentContainer.viewContext)
            message.isSent = true
            message.date = Date()
            message.contentText = message_sent
            message.friend = friend
            message.isDateIdentifier = false
            
            // delete the old last message and add the new one
            let context = appDelegate.persistentContainer.viewContext
            if friend.lastMessage != nil {
                context.delete(friend.lastMessage!)
            }
            
            // 更新 lastMessage
            let lastmessage = LastMessageMO(context: appDelegate.persistentContainer.viewContext)
            lastmessage.content = textField.text!
            lastmessage.date = Date()
            friend.lastMessage = lastmessage
            
            // 保存发送的信息
            appDelegate.saveContext()
            appendMessageAndShow(message: message)
            
            let parameters: [String: Any] = [
                "friendid": friend.id!,
                "mes": message.contentText!
            ]
            let onSuccess = { (data: [String: Any]) in
                self.appendDateIndicatorIfNeeded()
                
                let result = data["result"] as! String
                let response_msg = ChatMessageMO(context: appDelegate.persistentContainer.viewContext)
                response_msg.isSent = false
                response_msg.date = Date()
                response_msg.contentText = result
                response_msg.friend = self.friend
                response_msg.isDateIdentifier = false
                
                // delete the old last message and add the new one
                let context = appDelegate.persistentContainer.viewContext
                if self.friend.lastMessage != nil {
                    context.delete(self.friend.lastMessage!)
                }
                
                // 更新 lastMessage
                let lastmessage = LastMessageMO(context: appDelegate.persistentContainer.viewContext)
                lastmessage.content = result
                lastmessage.date = Date()
                self.friend.lastMessage = lastmessage
                
                print("// self.friend.lastMessage:")
                print(self.friend.lastMessage ?? "")
                
                appDelegate.saveContext()
                self.appendMessageAndShow(message: response_msg)
            }
            let onFailure = { (data: [String: Any]) in
                // TODO: 获取服务器好友回复失败后的提示
            }
            // 从服务器获取好友的回复
            HttpUtil.post(url: "/dealMessage", parameters: parameters, onSuccess: onSuccess, onFailure: onFailure)
        }
    }
    
    func saveMessageToStoreAndShow() {
        let messgae = textField.text!
        sendMessageAndWaitForResponse(messgae)
    }

    func appendMessageAndShow(message: ChatMessageMO) {
        chatMessages.append(message)

        tableView.beginUpdates()
        tableView.insertRows(at: [IndexPath(row: chatMessages.count - 1, section: 0)], with: .automatic)
        tableView.endUpdates()

        // deal with the hidden cell by the keyboard
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageCell", for: IndexPath(row: chatMessages.count - 1, section: 0))
        hiddenTableCellHeight = cell.bounds.height
        // Add bubble bottom constraint length. it seems the bounds.height doesnot count it
        hiddenTableCellHeight += 12
        pushTableViewIfHidden()

        scrollToBottom(animated: true)
    }
    
    func scrollToBottom(animated: Bool) {
        if self.chatMessages.count > 0 {
            DispatchQueue.main.async {
                let indexPath = IndexPath(row: self.chatMessages.count-1, section: 0)
                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
            }
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowFriendManagement" {
            let destinationViewController = segue.destination as! FriendManagementTableViewController
            destinationViewController.friend = friend
        }
        
        if segue.identifier == "ShowFriendProfile" {
            let destinationViewController = segue.destination as! FriendProlileTableViewController
            destinationViewController.friend = self.friend
        }
    }

}
