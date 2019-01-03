//
//  Console+Print.swift
//  Vendor
//
//  Created by ray on 2018/12/14.
//  Copyright © 2018年 ray. All rights reserved.
//

import UIKit

public func console_print<T>(_ item: @autoclosure () -> T, color: @autoclosure () -> UIColor? = nil, global: Bool? = nil, file: StaticString? = #file, line: UInt? = #line) {
    #if !PUBLISH
    Console.print(item, color: color(), global: global, file: file, line: line, isInput: false)
    #endif
}

public func console_assert(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    #if !PUBLISH
    if !condition() {
        Console.print("Console Assert Failed:\(message()) file:\(file) line:\(line)", color: UIColor.red, global: true, file: file, line: line, isInput: false)
        abort()
    }
    #endif
}

public func console_assertFailure(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    #if !PUBLISH
    console_assert(false, message, file: file, line: line)
    #endif
}

#if !PUBLISH
extension Console {
    
    static func print<T>(_ item: @autoclosure () -> T, color: UIColor? = nil, global: Bool? = nil, file: StaticString? = #file, line: UInt? = #line, isInput: Bool) {
        
        if !Console.didSetup {
            return
        }
        
        let content = "\(item())"
        let now = Date()
        
        var fileName: String?
        if let file = file {
            fileName = "\(file)"
            if let last = fileName?.split(separator: "/").last {
                fileName = String(last)
            }
        }
        
        if global ?? true {
            var printText = isInput ? "[Console.Input]" : "[Console.Print]"
            printText.append(" \(self.dateFormatter.string(from: now))")
            if !isInput {
                if let fileName = fileName {
                    printText.append(" \(fileName)")
                }
                if let line = line {
                    printText.append(" \(line)")
                }
            }
            printText.append(": \(content)\n")
            Swift.print(printText)
        }
        
        let log = Log(content: content, color: color, date: now, fileName: fileName, line: line)
        var shouldResetFile = false
        logsQueue.sync {
            if self.logs.count >= maxLogAmount {
                self.logs.removeAll()
                shouldResetFile = true
            }
            self.logs.append(log)
        }
        if shouldResetFile {
            Log.DiskOutput.resetFileHandler()
        }
        _ = Log.DiskOutput.append(log)
        if !Console.windowIsHidden {
            DispatchQueue.main.async {
                self.consoleVC.reloadData()
            }
        }
    }
}
#endif
