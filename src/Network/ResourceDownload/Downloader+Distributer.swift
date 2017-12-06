//
//  TaskDistributer.swift
//  Vendor
//
//  Created by ray on 2018/12/24.
//  Copyright © 2018年 ray. All rights reserved.
//


import Foundation

extension Downloader {
    
    class Distributer: NSObject, URLSessionDownloadDelegate {
        
        var tasksDic = [Resource: Task]()
        var tasksReorderArray = [Task]()
        private var needReorder = false
        
        func task(forResource resource: Resource, priority: Float, downloader: Downloader) -> Task {
            var task: Task!
            task = self.tasksDic[resource]
            if nil == task {
                task = Task(resource, downloader)
                self.tasksDic[resource] = task
                self.needReorder = true
                self.tasksReorderArray.append(task)
            }
            if priority != task.priority {
                task.priority = priority
                self.needReorder = true
            }
            return task
        }
        
        @objc func createTaskIfExistWithAddingHanlder(_ info: [Any]) {
            let downloader = info[0] as! Downloader
            let resource = info[1] as! Resource
            let priority = info[2] as! Float
            let handlerArg = info[3] as! (String?, ProgressHandler?, CompletionHandler?)
            let task = self.task(forResource: resource, priority: priority, downloader: downloader)
            if let handlerKey = handlerArg.0 {
                if let progressHandler = handlerArg.1 {
                    if nil == task.resumeData {
                        progressHandler(0, 0)
                    }
                    task.progressHandlerDic[handlerKey] = progressHandler
                }
                if let completionHandler = handlerArg.2 {
                    task.completedHandlerDic[handlerKey] = completionHandler
                }
            }
            markResume(task)
        }
        
        private func reorderTasks() {
            
            self.tasksReorderArray.sort { (l, r) -> Bool in
                let lv = l.priority
                let rv = r.priority
                if lv != rv {
                    return lv > rv
                }
                return l.id >= r.id
            }
        }
        
        private var id_flag: UInt = 1
        
        func markResume(_ task: Task) {
            self.id_flag += 1
            task.id = self.id_flag
            self.needReorder = true
            if !self.tasksReorderArray.isEmpty {
                self.resumeTimer()
            }
        }
        
        func markSuspend(_ task: Task) {
            task.id = 1
            self.needReorder = true
        }
        
        func markPause(_ task: Task) {
            task.id = 0
            self.needReorder = true
        }
        
        func makeTaskDone(_ task: Task, data: Data?, error: Error?) {
            
            self.tasksDic.removeValue(forKey: task.resource)
            if let idx = self.tasksReorderArray.firstIndex(where: { (t) -> Bool in
                return t.resource == task.resource
            }) {
                self.tasksReorderArray.remove(at: idx)
            }
            
            task.makeDone(withData: data, error: error)
        }
        
        lazy private(set) var thread: Thread = {
            let thread = Thread.init(target: self, selector: #selector(start), object: nil)
            thread.qualityOfService = .utility
            thread.name = "RYExtension.Downloader.Distributer.thread.\(self)"
            return thread
        }()
        
        weak var _timer: Timer?
        func resumeTimer() {
            if nil != _timer {
                return
            }
            console_assert(Thread.current == self.thread)
            let timer = Timer.init(timeInterval: 0.1, target: Distributer.self, selector: #selector(Distributer.checkTasks(_:)), userInfo: { [weak self] () -> Distributer? in
                return self
                }, repeats: true)
            RunLoop.current.add(timer, forMode: .common)
            timer.fire()
            _timer = timer
        }
        
        func stopTimer() {
            _timer?.invalidate()
            _timer = nil
        }
        
        @objc private func start() {
            RunLoop.current.add(Port(), forMode: .common)
            RunLoop.current.run()
        }
        
        private enum URLSessionCallbackCase {
            
            case taskDidResumeAtOffset(URLSession, URLSessionDownloadTask, Int64, Int64)
            case taskDidFinishDownloading(URLSession, URLSessionDownloadTask, Data?)
            case taskDidWriteData(URLSession, URLSessionDownloadTask, Int64, Int64, Int64)
            case taskDidCompleteWithError(URLSession, URLSessionDownloadTask, Error?)
            case urlSessionDidBecomeInvalidWithError(URLSession, Error?)
        }
        
        @objc private func urlSessionCallback(info: Any) {
            let `case` = info as! URLSessionCallbackCase
            switch `case` {
            case let .taskDidResumeAtOffset(_, downloadTask, fileOffset, expectedTotalBytes):
                let task = downloadTask.task!
                task.progressHandlerDic.forEach { (_, handler) in
                    handler(fileOffset, expectedTotalBytes)
                }
            case let .taskDidFinishDownloading(_, downloadTask, data):
                let task = downloadTask.task!
                self.makeTaskDone(task, data: data, error: nil)
            case let .taskDidWriteData(_, downloadTask, _, totalBytesWritten, totalBytesExpectedToWrite):
                let task = downloadTask.task!
                task.progressHandlerDic.forEach { (_, handler) in
                    handler(totalBytesWritten, totalBytesExpectedToWrite)
                }
            case let .taskDidCompleteWithError(_, downloadTask, error):
                guard let error = error as NSError? else { // if no error, handle in taskDidFinishDownloading
                    return
                }
                let task = downloadTask.task!
                if error.code == NSURLErrorCancelled {
                    if let resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                        console_print("Complete with resumeData md5: " + "\(resumeData.hashValue)" + ", status: \(task.status)")
                        task.resumeData = resumeData
                    } else {
                        console_print("Complete without resumeData, status: \(task.status)")
                    }
                } else {
                    self.makeTaskDone(task, data: nil, error: error)
                }
            case let .urlSessionDidBecomeInvalidWithError(_, error):
                self.tasksReorderArray.forEach { (task) in
                    task.makeDone(withData: nil, error: error)
                }
                self.tasksReorderArray.removeAll()
                self.tasksDic.removeAll()
            }
        }
        
        deinit {
            _timer?.invalidate()
        }
        
        override init() {
            super.init()
            self.thread.start()
        }
        
        var maxConcurrentTaskNum: Int = 5
        
        @objc private class func checkTasks(_ timer: Timer) {
            let closure = timer.userInfo as! () -> Distributer?
            closure()?.checkTasks()
        }
        
        private func checkTasks() {
            
            if self.tasksReorderArray.isEmpty {
                self.stopTimer()
                return
            }
            
            if self.needReorder {
                self.needReorder = false
                self.reorderTasks()
            }
            
            let reorderArray = self.tasksReorderArray
            let splitCount = min(reorderArray.count, self.maxConcurrentTaskNum)
            for i in 0..<splitCount {
                let task = reorderArray[i]
                if task.id >= 1 {
                    task.resume()
                } else if task.id == 0 {
                    task.pause()
                } else {
                    console_assertFailure()
                }
            }
            for i in splitCount..<reorderArray.count {
                let task = self.tasksReorderArray[i]
                if task.id >= 1 {
                    task.suspend()
                } else {
                    task.pause()
                }
            }
        }
        
        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
            
            self.perform(#selector(urlSessionCallback), on: self.thread, with: URLSessionCallbackCase.taskDidResumeAtOffset(session, downloadTask, fileOffset, expectedTotalBytes), waitUntilDone: false, modes: [RunLoop.Mode.common.rawValue])
        }
        
        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
            
            let data = try? Data.init(contentsOf: location, options: [.uncached])
            self.perform(#selector(urlSessionCallback), on: self.thread, with: URLSessionCallbackCase.taskDidFinishDownloading(session, downloadTask, data), waitUntilDone: false, modes: [RunLoop.Mode.common.rawValue])
        }
        
        func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
            
            self.perform(#selector(urlSessionCallback), on: self.thread, with: URLSessionCallbackCase.urlSessionDidBecomeInvalidWithError(session, error), waitUntilDone: false, modes: [RunLoop.Mode.common.rawValue])
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            
            guard let downloadTask = task as? URLSessionDownloadTask else {
                console_assertFailure()
                return
            }
            self.perform(#selector(urlSessionCallback), on: self.thread, with: URLSessionCallbackCase.taskDidCompleteWithError(session, downloadTask, error), waitUntilDone: false, modes: [RunLoop.Mode.common.rawValue])
        }
        
        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
            self.perform(#selector(urlSessionCallback), on: self.thread, with: URLSessionCallbackCase.taskDidWriteData(session, downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite), waitUntilDone: false, modes: [RunLoop.Mode.common.rawValue])
        }
        
    }
}
