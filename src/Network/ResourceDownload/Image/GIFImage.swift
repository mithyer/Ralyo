//
//  GIFImage.swift
//  CTSEditor
//
//  Created by ray on 2018/1/29.
//  Copyright © 2018年 ray. All rights reserved.
//

import Foundation
import CoreGraphics
import CoreImage

public class GIFImage {
    
    public let imageAndDelays: [(CGImage, TimeInterval/*时间点*/)]
    public let duration: TimeInterval
    
    public var isDynamic: Bool {
        return self.imageAndDelays.count > 1
    }

    public init?(_ source: CGImageSource) {
        let count = CGImageSourceGetCount(source)
        
        if count < 1 {
            return nil
        }
        
        var imageAndDelays = [(CGImage, TimeInterval)]()
        var duration: TimeInterval = 0
        
        for i in 0..<count {
            let delaySeconds = GIFImage.delayForImageAtIndex(Int(i), source: source)
            duration += delaySeconds
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                imageAndDelays.append((image, duration))
            }
        }
        self.imageAndDelays = imageAndDelays
        self.duration = duration
    }
    
    public convenience init?(_ data: Data) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("GIFImage: Source for the image does not exist")
            return nil
        }
        self.init(source)
    }
    
    private static func delayForImageAtIndex(_ index: Int, source: CGImageSource!) -> Double {
        
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifPropertiesPointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 0)
        if !CFDictionaryGetValueIfPresent(cfProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque(), gifPropertiesPointer) {
            return 0.1
        }
        let gifProperties:CFDictionary = unsafeBitCast(gifPropertiesPointer.pointee, to: CFDictionary.self)
        
        var delayObject: AnyObject = unsafeBitCast(
            CFDictionaryGetValue(gifProperties,
                                 Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
            to: AnyObject.self)
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties,
                                                             Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }
        
        return delayObject as? Double ?? 0.1
    }
    
}
