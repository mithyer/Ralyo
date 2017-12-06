//
//  Resource.swift
//  Vendor
//
//  Created by ray on 2018/12/24.
//  Copyright © 2018年 ray. All rights reserved.
//

import Foundation

extension Downloader {
    
    public struct Resource: Hashable {
        
        public private(set) var url: URL
        public private(set) var cacheKey: String
        
        public init(url: URL, key: String) {
            self.url = url
            self.cacheKey = key
        }
        
        public var hashValue: Int {
            return cacheKey.hashValue
        }
        
        public static func ==(lhs: Downloader.Resource, rhs: Downloader.Resource) -> Bool {
            return lhs.cacheKey == rhs.cacheKey
        }
    }
}
