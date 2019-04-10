//
//  CALayer+Download.swift
//  CTSEditor
//
//  Created by ray on 2018/1/25.
//  Copyright © 2018年 ray. All rights reserved.
//

import QuartzCore

extension CALayer {
    
    private static let imageCacher = ImageCacher()
    
    public static func getDiskCacheSize() -> UInt64? {
        return imageCacher.getDiskCacheSize()
    }
    
    public static func clearCache() {
        imageCacher.clearCache()
    }
    
    class ResourcePair {
    
        var resource: Downloader.Resource?
        var placeholderResource: Downloader.Resource?
        
        init(_ r: Downloader.Resource, _ p: Downloader.Resource?) {
            self.resource = r
            self.placeholderResource = p
        }
    }
    
    static private var resourcePairKey: Void?
    var resourcePair: ResourcePair? {
        set {
            objc_setAssociatedObject(self, &CALayer.resourcePairKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &CALayer.resourcePairKey) as? ResourcePair
        }
    }
    
    public func downloadAndDisplayFirstDownloadImage(withResourceAndDownloader rd: (Downloader.Resource, Downloader),
                                                     placeholderResourceAndDownloader prd: (Downloader.Resource, Downloader)? = nil,
                                                     handlerKey: String,
                                                     downloadProgressHandler: ((Int64, Int64) -> Void )? = nil,
                                                     downloadCompletionHandler: ((GIFImage?, Error?) -> Void)? = nil,
                                                     displayConfig: [String: Any]? = nil,
                                                     displayDidBeginHandler: (() -> Void)? = nil,
                                                     displayOverHandler: ((Bool) -> Void)? = nil) {
        let resourcePair = ResourcePair.init(rd.0, prd?.0)
        self.resourcePair = resourcePair
        if let prd = prd {
            prd.1.cacheDownload(cacher: CALayer.imageCacher, resource: prd.0, handlerKey: handlerKey) { [weak self, weak resourcePair] (image, _, error) in
                DispatchQueue.main.async {
                    guard let `self` = self, let rp = resourcePair, rp.placeholderResource == prd.0 else {
                        return
                    }
                    if let image = image {
                        self.ry_display(image, config: nil, completionHandler: nil)
                    }
                }
            }
        }
        rd.1.cacheDownload(cacher: CALayer.imageCacher, resource: rd.0, handlerKey: handlerKey, progressHandler: nil == downloadProgressHandler ? nil : { [weak resourcePair] r, t in

            if let resourcePair = resourcePair, resourcePair.resource == rd.0 {
                DispatchQueue.main.async {
                    downloadProgressHandler?(r, t)
                }
            }
            }, completionHandler: { [weak self, weak resourcePair] image, _, error in
                DispatchQueue.main.async {
                    guard let `self` = self, let rp = resourcePair, rp === resourcePair, rp.resource == rd.0 else {
                        return
                    }
                    self.resourcePair = nil
                    downloadCompletionHandler?(image, error)
                    if let image = image {
                        displayDidBeginHandler?()
                        self.ry_display(image, config: displayConfig, completionHandler: { completed in
                            displayOverHandler?(completed)
                        })
                    }
                }
            }
        )
    }
    
    static public func download(resources: Set<Downloader.Resource>, downloader: Downloader, priority: Float, handlerKey: String, totalProgressHandler: ((Float) -> Void)? = nil, completedHandler: @escaping ([Downloader.Resource: GIFImage]) -> Void) {
        let group = DispatchGroup()
        var progressDic = [Downloader.Resource: Float]()
        var imageDic = [Downloader.Resource: GIFImage]()
        let imageDic_lock = DispatchSemaphore.init(value: 1)
        let resourceCount = resources.count
        
        let handleProgress = { (resource: Downloader.Resource, progress: Float) in
            DispatchQueue.main.async {
                progressDic[resource] = progress
                var totalProgress: Float = 0
                progressDic.forEach({ _, progress in
                    totalProgress += progress
                })
                totalProgressHandler?(totalProgress)
            }
        }
        for resource in resources {
            group.enter()
            progressDic[resource] = 0
            downloader.cacheDownload(cacher: CALayer.imageCacher, resource: resource, priority: priority, handlerKey: handlerKey, progressHandler: { received, total in
                if total <= 0 {
                    return
                }
                handleProgress(resource, Float(received)/Float(total)/Float(resourceCount))
            }, completionHandler: { img, _, _ in
                imageDic_lock.wait()
                imageDic[resource] = img
                imageDic_lock.signal()
                handleProgress(resource, 1/Float(resourceCount))
                group.leave()
            })
        }
        group.notify(queue: DispatchQueue.main, work: DispatchWorkItem.init(block: {
            completedHandler(imageDic)
        }))
    }
    
    
    static public func cancelDownloading(resources: Set<Downloader.Resource>, downloader: Downloader) {
        downloader.cancelDownloading(resources: resources)
    }
    
    
}
