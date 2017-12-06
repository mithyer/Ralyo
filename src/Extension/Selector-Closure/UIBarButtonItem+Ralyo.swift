//
//  UIBarButtonItem+Ralyo.swift
//  Selector-Closure
//
//  Created by ray on 2017/12/22.
//  Copyright © 2017年 ray. All rights reserved.
//

import UIKit

fileprivate var invokerKey: Void?

extension UIBarButtonItem: RalyoProtocol {
    
    func setupInvoker<T: UIBarButtonItem>(_ closure: @escaping (T) -> Void) {
        let invoker = Invoker(self as! T, closure)
        objc_setAssociatedObject(self, &invokerKey, invoker, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        self.target = invoker
        self.action = invoker.action
    }
}

extension Ralyo where OBJ: UIBarButtonItem {
    
    static public func initialize(image: UIImage?, style: UIBarButtonItem.Style, _ closure: @escaping (OBJ) -> Void) -> OBJ {
        let btnItem = OBJ.init(image: image, style: style, target: nil, action: nil)
        btnItem.setupInvoker(closure)
        return btnItem
    }
    
    static public func initialize(title: String?, style: UIBarButtonItem.Style, _ closure: @escaping (OBJ) -> Void) -> OBJ {
        let btnItem = OBJ.init(title: title, style: style, target: nil, action: nil)
        btnItem.setupInvoker(closure)
        return btnItem
    }
    
    static public func initialize(barButtonSystemItem systemItem: UIBarButtonItem.SystemItem, _ closure: @escaping (OBJ) -> Void) -> OBJ {
        let btnItem = OBJ.init(barButtonSystemItem: systemItem, target: nil, action: nil)
        btnItem.setupInvoker(closure)
        return btnItem
    }
    
    static public func initialize(customView: UIView, _ closure: @escaping (OBJ) -> Void) -> OBJ {
        let btnItem = OBJ.init(customView: customView)
        btnItem.setupInvoker(closure)
        return btnItem
    }
    
    public func sendAction() {
        if let target = self.obj.target, let action = self.obj.action {
            _ = target.perform(action)
        }
    }
}


