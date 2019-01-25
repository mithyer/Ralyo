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
        
        let atals: Atalas
        private lazy var imageDic = [String: (CIImage, Atalas.ImageInfoGroup.ImageInfo)]()
        public let fileName: String
        private let scale: CGFloat
        
        public init(fileName: String, scale: CGFloat) {
            
            let path = Bundle.main.path(forResource: "\(fileName).atlasc/\(fileName)", ofType: "plist")!
            let atalsData = try! Data.init(contentsOf: URL.init(fileURLWithPath: path), options: [.mappedIfSafe, .uncached])
            self.atals = try! PropertyListDecoder().decode(Atalas.self, from: atalsData)
            self.fileName = fileName
            self.scale = scale
            
            for group in atals.images {
                
                let imgPath = group.path as NSString
                let imgFile = (imgPath.lastPathComponent as NSString).deletingPathExtension
                let imgExtension = imgPath.pathExtension
                let path = Bundle.main.path(forResource: "\(fileName).atlasc/\(imgFile)", ofType: imgExtension)!
                let data = try! Data.init(contentsOf: URL.init(fileURLWithPath: path), options: [.mappedIfSafe, .uncached])
                let imgSource = CIImage.init(data: data)!
                
                let subimages = group.subimages!
                
                for info in subimages {
                    var textureRect = NSCoder.cgRect(for: info.textureRect)
                    textureRect.origin.y = imgSource.extent.height - textureRect.maxY
                    let rotated = info.textureRotated!
                    let name = (info.name as NSString).deletingPathExtension
                    var img: CIImage = imgSource.cropped(to: textureRect)
                    if rotated {
                        img = img.oriented(forExifOrientation: Int32(CGImagePropertyOrientation.left.rawValue))
                    }
                    self.imageDic[name] = (img, info)
                }
            }
        }
        
        static func createCGImage(ciImg: CIImage, info: Atalas.ImageInfoGroup.ImageInfo, scale: CGFloat) -> CGImage {
            
            struct const {
                static let ciContext = CIContext()
            }
            
            let ciContext = const.ciContext
            let sourceSize = NSCoder.cgSize(for: info.spriteSourceSize)
            let offset = NSCoder.cgPoint(for: info.spriteOffset)
            let rotated = info.textureRotated!
            let textureRect = NSCoder.cgRect(for: info.textureRect)
            
            var cgImg = ciContext.createCGImage(ciImg, from: ciImg.extent)!
            let context = CGContext.init(data: nil, width: Int(sourceSize.width * scale), height: Int(sourceSize.height * scale), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)!
            context.draw(cgImg, in: CGRect.init(x: offset.x * scale, y: offset.y * scale, width: (rotated ? textureRect.height : textureRect.width) * scale, height: (rotated ? textureRect.width : textureRect.height) * scale))
            cgImg = context.makeImage()!
            
            return cgImg
        }
        
        public func load(byNames names: [String], async: Bool, _ completed: @escaping ([String: CGImage]?) -> Void) {

            let block = {
                var cgImgDic = [String: CGImage]()
                for name in names {
                    guard let (ciImg, info) = self.imageDic[name] else {
                        continue
                    }
                    let img = AtalasUnarchiver.createCGImage(ciImg: ciImg, info: info, scale: self.scale)
                    cgImgDic[name] = img
                }
                completed(cgImgDic)
            }
            if async {
                DispatchQueue.global().async(execute: block)
            } else {
                block()
            }
        }
        
        public func loadAll(async: Bool, _ completed: @escaping ([String: CGImage]?) -> Void) {
            let names = [String](self.imageDic.keys)
            self.load(byNames: names, async: async, completed)
        }
        
        public func load(byName name: String, async: Bool, _ completed: @escaping (CGImage?) -> Void) {
            self.load(byNames: [name], async: async) { dic in
                completed(dic?[name])
            }
        }

    }
    
    
    
}
