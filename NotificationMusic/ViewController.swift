//
//  ViewController.swift
//  NotificationMusic
//
//  Created by shiwei on 16/9/6.
//  Copyright © 2016年 shiwei. All rights reserved.
//

import UIKit

//选择通知声音发生改变的通知名
let TFSelectedSoundChangedNotification = "TFSelectedSoundChangedNotification"

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let tableView = UITableView(frame: UIScreen.mainScreen().bounds, style: .Grouped)
    
    var selectedIndex: Int = 0{
        didSet{
            //值改变发通知
            if selectedIndex != oldValue {
                let notification = NSNotification(name: TFSelectedSoundChangedNotification, object: nil, userInfo: ["soundIndex":selectedIndex])
                NSNotificationCenter.defaultCenter().postNotification(notification)
            }
        }
    }
    
    var soundNames: [String]{
        get{
            return TFCustomNotificationSoundProcessor.shareInstance.soundNames
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(notificationSoundsLoaded), name: TFLoadSoundNameCompletedNotification, object: nil)
    }
    
    func notificationSoundsLoaded( notification: NSNotification){
        
        tableView.reloadData()
    }

    //MARK:- tableview 委托
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return soundNames.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier("Cell")
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "Cell")
        }
        
        cell.textLabel?.text = soundNames[indexPath.row]
        if selectedIndex == indexPath.row {
            cell.accessoryType = .Checkmark
        }else{
            cell.accessoryType = .None
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedIndex = indexPath.row
        
        tableView.reloadData()
    }
}

