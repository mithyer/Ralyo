//
//  Cacher.swift
//  CTSEditor
//
//  Created by ray on 2018/1/25.
//  Copyright © 2018年 ray. All rights reserved.
//

import Foundation

public protocol Datable {
    
    static func obj<T: Datable>(fromData data: Data) -> T?
}

public protocol Cacher: class {
    
    associatedtype T: Datable
    
    func cacheToDisk(data: Data, key: String, completed: ((Bool) -> Void)?)
    func cacheToMemery(data: Data, key: String, completed: ((Bool) -> Void)?)
    
    func objFromDisk(key: String, got: @escaping ((Data, T)?) -> Void)
    func objFromMemery(key: String, got: @escaping (T?) -> Void)

    func getDiskCacheSize() -> UInt64?
    func clearCache()
}


