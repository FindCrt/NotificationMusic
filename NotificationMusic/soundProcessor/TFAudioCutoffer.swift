//
//  TFAudioCutoffer.swift
//  PoetryAndSchedule
//
//  Created by shiwei on 16/8/19.
//  Copyright © 2016年 shiwei. All rights reserved.
//

import UIKit
import AVFoundation

class TFAudioCutoffer: NSObject {
    
    static let shareInstance = TFAudioCutoffer()
    
    /**
     剪切音乐的指定区间，并转成m4a格式，然后存储
     
     - parameter audioPath:  源文件地址
     - parameter startTime:  剪切开始时间
     - parameter endTime:    剪切结束时间
     - parameter saveDirect: 存储地址全名
     - parameter handler:    处理结果回调
     */
    func cutoffAudio(audioPath: NSURL, startTime: Int64, endTime: Int64, saveDirect:NSURL, handler: (succeed: Bool) -> Void){
        
        let audioAsset = AVURLAsset(URL: audioPath, options: nil)
        
        if let exportSession = AVAssetExportSession(asset: audioAsset, presetName: AVAssetExportPresetAppleM4A){
            
            let startTime = CMTimeMake(startTime, 1)
            let stopTime = CMTimeMake(endTime, 1)
            
            exportSession.outputURL = saveDirect
            exportSession.outputFileType = AVFileTypeAppleM4A
            exportSession.timeRange = CMTimeRangeFromTimeToTime(startTime, stopTime)
            
            exportSession.exportAsynchronouslyWithCompletionHandler({ 
                handler(succeed: exportSession.status == .Completed)
            })
        }
    }

}
