# NotificationMusic

#####三部分内容：

* 从其他设备导入音频文件 
 
* 把音频剪切成30s以及通知指定的格式 
 
* 设定成通知的声音

#####关键的第3步

iOS没法使用类似系统闹钟，要实现类似效果只能通过本地通知来模拟。本地通知有个soundName属性，用来指定通知触发时的声音。

系统有默认声音，但如果要使用自定义的音乐，看下soundName属性的文档说明：

>For this property, specify the filename (including extension) of a sound resource in the app’s main bundle or UILocalNotificationDefaultSoundName to request the default system sound.

这一段其实是个坑，这里只说了声音资源放在`app’s main bundle`里，main bundle是啥?就是xxx.app文件的这个目录，APP自身代码是没有访问权限的，里面的文件是在APP打包的时候一起打进去的。

这就难办了，如果想从后台下载音乐来设成通知呢？从电脑传文件进来呢？

最后看到了知乎上关于网易云音乐的“音乐闹钟”的一个问题：[网易云音乐的 iOS 版音乐闹钟是怎么实现的](https://www.zhihu.com/question/41468858/answer/119075041)，看到文档里有写只要放到`/Library/Sounds`目录下就可以。试了是对的。

然后，soundName只需要提供文件名（包括扩展名）就可以了，跟在main bundle里一样。


#####导入音乐

两种方法：1、使用iPhone自带的音乐APP里的歌   2、使用airDrop共享或者其他APP分享

######访问ipod音乐库
```
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
```

很简单啊，music标量类型为MPMediaItem，关键是assetURL属性，有这个东西，就可以拿到音频文件了。对于Apple music下载的音乐或者在iCloud上的音乐，这个值为nil.

#####使用文件共享
效果就是，在其他APP里点击分享按钮（如QQ里的在其他应用里打开）后，弹出一系列APP，怎么让你的APP在里面？

在info.plist文件配置Document types字段，在里面设置可接受的类型，我的配置：

```
<key>CFBundleDocumentTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeName</key>
			<string>audio</string>
			<key>LSHandlerRank</key>
			<string>Owner</string>
			<key>LSItemContentTypes</key>
			<array>
				<string>public.audio</string>
			</array>
		</dict>
	</array>
```

![配置截图示例](http://upload-images.jianshu.io/upload_images/624048-2e8531bcff98fd95.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

LSItemContentTypes字段对应的是文件类型的UTI(Uniform Type Identifier
),UTI有一套完整的规范，参考Apple文档[UniformTypeIdentifier](https://developer.apple.com/library/prerelease/content/documentation/General/Conceptual/DevPedia-CocoaCore/UniformTypeIdentifier.html)

这里public.audio可以接受mp3,其他的没试过。

当其他APP或airDrop传递完成，选择你的APP打开后，会调用到APPDeleagte的`func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool`方法，这里的url就是传递的资源的地址，只需要判断一下类型，我暂时是按结尾为mp3来判断。是需要的音频，就可以处理。


####剪切音频

因为通知有限制：1、时长不大于30s 2、格式限定，实测caf m4a可以。这里使用m4a，因为我剪切的方法就能转这个类型。

```
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
            //输出就是m4a
            exportSession.outputFileType = AVFileTypeAppleM4A
            exportSession.timeRange = CMTimeRangeFromTimeToTime(startTime, stopTime)
            
            exportSession.exportAsynchronouslyWithCompletionHandler({ 
                handler(succeed: exportSession.status == .Completed)
            })
        }
    }
```

####稍微封装了下

写了几个类，包括demo一起放在[NotificationMusic](https://github.com/ToFind1991/NotificationMusic)这个项目里。

1、处理音频主要使用类TFCustomNotificationSoundProcessor，它负责把ipod音乐库的音乐拷贝过来，也负责处理从其他设备共享过来的音频文件。

启动APP的时候，调用`func loadSoundNames()`方法，导入ipod音乐库音乐以及加载已经在声音资源目录（/Libraty/Sounds）下的音频。

然后把所有可用的声音的文件名提取出来，统一存放在`soundNames`属性里。

2、从其他设备接收资源，在handleURL方法里，使用`tryHandleMusicURL`处理就可以

3、因为加载音频本身是异步的，所以在加载完需要一个通知来提醒外界，做界面更新之类的。

```
dispatch_async(dispatch_get_main_queue(), { 
                    NSNotificationCenter.defaultCenter().postNotificationName(TFLoadSoundNameCompletedNotification, object: nil)
                })
```
注意使用这个通知来更新可用的声音。

4、注意info.plist文件里面要配置Document types,才能从其他设备或应用接收资源。

