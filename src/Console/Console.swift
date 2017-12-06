//
//  Console.swift
//  LeBrick
//
//  Created by ray on 2017/12/15.
//  Copyright © 2017年 ray. All rights reserved.
//

#if !PUBLISH
import UIKit

open class Console {

    struct Log: Codable {
        
        struct Color: Codable {
            var r: Int
            var g: Int
            var b: Int
        }
        
        init(content: String, color: UIColor?, date: Date, fileName: String?, line: UInt?) {
            self.content = content
            if let color = color {
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                color.getRed(&red, green: &green, blue: &blue, alpha: nil)
                self.color = Color.init(r: Int(red * 255), g: Int(green * 255), b: Int(blue * 255))
            }
            self.date = date
            self.fileName = fileName
            self.line = line
        }
        
        var fileName: String?
        var line: UInt?
        var content: String
        var color: Color?
        var date: Date
        var isInput: Bool = false
        
        func uiColor() -> UIColor? {
            if let color = self.color {
                return UIColor.init(red: CGFloat(color.r)/255, green: CGFloat(color.g)/255, blue: CGFloat(color.b)/255, alpha: 1)
            }
            return nil
        }
    }

    static var logs: [Log] = []
    
    static let window: UIWindow = {
        let window = UIWindow()
        window.windowLevel = UIWindow.Level.init(UIWindow.Level.statusBar.rawValue + 1)
        window.rootViewController = Console.consoleVC
        window.isHidden = _windowIsHidden
        window.frame = UIScreen.main.bounds
        return window
    }()
    
    static var _windowIsHidden: Bool = true
    static var windowIsHidden: Bool {
        set {
            _windowIsHidden = newValue
            self.window.isHidden = newValue
        }
        get {
            return _windowIsHidden
        }
    }
    
    static let consoleVC: ConsoleVC = {
        let vc = ConsoleVC()
        vc.tappedClose = {
            Console.windowIsHidden = true
        }
        return vc
    }()

    public static func setup() {
        _ = self.window
        setupCrashHandler()
    }
    
    static let sigDic = [SIGHUP: "SIGHUP", SIGINT: "SIGINT", SIGQUIT: "SIGQUIT", SIGABRT: "SIGABRT", SIGILL: "SIGILL", SIGSEGV: "SIGSEGV", SIGFPE: "SIGFPE", SIGBUS: "SIGBUS", SIGPIPE: "SIGPIPE"]
    static func setupCrashHandler() {
        
        NSSetUncaughtExceptionHandler { expt in
            let name = expt.name
            let stack = expt.callStackSymbols.joined(separator: "\n")
            let reason = expt.reason
            let string = "\nEXCEPTION:\n-NAME:\(name.rawValue)\n-REASON:\(reason ?? "unknown")\n-STACK:\n\(stack)"
            Console.print(string, color: .red, global: false, file: nil, line: nil, isInput: false)
        }
        
        for sig in sigDic.keys {
            signal(sig) { sig in
                Console.print("SIGNAL \(Console.sigDic[sig]!)\n" + Thread.callStackSymbols.joined(separator: "\n"), color: .red, global: false, file: nil, line: nil, isInput: false)
            }
        }
    }
    
    
    static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZ"
        return formatter
    }()
    
    public static var textAppearance: [NSAttributedString.Key: Any] = [.font: UIFont(name: "Menlo", size: 12.0)!, .foregroundColor: UIColor.white]
    
    static let maxLogAmount = 1000
    static let logsQueue = DispatchQueue.init(label: "Console.logsQueue")
    
    public static func clear() {
        self.logsQueue.sync {
            if self.logs.isEmpty {
                return
            }
            self.logs.removeAll()
        }
        Log.DiskOutput.resetFileHandler()
    }
}

extension UIWindow {
    
    open override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionBegan(motion, with: event)
        if motion == .motionShake, Console.windowIsHidden {
            Console.windowIsHidden = false
            Console.consoleVC.reloadData()
        }
    }

}

extension Console.Log {
    
    class DiskOutput {
        
        static var curFileName: String?
        static var curFilePath: String?
        static let outputDirectory: String = {
            var path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
            path += "/ry/\(Bundle.init(for: DiskOutput.self).bundleIdentifier!)/console"
            #if DEBUG
            path += "/debug"
            #endif
            return path
        }()
        static let encoder = JSONEncoder()
        static let decoder = JSONDecoder()
        
        private static func newFileHandler() -> FileHandle {
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: outputDirectory) {
                try! fileManager.createDirectory(atPath: outputDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            let now = Date()
            let nowString = CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey)! as! String + "_" + Console.dateFormatter.string(from: now)
            curFilePath = outputDirectory + nowString
            curFileName = nowString
            if !fileManager.fileExists(atPath: curFilePath!) {
                let res = fileManager.createFile(atPath: curFilePath!, contents: Data(), attributes: [.creationDate: now, .ownerAccountName: "ray"])
                assert(res)
            }
            let handler = FileHandle(forWritingAtPath: curFilePath!)!
            return handler
        }
        
        static var fileHandler: FileHandle = DiskOutput.newFileHandler()
        
        static func resetFileHandler() {
            writeQueue.async {
                self.fileHandler.synchronizeFile()
                self.fileHandler.closeFile()
                self.fileHandler = self.newFileHandler()
            }
        }
        
        static var fileData: Data? {
            guard let path = self.curFilePath, let data = try? Data(contentsOf: URL(fileURLWithPath: path), options:Data.ReadingOptions.mappedIfSafe) else {
                return nil
            }
            return data
        }
        
        static let writeQueue = DispatchQueue(label: "ray.console.output")
        
        static func append(_ log: Console.Log) -> UInt64 {
            var point: UInt64!
            writeQueue.sync {
                guard var data = try? encoder.encode(log) else {
                    return
                }
                data.append(",".data(using: .utf8)!)
                point = self.fileHandler.seekToEndOfFile()
                self.fileHandler.write(data)
            }
            return point
        }
        
        static func logFileNames() -> [String]? {
            guard let enumerator = FileManager.default.enumerator(at: URL.init(string: self.outputDirectory)!, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else {
                return nil
            }
            var list = [String]()
            for obj in enumerator {
                guard let url = obj as? URL else {
                    continue
                }
                list.append(url.lastPathComponent)
            }
            list.sort { (l, r) -> Bool in
                return l.compare(r) == .orderedDescending
            }
            return list
        }
        
        static func logs(forFileName name: String) -> [Console.Log]? {
            guard var data = try? Data.init(contentsOf: URL.init(fileURLWithPath: self.outputDirectory + name)) else {
                return nil
            }
            let range = Range<Data.Index>.init(NSRange.init(location: 0, length: 0))!
            data.replaceSubrange(range, with: "[".data(using: .utf8)!)
            data.append("]".data(using: .utf8)!)
            let logs = try? decoder.decode([Console.Log].self, from: data)
            return logs
        }
        
        static func removeLogFile(forName name: String) {
            try? FileManager.default.removeItem(atPath: self.outputDirectory + name)
        }
    }
}

#endif
