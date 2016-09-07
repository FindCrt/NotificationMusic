# NotificationMusic

#####三部分内容：

* 从其他设备导入音频文件 
 
* 把音频剪切成30s以及通知指定的格式 
 
* 设定成通知的声音

#####需求

iOS没法使用类似系统闹钟，要实现类似效果只能通过本地通知来模拟。本地通知有个soundName属性，用来指定通知触发时的声音。

系统有默认声音，但如果要使用自定义的音乐，看下soundName属性的文档说明：

>For this property, specify the filename (including extension) of a sound resource in the app’s main bundle or UILocalNotificationDefaultSoundName to request the default system sound.

这一段其实是个坑，这里只说了声音资源放在`app’s main bundle`里，main bundle是啥?就是xxx.app文件的这个目录，APP自身代码是没有访问权限的，里面的文件是在APP打包的时候一起打进去的。

这就难办了，如果想从后台下载音乐来设成通知呢？从电脑传文件进来呢？

最后看到了知乎上关于网易云音乐的“音乐闹钟”的一个问题：[网易云音乐的 iOS 版音乐闹钟是怎么实现的](https://www.zhihu.com/question/41468858/answer/119075041)，看到文档里有写只要放到`/Library/Sounds`目录下就可以。试了是对的。

然后，soundName只需要提供文件名（包括扩展名）就可以了，跟在main bundle里一样。


#####关于项目

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

详细参考博客：[使用沙盒里或下载音乐自定义通知声音（以及APP间文件共享和访问ipod音乐库）](http://www.jianshu.com/p/57bf2ad33d92)
