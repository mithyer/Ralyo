//
//  Ralyo+Thread.swift
//  src
//
//  Created by ray on 2018/12/28.
//  Copyright © 2018年 actufo. All rights reserved.
//


import Foundation


extension Thread {

    @objc fileprivate static func ry_perform_closure(_ info: Any) {
        autoreleasepool {
            let closure = info as! () -> Void
            closure()
        }
    }
    
    static private func perform(_ closure: @escaping () -> Void, on thread: Thread, waitUntilDone: Bool, modes: [RunLoop.Mode]? = nil) {
        let modes = modes ?? [RunLoop.Mode.default]
        Thread.perform(#selector(Thread.ry_perform_closure), on: thread, with: closure, waitUntilDone: waitUntilDone, modes: modes.map{ $0.rawValue})
    }
    
    public func async(onModes modes: [RunLoop.Mode]? = nil, _ closure: @escaping () -> Void) {
        Thread.perform(closure, on: self, waitUntilDone: false, modes: modes)
    }
    
    public func sync(onModes modes: [RunLoop.Mode]? = nil, _ closure: @escaping () -> Void) {
        Thread.perform(closure, on: self, waitUntilDone: true, modes: modes)
    }
}
