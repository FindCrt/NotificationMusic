//
//  AppDelegate.swift
//  NotificationMusic
//
//  Created by shiwei on 16/9/6.
//  Copyright © 2016年 shiwei. All rights reserved.
//

import UIKit
import MediaPlayer

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var musicName: String = ""
    var soundIndex: Int = 0

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        registerNotifications()
        TFCustomNotificationSoundProcessor.shareInstance.loadSoundNames()
        
        //接收通知修改 本地通知的声音
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(selectedSoundChanged), name: TFSelectedSoundChangedNotification, object: nil)
        
        return true
    }
    
    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        TFCustomNotificationSoundProcessor.shareInstance.tryHandleMusicURL(url)
        
        return true
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        fireNotifications()
    }
    
    
    

    func registerNotifications(){
        
        let settings = UIUserNotificationSettings(forTypes: [.Alert,.Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)

    }
    
    func fireNotifications(){
        
        let notification = UILocalNotification()
        notification.alertTitle = "测试声音推送"
        notification.soundName = TFCustomNotificationSoundProcessor.shareInstance.soundName(atIndex: soundIndex)
        
        print("soundname:",notification.soundName!)
        
        notification.fireDate = NSDate()
        
        UIApplication.sharedApplication().presentLocalNotificationNow(notification)
    }

    
    func selectedSoundChanged(notification: NSNotification){
        if let index = notification.userInfo!["soundIndex"] as? Int {
            soundIndex = index
        }
    }
}







