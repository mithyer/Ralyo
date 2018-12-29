//
//  CoreGraphics+RYExntension.swift
//  InfiCo
//
//  Created by ray on 2018/6/15.
//  Copyright © 2018年 ray. All rights reserved.
//

import CoreGraphics


extension CGRect {
    
    public static func make(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        
        return self.init(x: x, y: y, width: width, height: height)
    }
    
    public var center: CGPoint {
        
        return CGPoint.init(x: self.midX, y: self.midY)
    }
    
    public var leftTop: CGPoint {
        
        return CGPoint.init(x: self.minX, y: self.minY)
    }
    
    public var leftBottom: CGPoint {
        
        return CGPoint.init(x: self.minX, y: self.maxY)
    }
    
    public var rightTop: CGPoint {
        
        return CGPoint.init(x: self.maxX, y: self.minY)
    }
    
    public var rightBottom: CGPoint {
        
        return CGPoint.init(x: self.maxX, y: self.maxY)
    }
    
    public init(center: CGPoint, size: CGSize) {
        
        self.init(origin: .init(x: center.x - size.width/2, y: center.y - size.height/2), size: size)
    }
    
    public func moveBy(_ dx: CGFloat, _ dy: CGFloat) -> CGRect {
        
        let origin = self.origin + CGVector.make(dx, dy)
        return CGRect.init(origin: origin, size: self.size)
    }
    
    public func randomAnInsidePoint() -> CGPoint {
        
        return CGPoint.make(self.minX + self.width * CGFloat.random0_1(), self.minY + self.height * CGFloat.random0_1())
    }
    
}

extension CGSize {
    
    public static func make(_ width: CGFloat, _ height: CGFloat) -> CGSize {
        
        return self.init(width: width, height: height)
    }
    
    public var zeroRect: CGRect {
        
        return CGRect.init(origin: .zero, size: self)
    }
    
    public static func square(_ width: CGFloat) -> CGSize {
        
        return self.init(width: width, height: width)
    }
    
    public static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
     
        return .make(lhs.width * rhs, lhs.height * rhs)
    }
    
    public static func / (lhs: CGSize, rhs: CGFloat) -> CGSize {
        
        return .make(lhs.width / rhs, lhs.height / rhs)
    }
    
    public func floorSizeString() -> String {
        
        return String.init(format: "{%.0f, %.0f}", self.width, self.height)
    }
}

extension CGVector {
    
    
    public static func make(_ dx: CGFloat, _ dy: CGFloat) -> CGVector {
        
        return self.init(dx: dx, dy: dy)
    }
    
    public var length: CGFloat {
        
        return sqrt(self.dx * self.dx + self.dy * self.dy)
    }
    
    public var unit: CGVector {
        
        let length = self.length
        return CGVector.init(dx: self.dx/length, dy: self.dy/length)
    }
    
    public init(length: CGFloat, radian: CGFloat) {
        
        self.init(dx: length * sin(radian), dy: length * cos(radian))
    }
    
    public static func + (lhs: CGVector, rhs: CGVector) -> CGVector {
        
        return CGVector.init(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
    }
    
    public static func - (lhs: CGVector, rhs: CGVector) -> CGVector {
        
        return CGVector.init(dx: lhs.dx - rhs.dx, dy: lhs.dy - rhs.dy)
    }
    
    public static prefix func - (hs: CGVector) -> CGVector {
        
        return CGVector.init(dx: -hs.dx, dy: -hs.dy)
    }
    
    public static func * (lhs: CGVector, rhs: CGFloat) -> CGVector {
        
        return CGVector.init(dx: lhs.dx * rhs, dy: lhs.dy * rhs)
    }
    
    public static func / (lhs: CGVector, rhs: CGFloat) -> CGVector {
        
        return lhs * (1/rhs)
    }
    
    public func rotateBy(_ radian: CGFloat) -> CGVector {
        return CGVector.make(dx * cos(radian) - dy * sin(radian), dy * cos(radian) + dx * sin(radian))
    }

    public static func radianBetweenTwoVector(_ v1: CGVector, _ v2: CGVector) -> CGFloat {
        
        return atan2(v1.dy - v2.dy, v1.dx - v2.dx)
    }
}

extension CGPoint {
    
    public static func make(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        
        return self.init(x: x, y: y)
    }
    
    public static func arcPoint(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        
        let dx = radius * cos(angle)
        let dy = radius * sin(angle)
        return center.moveBy(dx, dy)
    }
    
    public static func midPos(_ pos0: CGPoint, _ pos1: CGPoint) -> CGPoint {
    
        return CGPoint.init(x: (pos0.x + pos1.x)/2, y: (pos0.y + pos1.y)/2)
    }
    
    public func moveBy(_ dx: CGFloat, _ dy: CGFloat) -> CGPoint {
        
        return CGPoint.init(x: self.x + dx, y: self.y + dy)
    }
    
    public func moveBy(_ vector: CGVector) -> CGPoint {
        
        return self.moveBy(vector.dx, vector.dy)
    }

    public static func + (lhs: CGPoint, rhs: CGVector) -> CGPoint {
        
        return CGPoint.init(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
    }
    
    public static func += (lhs: inout CGPoint, rhs: CGVector) {

        lhs.x += rhs.dx
        lhs.y += rhs.dy
    }
    
    public static func -= (lhs: inout CGPoint, rhs: CGVector) {
        
        lhs.x -= rhs.dx
        lhs.y -= rhs.dy
    }
    
    public static func - (lhs: CGPoint, rhs: CGVector) -> CGPoint {
        
        return lhs + (-rhs)
    }
    
    public static func - (lhs: CGPoint, rhs: CGPoint) -> CGVector {
        
        return CGVector.init(dx: lhs.x - rhs.x, dy: lhs.y - rhs.y)
    }
    
    public func test(inPolygon points: [CGPoint]) -> Bool {
        let nCount = points.count
        assert(nCount >= 3)
        
        var nCross = 0
        for i in 0..<nCount {
            
            let p1 = points[i]
            let p2 = points[(i + 1)%nCount]
            
            if p1.y == p2.y {
                continue
            }
            if self.y < min(p1.y, p2.y) {
                continue
            }
            if self.y >= max(p1.y, p2.y) {
                continue
            }
            
            let x = (self.y - p1.y) * (p2.x - p1.x) / (p2.y - p1.y) + p1.x
            
            if x > self.x {
                nCross += 1
            }
        }
        return nCross%2 == 1
    }
    
}


extension CGColor {
    
    static public func RGBHex(_ hex: Int) -> CGColor {
        
        let r = (hex >> 16) & 0xFF
        let g = (hex >> 8) & 0xFF
        let b = (hex) & 0xFF
        return CGColor.init(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [CGFloat(r) / 255, CGFloat(g) / 255, CGFloat(b) / 255, 1.0])!
    }
    
    static public func ARGBHex(_ hex: Int64) -> CGColor {
        let r = (hex >> 16) & 0xFF
        let g = (hex >> 8) & 0xFF
        let b = (hex) & 0xFF
        let a = (hex >> 24) & 0xFF
        return CGColor.init(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [CGFloat(r) / 255, CGFloat(g) / 255, CGFloat(b) / 255, CGFloat(a) / 255])!
    }
    
    static public func RGBAHex(_ hex: Int64) -> CGColor {
        
        let r = (hex >> 24) & 0xFF;
        let g = (hex >> 16) & 0xFF;
        let b = (hex >> 8) & 0xFF;
        let a = (hex) & 0xFF;
        return CGColor.init(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [CGFloat(r) / 255, CGFloat(g) / 255, CGFloat(b) / 255, CGFloat(a) / 255])!
    }
    
}

extension CGFloat {
    
    static public func random0_1() -> CGFloat {
        
        return CGFloat.random(in: ClosedRange<CGFloat>.init(uncheckedBounds: (lower: 0, upper: 1)))
    }
    
    static public func randomBetween(min: CGFloat, max: CGFloat) -> CGFloat {
        
        return CGFloat.random(in: ClosedRange<CGFloat>.init(uncheckedBounds: (lower: min, upper: max)))
    }
    
    static public func randomRadian() -> CGFloat {
        
        return 2.0 * .pi * random0_1()
    }
    
    static public func degressToRadian(_ degress: CGFloat) -> CGFloat {
        
        return degress/720 * CGFloat.pi
    }
    
    public func string(withDigitRetain digit: UInt, trimZero: Bool = false) -> String {
        
        var string = String.init(format: "%.\(digit)f", self)
        if !trimZero || digit == 0 {
            return string
        }
        while true {
            let last = string.last!
            if last != "0" {
                if last == "." {
                    string.removeLast()
                }
                break
            }
            string.removeLast()
        }
        return string
    }
}

