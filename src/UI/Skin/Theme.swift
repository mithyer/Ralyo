//
//  AnyObject+Theme.swift
//  CTShow
//
//  Created by ray on 2018/11/22.
//  Copyright © 2018年 ray. All rights reserved.
//

import UIKit

public protocol ThemeProtocol: class {
    @discardableResult
    func registerTheme(forThemeKey key: Theme.Key, themeChangeHandler: @escaping () -> Void) -> (() -> Void)
}

extension ThemeProtocol {
    
    public func registerTheme(forThemeKey key: Theme.Key, themeChangeHandler: @escaping () -> Void) -> (() -> Void) {
        let theme = objc_getAssociatedObject(self, &ThemeConstVar.themeKey) as? Theme ?? {
            let theme = Theme.init(object: self)
            objc_setAssociatedObject(self, &ThemeConstVar.themeKey, theme, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return theme
        }()
        
        theme.registerTheme(themeKey: key, themeChangeHandler: themeChangeHandler)
        return themeChangeHandler
    }
}

fileprivate struct ThemeConstVar {
    
    fileprivate static var themeKey: Void?
    fileprivate static let notiCenter = NotificationCenter.init()
    fileprivate static let changeNoti = NSNotification.Name.init("ThemeChangeNoti")
}

public class Theme {
    
    public struct Key: Hashable {
        private let key: String
        public init(_ key: String) {
            self.key = key
        }
    }
    
    private weak var object: AnyObject?
    private lazy var themeKeyToHandler = [Key: () -> Void]()
    private var observer: AnyObject?
    
    deinit {
        if let observer = self.observer {
            ThemeConstVar.notiCenter.removeObserver(observer)
        }
    }
    
    private init() {}
    
    fileprivate convenience init(object: AnyObject) {
        self.init()
        self.object = object
        observer = ThemeConstVar.notiCenter.addObserver(forName: ThemeConstVar.changeNoti, object: nil, queue: nil) { [unowned self] (noti) in
            let key = noti.userInfo?["key"] as! Key
            let handler = self.themeKeyToHandler[key]
            handler?()
        }
    }
    
    fileprivate func registerTheme(themeKey: Key, themeChangeHandler: @escaping () -> Void) {
        self.themeKeyToHandler[themeKey] = themeChangeHandler
    }
    
    static public private(set) var currentThemeKey: Theme.Key?
    static public func changeToTheme(_ key: Key) {
        if key == currentThemeKey {
            return
        }
        currentThemeKey = key
        ThemeConstVar.notiCenter.post(name: ThemeConstVar.changeNoti, object: nil, userInfo: ["key": key])
    }
}


extension UIViewController: ThemeProtocol {}
extension UIView: ThemeProtocol {}
