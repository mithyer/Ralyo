//
//  Downloader.swift
//  CTSEditor
//
//  Created by ray on 2018/1/24.
//  Copyright © 2018年 ray. All rights reserved.
//

import Foundation
import ObjectiveC

public class Downloader {
    
    public init() {}
    
    private lazy var distributer = Distributer()
    lazy var session: URLSession = URLSession.init(configuration: URLSessionConfiguration.default, delegate: distributer, delegateQueue: OperationQueue())
    
    public var maxConcurrentTaskNum: Int {
        get {
            return self.distributer.maxConcurrentTaskNum
        }
        set {
            self.distributer.maxConcurrentTaskNum = newValue
        }
    }
    
    public func download(resource: Resource, priority: Float = 0, handlerKey: String?, progressHandler: ProgressHandler? = nil, completionHandler: CompletionHandler? = nil) {
        
        let info: [Any] = [self, resource, priority, (handlerKey, progressHandler, completionHandler)]
        self.distributer.perform(#selector(Distributer.createTaskIfExistWithAddingHanlder), on: self.distributer.thread, with: info, waitUntilDone: false)
    }
    
    
    public func cacheDownload<K: Cacher>(cacher: K, resource: Resource, priority: Float = 0, handlerKey: String? = nil, progressHandler: ProgressHandler? = nil, completionHandler: ((K.T?, Error?) -> Void)? = nil) {
        
        let startDownload = { [weak self, weak cacher] in
            self?.download(resource: resource, priority: priority, handlerKey: handlerKey, progressHandler: progressHandler, completionHandler: { (data, error) in
                guard nil == error, let data = data else {
                    completionHandler?(nil, error)
                    return
                }
                guard let obj: K.T = K.T.obj(fromData: data) else {
                    completionHandler?(nil, error)
                    return
                }
                cacher?.cacheToDisk(data: data, key: resource.cacheKey, completed: nil)
                cacher?.cacheToMemery(data: data, key: resource.cacheKey, completed: nil)
                completionHandler?(obj, error)
            })
        }
        
        let key = resource.cacheKey
        let tryGetObjFromDisk = { [weak cacher] in
            cacher?.objFromDisk(key: key) { res in
                if let res = res {
                    cacher?.cacheToMemery(data: res.0, key: key, completed: nil)
                    completionHandler?(res.1, nil)
                } else {
                    startDownload()
                }
            }
        }
        
        cacher.objFromMemery(key: key) { obj in
            if let obj = obj {
                completionHandler?(obj, nil)
            } else {
                tryGetObjFromDisk()
            }
        }
    }
    
    
    public func isDownloading(resource: Resource) -> Bool {
        let res = nil != distributer.tasksDic[resource]
        return res
    }
    
    public func pauseDownloading(resource: Resource) {
        if let task = self.distributer.tasksDic[resource] {
            self.distributer.markPause(task)
        }
    }

    
    public func cancelDownloading(resources: Set<Resource>) {
        let dic = self.distributer.tasksDic
        resources.forEach { resource in
            guard let task = dic[resource] else {
                return
            }
            self.distributer.makeTaskDone(task, data: nil, error: nil)
        }
    }

}
