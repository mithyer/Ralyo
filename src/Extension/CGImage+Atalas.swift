//
//  CGImage+Ralyo.swift
//  Circul
//
//  Created by ray on 2019/1/17.
//  Copyright © 2019年 actufo. All rights reserved.
//

import Foundation
import CoreImage

extension CGImage {
    
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
        
        public init(fileName: String, scale: CGFloat) {
            
            let path = Bundle.main.path(forResource: "\(fileName).atlasc/\(fileName)", ofType: "plist")!
            let atalsData = try! Data.init(contentsOf: URL.init(fileURLWithPath: path), options: [.mappedIfSafe, .uncached])
            let atals = try! PropertyListDecoder().decode(Atalas.self, from: atalsData)
            
            for group in atals.images {
                
                let imgPath = group.path as NSString
                let imgFile = (imgPath.lastPathComponent as NSString).deletingPathExtension
                let imgExtension = imgPath.pathExtension
                let path = Bundle.main.path(forResource: "\(fileName).atlasc/\(imgFile)", ofType: imgExtension)!
                let data = try! Data.init(contentsOf: URL.init(fileURLWithPath: path), options: [.mappedIfSafe, .uncached])
                let imgSource = CIImage.init(data: data)!

                let context = CIContext()
                let subimages = group.subimages!
                for info in subimages {
                    
                    let sourceSize = NSCoder.cgSize(for: info.spriteSourceSize)
                    let offset = NSCoder.cgPoint(for: info.spriteOffset)
                    var textureRect = NSCoder.cgRect(for: info.textureRect)
                    textureRect.origin.y = imgSource.extent.height - textureRect.maxY
                    let rotated = info.textureRotated!
                    let name = (info.name as NSString).deletingPathExtension
                    let img: CIImage = imgSource.cropped(to: textureRect)
                    var cgImg = context.createCGImage(img, from: img.extent)!
                    
                    if rotated {
                        let context = CGContext.init(data: nil, width: Int(textureRect.height), height: Int(textureRect.width), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)!
                        context.translateBy(x: textureRect.height/2, y: textureRect.width/2)
                        context.rotate(by: CGFloat.pi/2)
                        context.draw(cgImg, in: CGRect.init(x: -textureRect.width/2, y: -textureRect.height/2, width: textureRect.width, height: textureRect.height))
                        cgImg = context.makeImage()!
                    }

                    let context = CGContext.init(data: nil, width: Int(sourceSize.width * scale), height: Int(sourceSize.height * scale), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)!
                    context.draw(cgImg, in: CGRect.init(x: offset.x * scale, y: offset.y * scale, width: (rotated ? textureRect.height : textureRect.width) * scale, height: (rotated ? textureRect.width : textureRect.height) * scale))
                    cgImg = context.makeImage()!
 
                    self.imageDic[name] = cgImg
                }
            }
        }
        
        public func image(forName name: String) -> CGImage? {
            let img = self.imageDic[name]
            return img
        }
    }
    
    
    
}
