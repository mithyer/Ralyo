//
//  Foundation+RYExtension.swift
//  Vendor
//
//  Created by ray on 2018/12/13.
//  Copyright © 2018年 ray. All rights reserved.
//

import Foundation

extension String {
    
    public func replacingCharacters<T: StringProtocol>(in range: NSRange, with replacement: T) -> String {
        guard let stringRange = Range.init(range, in: self) else {
            return self
        }
        return self.replacingCharacters(in: stringRange, with: replacement)
    }
    
}
