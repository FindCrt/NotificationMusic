//
//  TFCustomNotificationSoundProcessor.swift
//  NotificationMusic
//
//  Created by shiwei on 16/9/7.
//  Copyright © 2016年 shiwei. All rights reserved.
//

import UIKit
import MediaPlayer

///存在沙盒的/Library/Sounds目录下才可以作为本地通知的声音
let TFNotificationSoundDir = NSSearchPathForDirectoriesInDomains(.LibraryDirectory, .UserDomainMask, true).first! + "/Sounds"

/// 加载完已有声音和ipod音乐后，发出通知，因为这个操作为异步
let TFLoadSoundNameCompletedNotification = "TFLoadSoundNameCompletedNotification"

class TFCustomNotificationSoundProcessor: NSObject {
    
    static let shareInstance = TFCustomNotificationSoundProcessor()
    
    /// 所有可用的通知声音名，都不带扩展名，使用`func soundName(atIndex index: Int) -> String`方法获取实际通知声音名
    var soundNames = [String]()
    
    private override init() {
        super.init()
    }
    
    /**
     加载已有的通知声音，在APP启动时即可调用
     */
    func loadSoundNames(){
        if !NSFileManager.defaultManager().fileExistsAtPath(TFNotificationSoundDir) {
            
            _ = try? NSFileManager.defaultManager().createDirectoryAtURL(NSURL(fileURLWithPath: TFNotificationSoundDir), withIntermediateDirectories: true, attributes: nil)
        }
        
        if let contents = try? NSFileManager.defaultManager().contentsOfDirectoryAtPath(TFNotificationSoundDir){
            
            for path in contents {
                
                //取出文件名
                if let lastComp = path.componentsSeparatedByString("/").last{
                    var nameParts = lastComp.componentsSeparatedByString(".")
                    nameParts.removeLast()
                    let name = nameParts.joinWithSeparator(".")
                    soundNames.append(name)
                }
            }
        }
        
        copyAviableIpodMusics()
    }
    
    /**
     从ipod音乐库导入可用的音乐。直接在Apple music里下载的音乐是获取不到资源地址的，无法导入，只有自己通过itunes导入且下载到本地的音乐才可以,留在iCloud上的也不行
     */
    func copyAviableIpodMusics(){
        let mediaquery = MPMediaQuery()
        MPMusicPlayerControllerNowPlayingItemDidChangeNotification
        if let musics = mediaquery.items {
            for music in musics {
                let title = music.valueForProperty(MPMediaItemPropertyTitle) as? String
                
                if let url = music.assetURL {
                    saveNotificationSound(url,name: title,isLast: music == musics.last)
                }
            }
        }
    }
    
    /**
     将指定位置音频存入到通知声音路径(/Library/Sounds)下
     默认剪切前面30秒，如果有需求让用户自定义区间，可以调整参数值
     
     - parameter fromURL: 源音频地址
     - parameter name:    音频名，如果传空，则从音频内部读取
     */
    func saveNotificationSound(fromURL: NSURL, name: String? = nil, isLast: Bool = false ,startTime: Int64 = 0, endTime: Int64 = 30){
        
        var soundName: String! = name
        if soundName == nil {
            soundName = analysisMusicFormats(withFilePath: fromURL.path!).title
        }
        if soundName == nil {
            soundName = "\(Int(NSDate().timeIntervalSince1970))"
        }
        
        if soundNames.contains(soundName) {
            return
        }
        
        let savePath = TFNotificationSoundDir + "/" + soundName! + ".m4a"
        TFAudioCutoffer.shareInstance.cutoffAudio(fromURL, startTime: 30, endTime: 60, saveDirect: NSURL(fileURLWithPath: savePath),handler: { (succeed:Bool) in
            
            if succeed {
                print("convert succeed")
                
                self.soundNames.append(soundName)
                
            }else{
                print("convert error")
            }
            
            if isLast{
                dispatch_async(dispatch_get_main_queue(), { 
                    NSNotificationCenter.defaultCenter().postNotificationName(TFLoadSoundNameCompletedNotification, object: nil)
                })
                
            }
        })
        
    }
    
    /**
     使用airDrop或者其他APP文件共享把音乐文件传入当前APP，会打开当前APP,
     在具有handleOpenURL的UIApplicationDelegate方法里调用这个方法，检测是否为音乐文件，是则处理
     
     - parameter url: 启动APP的URL
     
     - returns: 是否为音乐类型
     */
    func tryHandleMusicURL(url: NSURL) -> Bool{
        
        //暂时只处理mp3格式
        if url.absoluteString.hasSuffix(".mp3") {
            self.saveNotificationSound(url)
            return true
        }
        
        return false
    }
    
    func deleteSound(withName soundName: String){
        if soundNames.contains(soundName) {
            let path = TFNotificationSoundDir + "/\(soundName).m4a"
            
            if NSFileManager.defaultManager().fileExistsAtPath(path) {
                var succeed: Bool = true
                do{
                    try NSFileManager.defaultManager().removeItemAtPath(path)
                }catch{
                    succeed = false
                }
                
                if succeed {
                    soundNames.removeObject(soundName)
                }
                
            }
        }
    }
    
    func soundName(atIndex index: Int) -> String{
        if index < soundNames.count {
            return soundNames[index] + ".m4a"
        }
        return ""
    }
}

//MARK:- 分析音频文件格式信息

struct TFMusicInfos {
    var title: String?
    var artist: String?
    var image: UIImage?
    var fileSize: Int? //单位字节
    var albumName: String?
}

/**
 分析音乐的信息
 
 - parameter path: 音乐的存储地址
 
 - returns: 返回结构体，包含音乐的多个信息
 */
func analysisMusicFormats(withFilePath path: String) -> TFMusicInfos{
    var musicInfo = TFMusicInfos()
    let asset = AVURLAsset(URL: NSURL(fileURLWithPath: path))
    
    for format in asset.availableMetadataFormats {
        print("format:",format)
        for item in asset.metadataForFormat(format) {
            
            print("item:",item.commonKey)
            
            if item.commonKey == "title" {
                
                musicInfo.title = item.value as? String
                
            }else if item.commonKey == "artist"{
                
                musicInfo.artist = item.value as? String
                
            }else if item.commonKey == "albumName"{
                
                musicInfo.albumName = item.value as? String
                
            }else if item.commonKey == "artwork"{
                
                if let data = item.value as? NSData{
                    musicInfo.image = UIImage(data: data)
                }
            }
        }
    }
    
    do{
        let attributes = try NSFileManager.defaultManager().attributesOfItemAtPath(path)
        if let size = attributes[NSFileSize] as? NSNumber {
            musicInfo.fileSize = size.integerValue
        }
        
    }catch{
        
    }
    
    return musicInfo
}

