//
//  Ralyo+Thread.swift
//  src
//
//  Created by ray on 2018/12/28.
//  Copyright © 2018年 actufo. All rights reserved.
//


import Foundation

extension NSObject: RalyoProtocol {
    
    @objc fileprivate static func ry_perform_closure(_ info: Any) {
        
        autoreleasepool {
            let closure = info as! () -> Void
            closure()
        }
    }
}

extension Ralyo where OBJ == Ralyo_Public_Funcs {
    
    public func perform(_ closure: @escaping () -> Void, on thread: Thread, waitUntilDone: Bool, modes: [RunLoop.Mode]? = nil) {
        
        let modes = modes ?? [RunLoop.Mode.default]
        NSObject.perform(#selector(NSObject.ry_perform_closure), on: thread, with: closure, waitUntilDone: waitUntilDone, modes: modes.map{ $0.rawValue})
    }
}


