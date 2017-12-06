//
//  UIGestureRecognizer+Ralyo.swift
//  Selector-Closure
//
//  Created by ray on 2017/12/22.
//  Copyright © 2017年 ray. All rights reserved.
//

import UIKit

fileprivate var invokerKey: Void?

extension UIGestureRecognizer: RalyoProtocol {}

extension Ralyo where OBJ: UIGestureRecognizer {
    
    static public func initialize(_ closure: @escaping (OBJ) -> Void) -> OBJ {
        let rgzer = OBJ.init()
        let invoker = Invoker(rgzer, closure)
        objc_setAssociatedObject(rgzer, &invokerKey, invoker, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        rgzer.addTarget(invoker, action: invoker.action)
        return rgzer
    }
}


