//
//  CALayer+GIFPlay.swift
//  CTSEditor
//
//  Created by ray on 2018/1/29.
//  Copyright © 2018年 ray. All rights reserved.
//

import Foundation
import QuartzCore

extension CALayer {
    
    private class GIFPlayer: NSObject, CAAnimationDelegate {
        
        private var animationOver: ((Bool) -> Void)?
        private var image: GIFImage!
        private var repeatForever: Bool!
        weak var layer: CALayer?
        
        private var playedTime: TimeInterval = 0
        private var keyFrame: Int = 0
        
        fileprivate enum Status {
            
            case notBegin
            case playing
            case pause
            case stopped(clearContent: Bool)
        }
        
        let lock = DispatchSemaphore.init(value: 1)
        private var _status: Status = .notBegin
        fileprivate var status: Status  {
            get {
                return _status
            }
            set {
                lock.wait()
                _status = newValue
                switch _status {
                case .notBegin:
                    break
                case .playing:
                    _ = self.timer
                case .pause:
                    _timer?.invalidate()
                    _timer = nil
                case .stopped(let clear):
                    _timer?.invalidate()
                    _timer = nil
                    self.layer?.contents = clear ? nil : image.imageAndDelays.first?.0
                }
                lock.signal()
            }
        }
        
        init(image: GIFImage, layer: CALayer, repeatForever: Bool, startKeyFrame: Int, animationOver: ((Bool) -> Void)?) {
            super.init()
            self.image = image
            self.layer = layer
            self.animationOver = animationOver
            self.repeatForever = repeatForever
            if startKeyFrame < image.imageAndDelays.count {
                self.keyFrame = startKeyFrame
                let (image, delay) = image.imageAndDelays[keyFrame]
                self.layer?.contents = image
                self.playedTime = delay
            }
        }
    
        deinit {
            if let timer = _timer {
                timer.invalidate()
                if let animationOver = self.animationOver {
                    DispatchQueue.main.async {
                        animationOver(false)
                    }
                }

            }
        }
        
        var currentKeyFrame: Int {
            return self.keyFrame
        }
        
        var _timer: Timer?
        var timer: Timer! {
            get {
                if nil == _timer {
                    _timer = Timer.init(timeInterval: 1.0/24, target: GIFPlayer.self, selector: #selector(GIFPlayer.timerRepeat), userInfo: { [weak self] in
                        return self
                    }, repeats: true)
                    RunLoop.current.add(_timer!, forMode: .common)
                }
                return _timer!
            }
            set {
                if nil == newValue {
                    _timer?.invalidate()
                }
                _timer = newValue
            }
        }
        
        func pause() {
            self.status = .pause
        }
        
        func resume() {
            self.status = .playing
        }
        
        func stop(clear: Bool) {
            self.status = .stopped(clearContent: clear)
        }
        
        @objc class func timerRepeat(timer: Timer) {
            autoreleasepool {
                guard let player = (timer.userInfo as? () -> GIFPlayer?)?(), let gImage = player.image, case .playing = player.status else {
                    return
                }
                
                let imageAndDelays = gImage.imageAndDelays
                if player.keyFrame >= imageAndDelays.count - 1 {
                    if player.repeatForever {
                        player.playedTime = 0
                        player.keyFrame = 0
                    } else {
                        player.status = .stopped(clearContent: false)
                        if let animationOver = player.animationOver {
                            DispatchQueue.main.async {
                                animationOver(true)
                            }
                        }
                    }
                    return
                }
                
                let (image, delay) = imageAndDelays[player.keyFrame]
                if delay <= player.playedTime {
                    player.layer?.contents = image
                    player.keyFrame += 1
                }
                player.playedTime += timer.timeInterval
            }
        }
    }
    
    private static var gifPlayerKey: Void?
    private var gifPlayer: GIFPlayer? {
        get {
            return objc_getAssociatedObject(self, &CALayer.gifPlayerKey) as? GIFPlayer
        }
        set {
            objc_setAssociatedObject(self, &CALayer.gifPlayerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private static let gifDisplayThread: Thread = {
        
        let thread = Thread.init(target: CALayer.self, selector: #selector(CALayer.startRunloop), object: nil)
        thread.name = "RYExtension.CALayer.GIFDisplayThread"
        thread.qualityOfService = .userInteractive
        thread.start()
        return thread
    }()
    
    @objc private class func startRunloop() {
        let runloop = RunLoop.current
        runloop.add(Port(), forMode: .common)
        runloop.run()
    }
    
    @objc private func displayGIF(_ array: NSArray) {
        
        autoreleasepool {
            
            let gifImage = array[0] as! GIFImage
            let completionHandler = array[1] as? (Bool) -> ()
            let repeatForever = array[2] as! Bool
            let startKeyFrame = array[3] as! Int

            self.gifPlayer = nil
            if gifImage.isDynamic {
                self.gifPlayer = GIFPlayer.init(image: gifImage, layer: self, repeatForever: repeatForever, startKeyFrame: startKeyFrame, animationOver: completionHandler)
                self.gifPlayer!.resume()
            } else {
                self.contents = gifImage.imageAndDelays.first?.0
                completionHandler?(true)
            }
        }
    }
    
    public static let GIFDisplayConfigStartKeyFrameKey = "GIFDisplayConfigStartKeyFrameKey"
    public static let GIFDisplayConfigRepeatForeverKey = "GIFDisplayConfigRepeatForeverKey"

    public func ry_display(_ gifImage: GIFImage, config: [String: Any]?, completionHandler: ((Bool) -> ())?) {
        let repeatForever = config?[CALayer.GIFDisplayConfigRepeatForeverKey] as? Bool ?? false
        let startKeyFrame = config?[CALayer.GIFDisplayConfigStartKeyFrameKey] as? Int ?? 0
        if gifImage.isDynamic {
            self.perform(#selector(displayGIF), on: CALayer.gifDisplayThread, with: [gifImage, completionHandler ?? (), repeatForever, startKeyFrame] as NSArray, waitUntilDone: false, modes: [RunLoop.Mode.common.rawValue])
        } else {
            self.contents = gifImage.imageAndDelays.first?.0
        }

    }
    
    public var ry_isPlayingGIF: Bool {
        if let status = self.gifPlayer?.status, case .playing = status {
            return true
        }
        return false
    }
    
    public var ry_currentDisplayKeyFrame: Int? {
        return self.gifPlayer?.currentKeyFrame
    }
    
    public func ry_clearContents() {
        if let player = self.gifPlayer {
            player.stop(clear: true)
        } else {
            self.contents = nil
        }
        self.gifPlayer = nil
    }
    
    public func ry_resume() {
        self.gifPlayer?.resume()
    }
    
    public func ry_pause() {
        self.gifPlayer?.pause()
    }

}
