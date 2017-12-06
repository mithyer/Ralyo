//
//  RefreshDisplay.swift
//  CTShow
//
//  Created by ray on 2018/11/15.
//  Copyright © 2018年 ray. All rights reserved.
//

import UIKit


public class DefaultRefreshDisplay: RefreshDisplayProtocol {
    
    public lazy var indicator: UIActivityIndicatorView = {
        
        let indicator = UIActivityIndicatorView.init(style: .gray)
        indicator.hidesWhenStopped = false
        indicator.layer.opacity = 0
        return indicator
    }()
    
    private let fadeAnimationKey = "fadeAnimationKey"
    private lazy var fadeAnimation: CABasicAnimation = {
        
        let animation = CABasicAnimation.init(keyPath: "opacity")
        animation.fromValue = 1
        animation.toValue = 0
        animation.duration = 0.25
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false
        return animation
    }()

    public required init(scrollView: UIScrollView, preferCenter: CGPoint) {
        
        scrollView.addSubview(self.indicator)
        self.indicator.center = preferCenter
    }
    
    public func didStartDrag(scrollView: UIScrollView) {
        indicator.layer.removeAnimation(forKey: fadeAnimationKey)
        indicator.layer.opacity = 1
    }
    
    public func isDragging(scrollView: UIScrollView) {

        self.indicator.layer.setAffineTransform(self.indicator.layer.affineTransform().rotated(by: CGFloat.pi/90))
    }
    
    public func didStartRefresh(scrollView: UIScrollView) {
        
        indicator.layer.opacity = 1
        self.indicator.startAnimating()
    }
    
    public func didEndRefresh(scrollView: UIScrollView) {
        self.indicator.stopAnimating()
        self.indicator.layer.removeAnimation(forKey: fadeAnimationKey)
        self.indicator.layer.add(self.fadeAnimation, forKey: fadeAnimationKey)
    }
    
}
