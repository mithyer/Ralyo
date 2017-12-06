//
//  UIControl+Ralyo.swift
//  Selector-Closure
//
//  Created by ray on 2017/12/19.
//  Copyright © 2017年 ray. All rights reserved.
//

import UIKit


public class Invoker<T: AnyObject> {
    
    weak var sender: T?
    
    var events: UIControl.Event?
    
    var closure: (T) -> Void
    
    public var action: Selector {
        return #selector(invoke)
    }
    
    public init(_ sender: T, _ closure: @escaping (T) -> Void) {
        self.sender = sender
        self.closure = closure
    }
    
    @objc func invoke() {
        if let sender = self.sender {
            self.closure(sender)
        }
    }
}

extension UIControl.Event: Hashable {
    
    public var hashValue: Int {
        return self.rawValue.hashValue
    }
}

class DicWrapper<K: Hashable, V> {
    
    var dic = [K: V]()
}

class ArrayWrapper<T> {
    
    var array = [T]()
}

fileprivate typealias InvokersDicWrapper<T: UIControl> = DicWrapper<UIControl.Event, ArrayWrapper<Invoker<T>>>

fileprivate var invokersDicWrapperKey: Void?


extension Ralyo where OBJ: UIControl {
    
    func invokers(forEvents events: UIControl.Event, createIfNotExist: Bool = true) -> ArrayWrapper<Invoker<OBJ>>? {
        
        let dicWrapper: InvokersDicWrapper<OBJ>? = objc_getAssociatedObject(self, &invokersDicWrapperKey) as? InvokersDicWrapper<OBJ> ?? {
            if !createIfNotExist {
                return nil
            }
            let wrapper = InvokersDicWrapper<OBJ>()
            objc_setAssociatedObject(self, &invokersDicWrapperKey, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return wrapper
        }()
        if nil == dicWrapper {
            return nil
        }
        let invokers: ArrayWrapper<Invoker<OBJ>>? = dicWrapper!.dic[events] ?? {
            if !createIfNotExist {
                return nil
            }
            let invokers = ArrayWrapper<Invoker<OBJ>>()
            dicWrapper!.dic[events] = invokers
            return invokers
        }()
        return invokers
    }
    
    @discardableResult
    public func add(_ events: UIControl.Event? = nil, _ closure: @escaping (OBJ) -> Void) -> Invoker<OBJ> {
        let control = self.obj
        let events: UIControl.Event! = events ?? {
            switch control {
                case is UIButton: return .touchUpInside
                case is UISwitch: fallthrough
                case is UISlider: return .valueChanged
                case is UITextField: return .editingChanged
                default: return nil
            }
        }()
        assert(nil != events, "no default events for T")
        
        let wrapper: ArrayWrapper<Invoker<OBJ>> = invokers(forEvents: events)!
        let invoker = Invoker(control, closure)
        invoker.events = events
        wrapper.array.append(invoker)
        control.addTarget(invoker, action: invoker.action, for: events)
        return invoker
    }
    
    public func remove(_ invoker: Invoker<OBJ>) {
        guard let dicWrapper = objc_getAssociatedObject(self, &invokersDicWrapperKey) as? InvokersDicWrapper<OBJ>,
            let events = invoker.events,
            let arrayWrapper = dicWrapper.dic[events] else {
            return
        }
        let control = self.obj
        for (idx, ivk) in arrayWrapper.array.enumerated() {
            if ivk === invoker {
                control.removeTarget(invoker, action: invoker.action, for: events)
                arrayWrapper.array.remove(at: idx)
                break
            }
        }
    }
    
    public func removeAll(for events: UIControl.Event) {
        let control = self.obj
        guard let wrapper = invokers(forEvents: events, createIfNotExist: false) else {
            return
        }
        for invoker in wrapper.array {
            control.removeTarget(invoker, action: invoker.action, for: events)
        }
        wrapper.array.removeAll()
    }
    
    public func didAdd(_ events: UIControl.Event) -> Bool {
        guard let wrapper = invokers(forEvents: events, createIfNotExist: false) else {
            return false
        }
        return wrapper.array.count > 0
    }
}

