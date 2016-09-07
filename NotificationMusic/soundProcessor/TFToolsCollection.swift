//
//  TFTools.swift
//  NotificationMusic
//
//  Created by shiwei on 16/9/7.
//  Copyright © 2016年 shiwei. All rights reserved.
//

import UIKit

//swift中Array在iOS9才有indexOf方法查找元素的index;remove方法都是根据index来移除的
extension Array where Array<Element>.Generator.Element : Equatable{
    
    /**
     求某个元素在数组中的位置
     
     - parameter object: 所求的元素
     
     - returns: 元素的索引，不存在则返回NSNotFound
     */
    func indexOfObject(object: Generator.Element) -> Int{
        var index = -1
        for one in self {
            index += 1
            if one == object {
                break
            }
            
        }
        if index == -1 {
            return NSNotFound
        }
        
        return index
    }
    
    /**
     移除某个元素，返回这个元素的位置；NSNotFound表示不存在
     
     - parameter object: 要被移除的元素
     
     - returns: 被移除元素的位置
     */
    mutating func removeObject(object: Generator.Element) -> Int{
        var index = -1
        for one in self {
            index += 1
            if one == object {
                break
            }
            
        }
        if index != -1 {
            self.removeAtIndex(index)
            return index
        }else{
            return NSNotFound
        }
    }
}
