//
//  Ralyo.swift
//  src
//
//  Created by ray on 2018/12/27.
//  Copyright © 2018年 actufo. All rights reserved.
//

import ObjectiveC
import Foundation

fileprivate var ralyoObjKey: Void?
fileprivate var objRalyoKey: Void?
fileprivate var ralyoPropertyKey: Void?

public protocol RalyoProperty {}

public final class Ralyo<OBJ: AnyObject> {

    var obj: OBJ {
        return objc_getAssociatedObject(self, &ralyoObjKey) as! OBJ
    }
    
    public func strongStoredObject<T>(forKey key: inout Void?) -> T? {
        return objc_getAssociatedObject(self, &key) as? T
    }
    
    public func strongStore(_ object: Any?, forKey key: inout Void?) {
        objc_setAssociatedObject(self, &key, object, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    public func weakStoredObject<T>(forKey key: inout Void?) -> T? {
        guard let getter = objc_getAssociatedObject(self, &key) as? (() -> T?) else {
            return nil
        }
        if let object = getter() {
            return object
        } else {
            objc_setAssociatedObject(self, &key, nil, .OBJC_ASSOCIATION_COPY_NONATOMIC)
            return nil
        }
    }
    
    public func weakStore(_ object: AnyObject?, forKey key: inout Void?) {
        if let object = object {
            objc_setAssociatedObject(self, &key, { [weak object] in
                return object
            }, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        } else {
            objc_setAssociatedObject(self, &key, nil, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    public func associatedStrongStoredProperty<T: RalyoProperty>(_ initProperty: @autoclosure () -> T) -> T {
        return strongStoredObject(forKey: &ralyoPropertyKey) ?? {
            let property = initProperty()
            strongStore(property, forKey: &ralyoPropertyKey)
            return property
        }()
    }
    
}

public protocol RalyoProtocol {
    
    associatedtype OBJ: AnyObject
    static var ry: Ralyo<OBJ>.Type { get }
    var ry: Ralyo<OBJ> { get }
}

extension RalyoProtocol where Self: AnyObject {
    
    public static var ry: Ralyo<Self>.Type {
        return Ralyo<Self>.self
    }
    
    public var ry: Ralyo<Self> {
        return objc_getAssociatedObject(self, &objRalyoKey) as? Ralyo<Self> ?? {
            let ralyo = Ralyo<Self>()
            objc_setAssociatedObject(ralyo, &ralyoObjKey, self, .OBJC_ASSOCIATION_ASSIGN)
            objc_setAssociatedObject(self, &objRalyoKey, ralyo, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return ralyo
        }()
    }
}
