//
//  DiscoveryTableViewController.swift
//  MyChat
//
//  Created by Yuanyuan Zhang on 07/03/2018.
//  Copyright © 2018 Ithink Team. All rights reserved.
//

import UIKit

class DiscoveryTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        // tableView.backgroundColor = UIColor(displayP3Red: 237/255, green: 235/255, blue: 235/255, alpha: 1)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 4
    }

}
