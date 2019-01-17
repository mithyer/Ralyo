//
//  CGImage+Ralyo.swift
//  Circul
//
//  Created by ray on 2019/1/17.
//  Copyright © 2019年 actufo. All rights reserved.
//

import Foundation
import CoreImage
import UIKit

extension CIImage {
    
    public class AtalasUnarchiver {
        
        struct Atalas: Decodable {
            
            var version: Int!
            var format: String!
            var images: [ImageInfoGroup]!
            
            struct ImageInfoGroup: Decodable {
                
                var path: String!
                var size: String!
                var subimages: [ImageInfo]!
                
                struct ImageInfo: Decodable {
                    
                    var spriteSourceSize: String!
                    var isFullyOpaque: Bool!
                    var textureRect: String!
                    var spriteOffset: String!
                    var name: String!
                    var textureRotated: Bool!
                }
            }
        }
        
        private lazy var imageDic = [String: CGImage]()
        
        public init(fileName: String) {
            
            let path = Bundle.main.path(forResource: "\(fileName).atlasc/\(fileName)", ofType: "plist")!
            let atalsData = try! Data.init(contentsOf: URL.init(fileURLWithPath: path), options: [.mappedIfSafe, .uncached])
            let atals = try! PropertyListDecoder().decode(Atalas.self, from: atalsData)
            
            for group in atals.images {
                
                let imgPath = group.path as NSString
                let imgFile = (imgPath.lastPathComponent as NSString).deletingPathExtension
                let imgExtension = imgPath.pathExtension
                let path = Bundle.main.path(forResource: "\(fileName).atlasc/\(imgFile)", ofType: imgExtension)!
                let data = try! Data.init(contentsOf: URL.init(fileURLWithPath: path), options: [.mappedIfSafe, .uncached])
                let ciImg = CIImage.init(data: data, options: [CIImageOption.colorSpace : CGColorSpaceCreateDeviceRGB()])!
                ciImg.clampedToExtent()

                let context = CIContext()
                let subimages = group.subimages!
                for info in subimages {
                    
                    let sourceSize = NSCoder.cgSize(for: info.spriteSourceSize)
                    let offset = NSCoder.cgPoint(for: info.spriteOffset)
                    let textureRect = NSCoder.cgRect(for: info.textureRect)
                    let rotated = info.textureRotated!
                    let name = (info.name as NSString).deletingPathExtension
                    
                    var img = ciImg.cropped(to: textureRect)
                    if rotated {
                        img = img.oriented(forExifOrientation: Int32(CGImagePropertyOrientation.left.rawValue))
                    }
                    if offset.x > 0 || offset.y > 0 {
                        img = img.cropped(to: CGRect.init(x: -offset.x, y: -offset.y, width: sourceSize.width, height: sourceSize.height))
                    }
                    self.imageDic[name] = context.createCGImage(ciImg, from: img.extent)
                }
            }
            print(self.imageDic.keys)
        }
        
        public func image(forName name: String) -> CGImage? {
            let img = self.imageDic[name]
            return img
        }
    }
    
    
    
}
