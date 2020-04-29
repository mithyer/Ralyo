//
//  UIViewController+Ralyo.swift
//  Circul
//
//  Created by ray on 2019/4/1.
//  Copyright © 2019年 actufo. All rights reserved.
//

import UIKit

extension UIViewController: RalyoProtocol {}

@objc public protocol UIViewControllerQueuePresentDelegate {
    
    @objc optional func queuePresentWillStart(onVC: UIViewController)
    @objc optional func queuePresentDidEnd(onVC: UIViewController)
    @objc optional func queuePresentWillPresent(_ vc: UIViewController, onVC: UIViewController)
}

extension Ralyo where OBJ: UIViewController {
    
    fileprivate class QueuePresentInfo {
        
        var ctrler: UIViewController
        var animated: Bool
        var presented: (() -> Void)?
        var countdown: TimeInterval?
                
        init(ctrler: UIViewController, animated: Bool, dismissSeconds: TimeInterval?, presented: (() -> Void)?) {
            self.ctrler = ctrler
            self.countdown = dismissSeconds
            self.presented = presented
            self.animated = animated
        }
        
    }
    
    fileprivate class Property: RalyoProperty {
        
        weak var rootVC: UIViewController?
        weak var queuePresentDelegate: UIViewControllerQueuePresentDelegate?
        weak var queuePresentTimer: Timer?
        lazy var needToPresentInfos = [QueuePresentInfo]()
        
        @objc fileprivate func timerUpdate(_ timer: Timer) {
            
            guard let rootVC = self.rootVC else {
                timer.invalidate()
                return
            }
            
            if rootVC.isBeingDismissed || rootVC.isBeingPresented || !rootVC.isViewLoaded {
                return
            }
            guard let info = self.needToPresentInfos.first else {
                timer.invalidate()
                self.queuePresentDelegate?.queuePresentDidEnd?(onVC: rootVC)
                return
            }
            if let presentedVC = rootVC.presentedViewController {
                if info.ctrler == presentedVC {
                    if let countdown = info.countdown {
                        info.countdown = countdown - timer.timeInterval
                        if info.countdown! <= 0 {
                            info.ctrler.dismiss(animated: info.animated)
                            self.needToPresentInfos.removeFirst()
                            return
                        }
                    } else {
                        info.ctrler.dismiss(animated: info.animated)
                        self.needToPresentInfos.removeFirst()
                        return
                    }
                }
                return
            }
            var next: UIResponder? = rootVC
            var window: UIWindow?
            repeat {
                next = next?.next
                if let next = next as? UIWindow {
                    window = next
                }
            } while (nil == window) && (nil != next)
            if nil == window {
                return
            }

            self.queuePresentDelegate?.queuePresentWillPresent?(info.ctrler, onVC: rootVC)
            rootVC.present(info.ctrler, animated: info.animated, completion: info.presented)
            if rootVC.presentedViewController == info.ctrler && nil == info.countdown {
                self.needToPresentInfos.removeFirst()
            }
        }
    }
    
    fileprivate var property: Property {
        return self.associatedStrongStoredProperty({
            let property = Property()
            property.rootVC = self.obj
            return property
        })
    }
    
    public var queuePresentDelegate: UIViewControllerQueuePresentDelegate? {
        get {
            return self.property.queuePresentDelegate
        }
        set {
            self.property.queuePresentDelegate = newValue
        }
    }
    
    public var willPresentViewControllersInQueue: [UIViewController] {
        return self.property.needToPresentInfos.map { $0.ctrler }
    }
    
    public func cancelPresentViewController(inQueue where: (UIViewController) -> Bool) {
        self.property.needToPresentInfos.removeAll { (info) -> Bool in
            let ctrler = info.ctrler
            let res = `where`(ctrler)
            return res
        }
    }
    
    public func queuePresent(_ viewController: UIViewController, animated: Bool = true, dismissSecondsAfterAppear seconds: TimeInterval? = nil, _ presented: (() -> Void)? = nil) {
        let rootVC = self.obj
        let info = QueuePresentInfo.init(ctrler: viewController, animated: animated, dismissSeconds: seconds, presented: presented)
        self.property.needToPresentInfos.append(info)
        if nil == self.property.queuePresentTimer {
            self.property.queuePresentTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self.property, selector: #selector(Property.timerUpdate(_:)), userInfo: nil, repeats: true)
            self.queuePresentDelegate?.queuePresentWillStart?(onVC: rootVC)
            self.property.queuePresentTimer!.fire()
        }
    }
}

