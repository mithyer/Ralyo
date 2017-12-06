//
//  QuartzCore+Ralyo.swift
//  Vendor
//
//  Created by ray on 2018/11/19.
//  Copyright © 2018年 ray. All rights reserved.
//

import QuartzCore

extension CAAnimation {
    
    public class DelegateHandler: NSObject, CAAnimationDelegate {
        
        public var animationDidStart: ((CAAnimation) -> Void)?
        public var animationDidStop: ((CAAnimation, Bool) -> Void)?
        
        public func animationDidStart(_ anim: CAAnimation) {
            self.animationDidStart?(anim)
        }
        
        public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
            self.animationDidStop?(anim, flag)
        }
    }
}

