//
//  Task.swift
//  Vendor
//
//  Created by ray on 2018/12/24.
//  Copyright © 2018年 ray. All rights reserved.
//

import Foundation

extension URLSessionDownloadTask {
    
    private static var taskKey: Void?
    var task: Downloader.Task? {
        get {
            return objc_getAssociatedObject(self, &URLSessionDownloadTask.taskKey) as? Downloader.Task
        }
        set {
            objc_setAssociatedObject(self, &URLSessionDownloadTask.taskKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension Downloader {
    
    public typealias ProgressHandler = (_ received: Int64, _ total: Int64) -> Void
    public typealias CompletionHandler = (_ data: Data?, _ error: Error?) -> Void
    
    class Task: CustomDebugStringConvertible {
        
        enum Status {
            case running, paused, suspended, done
        }
        var status: Status = .suspended
        
        public let resource: Resource
        weak var downloader: Downloader?
        weak var downloadTask: URLSessionDownloadTask?
        var resumeData: Data?
        
        var id: UInt = 0
        var priority: Float = 0
        
        var doneCallback: (() -> Void)?
        
        var progressHandlerDic = [String: ProgressHandler]()
        var completedHandlerDic = [String: CompletionHandler]()
        
        init(_ resource: Resource, _ downloader: Downloader) {
            self.resource = resource
            self.downloader = downloader
        }
        
        func resume() {
            if self.status == .running || self.status == .done {
                return
            }
            console_assert(nil == self.downloadTask)
            if (self.status == .suspended || self.status == .paused), let resumeData = self.resumeData {
                self.downloadTask = self.downloader?.session.downloadTask(withResumeData: resumeData)
            } else {
                self.downloadTask = self.downloader?.session.downloadTask(with: self.resource.url)
            }
            self.downloadTask?.task = self
            self.status = .running
            self.downloadTask?.resume()
        }
        
        func suspend() {
            if self.status == .suspended || self.status == .done {
                return
            }
            self.status = .suspended
            if let downloadTask = self.downloadTask {
                self.downloadTask = nil
                downloadTask.cancel { _ in
                    // handle resumeData by urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
                }
            }
        }
        
        func pause() {
            if self.status == .paused || self.status == .done {
                return
            }
            self.status = .paused
            
            if let downloadTask = self.downloadTask {
                self.downloadTask = nil
                downloadTask.cancel { _ in
                    // handle resumeData by urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
                }
            }
        }
        
        func makeDone(withData data: Data?, error: Error?) {
            if self.status == .done {
                return
            }
            
            for (_, handler) in self.completedHandlerDic {
                handler(data, error)
            }
            self.completedHandlerDic.removeAll()
            
            self.status = .done
            if let downloadTask = self.downloadTask, downloadTask.state == .running {
                self.downloadTask = nil
                downloadTask.cancel()
            }
            self.doneCallback?()
        }
        
        
        public var debugDescription: String {
            return String.init(format: "\(type(of: self)) %x", unsafeBitCast(self, to: Int.self))
        }
    }
}
