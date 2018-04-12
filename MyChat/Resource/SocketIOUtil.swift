//
//  SocketIO.swift
//  MyChat
//
//  Created by Raincome on 07/03/2018.
//  Copyright © 2018 Ithink Team. All rights reserved.
//

import SocketIO

class SocketIOUtil {
    static let BASE_URL: String = "http://\(Config.SERVER_IP):3000"
    static var manager: SocketManager = SocketManager(socketURL: URL(string: BASE_URL)!, config: [.log(false), .compress])
    static var socket: SocketIOClient = manager.socket(forNamespace: "/")
    static weak var delegate: SocketIODelegate?
    
    static func initialize() {
        socket.on("connect", callback: { (data, ack) in
            print(data)
            print(ack)
            socket.emit("start", ["userid": Global.user.id!])
        })
        
        socket.on("error", callback: { (data, ack) in
            print(data)
            print(ack)
        })
        
        socket.on("message", callback: { (data, ack) in
            let temp = data[0] as! [String: Any]
            let message = temp["message"] as! String
            delegate!.recieveMessages(messages: ["test"], from: "test")
        })
        
        socket.on("messages", callback: { (data, ack) in
            let temp = data[0] as! [String: Any]
            let messages = temp["messages"] as! [String]
            delegate!.recieveMessages(messages: ["test"], from: "test")
        })
        
        socket.connect()
    }
    
    static func getUrlByAttributename(attributename: String) -> String {
        var url: String = "http://\(Config.SERVER_IP)"
        switch (attributename) {
        case "email":
            url += ":3001"
            break
        case "compute":
            url += ":3002"
            break
        case "translate":
            url += ":3003"
            break
        case "Weather":
            url += ":3004"
            break
        case "Mary":
            url += ":3005"
            break
        case "secretary":
            url += ":3006"
            break
        case "SanXing":
            url += ":3007"
            break
        default:
            url += ":3000"
        }
        print("**********\(url)")
        return url
    }
}
