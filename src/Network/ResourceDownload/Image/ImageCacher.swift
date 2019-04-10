//
//  ImageCacher.swift
//  CTSEditor
//
//  Created by ray on 2018/1/25.
//  Copyright © 2018年 ray. All rights reserved.
//

import Foundation

extension GIFImage: Datable {
    public static func obj<T: Datable>(fromData data: Data) -> T? {
        return GIFImage.init(data) as? T
    }
}

public class ImageCacher: Cacher {
    
    public typealias T = GIFImage
    
    public init() {}
    
    let rwQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "ImageCacher.rwQueue"
        return queue
    }()
    
    let memeryCache: NSCache<NSString, NSData> = {
        let cache = NSCache<NSString, NSData>.init()
        cache.totalCostLimit = 50 * 1024 //k
        return cache
    }()
    
    let fileManager = FileManager()
    lazy var diskPath: String = {
        var path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        path += "/ry/\(Bundle.init(for: ImageCacher.self).bundleIdentifier!)/image_cache"
        #if DEBUG
        path += "/debug"
        #endif
        self.rwQueue.addOperations([BlockOperation.init(block: {
            if !self.fileManager.fileExists(atPath: path) {
                try? self.fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            }
        })], waitUntilFinished: true)
        return path
    }()
    
    func pathForKey(_ key: String) -> String {
        return diskPath + "/" + key
    }

    public func cacheToDisk(data: Data, key: String, completed: ((Bool) -> Void)?) {
        
        self.rwQueue.addOperation {
            var res = true
            do {
                try data.write(to: URL.init(fileURLWithPath: self.pathForKey(key)), options: .atomic)
            } catch {
                res = false
                print("cacheToDisk Error:\(error)")
            }
            if res {
                self.diskCacheSize = nil
            }
            completed?(res)
        }
    }
    
    public func cacheToMemery(data: Data, key: String, completed: ((Bool) -> Void)?) {
        let kb = data.count/1024
        if kb > 1048 {
            return
        }
        self.memeryCache.setObject(data as NSData, forKey: key as NSString, cost: kb)
    }

    
    public func objFromDisk(key: String, got: @escaping ((Data, T)?) -> Void) {
        self.rwQueue.addOperation {
            let res: (Data, T)? = {
                guard let data = try? Data.init(contentsOf: URL.init(fileURLWithPath: self.pathForKey(key)), options: [.mappedIfSafe, .uncached]) else {
                    return nil
                }
                if let image: GIFImage = GIFImage.obj(fromData: data) {
                    return (data, image)
                }
                return nil
            }()
            got(res)
        }
    }
    
    public func objFromMemery(key: String, got: @escaping (T?) -> Void) {
        let res: T? = {
            guard let data = self.memeryCache.object(forKey: key as NSString) as Data? else {
                return nil
            }
            return GIFImage.init(data)
        }()
        got(res)
    }
    
    var diskCacheSize: UInt64?
    public func getDiskCacheSize() -> UInt64? {
        if let diskCacheSize = self.diskCacheSize {
            return diskCacheSize
        }
        guard let enumerator = self.fileManager.enumerator(at: URL.init(string: self.diskPath)!, includingPropertiesForKeys: [URLResourceKey.fileSizeKey], options: .skipsHiddenFiles) else {
            return nil
        }
        var total: UInt64 = 0
        for obj in enumerator {
            guard let url = obj as? URL else {
                continue
            }
            guard let size = (try? url.resourceValues(forKeys: [URLResourceKey.fileSizeKey]).fileSize) as? Int else {
                continue
            }
            total += UInt64(size)
        }
        diskCacheSize = total
        return total > 0 ? total : nil
    }
    
    public func clearCache() {
        diskCacheSize = nil
        self.rwQueue.cancelAllOperations()
        self.rwQueue.addOperations([BlockOperation.init(block: {
            self.memeryCache.removeAllObjects()
            try? self.fileManager.removeItem(atPath: self.diskPath)
            try? self.fileManager.createDirectory(atPath: self.diskPath, withIntermediateDirectories: true, attributes: nil)
        })], waitUntilFinished: true)
    }
}
