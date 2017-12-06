//
//  UIView+Ralyo.swift
//  Selector-Closure
//
//  Created by ray on 2018/4/13.
//  Copyright © 2018年 ray. All rights reserved.
//

import UIKit

extension UIView: RalyoProtocol {}

extension Ralyo where OBJ: UIView {
    
    @discardableResult
    public func whenTapped(_ enableUserInteraction: Bool = true, _ closure: @escaping (UITapGestureRecognizer) -> Void) -> UITapGestureRecognizer  {
        let view = self.obj
        if enableUserInteraction {
            view.isUserInteractionEnabled = true
        }
        let recg = UITapGestureRecognizer.ry.initialize(closure)
        view.addGestureRecognizer(recg)
        return recg
    }
}
