//
//  Ralyo.swift
//  src
//
//  Created by ray on 2018/12/27.
//  Copyright © 2018年 actufo. All rights reserved.
//

import ObjectiveC

fileprivate var ralyoObjKey: Void?
fileprivate var objRalyoKey: Void?

public final class Ralyo<OBJ: AnyObject> {

    var obj: OBJ {
        return objc_getAssociatedObject(self, &ralyoObjKey) as! OBJ
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
