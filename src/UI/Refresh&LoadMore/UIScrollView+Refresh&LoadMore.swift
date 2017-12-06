//
//  UIScrollView+Refresh.swift
//  CTShow
//
//  Created by ray on 2018/11/14.
//  Copyright © 2018年 ray. All rights reserved.
//

import UIKit


public protocol RefreshDisplayProtocol {
    
    init(scrollView: UIScrollView, preferCenter: CGPoint)
    func didStartDrag(scrollView: UIScrollView)
    func isDragging(scrollView: UIScrollView)
    func didStartRefresh(scrollView: UIScrollView)
    func didEndRefresh(scrollView: UIScrollView)
}

public protocol RefreshDelegate: class {
    
    func didBeginRefresh(scrollView: UIScrollView, stopRefresh: @escaping () -> Void)
}

public protocol LoadMoreDelegate: class {
    
    func shouldBeginLoadMore(scrollView: UIScrollView) -> Bool
    func didBeginLoadMore(scrollView: UIScrollView, stopLoadMore: @escaping () -> Void)
}

public extension UIScrollView {

    class Refresh {
        
        private var scrollViewAddress: Int?
        fileprivate weak var scrollView: UIScrollView?
        
        private var contentInsets: UIEdgeInsets!
        public private(set) var isRefreshing = false
        private let maxDragY: CGFloat = 50
        
        private var refreshDisplayType: RefreshDisplayProtocol.Type?
        public func registerRefreshDisplay(type: RefreshDisplayProtocol.Type) {
            self._display = nil
            self.refreshDisplayType = type
        }
        
        public var didBegin: ((_ isPull: Bool, _ stopRefresh: @escaping () -> Void) -> Void)?
        public weak var delegate: RefreshDelegate?
        
        var _display: RefreshDisplayProtocol?
        public var display: RefreshDisplayProtocol? {
            if let display = _display {
                return display
            }
            guard let scrollView = self.scrollView else {
                return nil
            }
            let type = self.refreshDisplayType ?? DefaultRefreshDisplay.self
            _display = type.init(scrollView: scrollView, preferCenter: CGPoint.init(x: scrollView.bounds.midX, y: -maxDragY/2))
            return _display!
        }
        
        private func _trigger(isPull: Bool) {
            
            guard let scrollView = self.scrollView, !self.isRefreshing else {
                return
            }
            self.contentInsets = scrollView.contentInset
            UIView.animate(withDuration: 0.5, delay: 0, options: [.beginFromCurrentState, .overrideInheritedDuration], animations: {
                scrollView.contentInset = UIEdgeInsets.init(top: self.contentInsets.top + self.maxDragY, left: self.contentInsets.left, bottom: self.contentInsets.bottom, right: self.contentInsets.right)
            })
            self.isRefreshing = true
            self.display?.didStartRefresh(scrollView: scrollView)
            self.didBegin?(isPull, self.stop)
            self.delegate?.didBeginRefresh(scrollView: scrollView, stopRefresh: self.stop)
        }
        
        public func trigger() {
            self._trigger(isPull: false)
        }
        
        public func stop() {
            
            guard let scrollView = self.scrollView, self.isRefreshing else {
                return
            }
            UIView.animate(withDuration: 0.5, delay: 0, options: [.beginFromCurrentState, .overrideInheritedDuration], animations: {
                scrollView.contentInset = UIEdgeInsets.init(top: self.contentInsets.top + self.maxDragY, left: self.contentInsets.left, bottom: self.contentInsets.bottom, right: self.contentInsets.right)
            }) { finished in
                if finished {
                    UIView.animate(withDuration: 0.5, delay: 0.5, options: [.beginFromCurrentState], animations: {
                        scrollView.contentInset = self.contentInsets
                    }) { _ in
                        self.display?.didEndRefresh(scrollView: scrollView)
                    }
                } else {
                    self.display?.didEndRefresh(scrollView: scrollView)
                }
            }
            
            self.isRefreshing = false
        }
        
        fileprivate func updateWhenDragging() {
            
            guard let scrollView = self.scrollView, scrollView.isTracking, !self.isRefreshing, scrollView.contentOffset.y < -scrollView.contentInset.top else {
                return
            }
            self.display?.isDragging(scrollView: scrollView)
    
        }
        
        fileprivate func startDragging() {
            guard let scrollView = self.scrollView else {
                return
            }
            self.display?.didStartDrag(scrollView: scrollView)
        }
        
        fileprivate func checkWhenEndDragging() {
            guard let scrollView = self.scrollView, !self.isRefreshing else {
                return
            }
            let offsetLimit: CGFloat = maxDragY + scrollView.contentInset.top
            if scrollView.contentOffset.y < -offsetLimit {
                self._trigger(isPull: true)
            } else {
                self.display?.didEndRefresh(scrollView: scrollView)
            }
        }
    
    }

    class LoadMore {
        
        public private(set) var isLoadingMore = false
        fileprivate weak var scrollView: UIScrollView?
        
        public var shouldBegin: (() -> Bool)?
        public var didBegin: ((_ stopLoadMore: @escaping () -> Void) -> Void)?
        public weak var delegate: LoadMoreDelegate?

        fileprivate func check() {
            
            guard let scrollView = self.scrollView, !self.isLoadingMore, (scrollView.isDecelerating || scrollView.isTracking), (self.shouldBegin?() ?? self.delegate?.shouldBeginLoadMore(scrollView: scrollView) ?? false) else {
                return
            }
            let offset = scrollView.contentOffset
            let maxY = scrollView.contentSize.height - scrollView.bounds.height
            if maxY - offset.y < 20 || offset.y >= scrollView.contentSize.height/2 {
                self.isLoadingMore = true
                self.didBegin?(self.stop)
                self.delegate?.didBeginLoadMore(scrollView: scrollView, stopLoadMore: self.stop)
            }
        }
        
        public func stop() {
            
            guard let _ = self.scrollView, self.isLoadingMore else {
                return
            }
            self.isLoadingMore = false
        }
        
    }
    
    private class RefreshAndLoadMore: NSObject {
        
        static fileprivate var observeContext: Void?
        static fileprivate let contentOffsetPath = "contentOffset"
        static fileprivate let panStatePath = "pan.state"

        fileprivate var loadMore: LoadMore!
        fileprivate var refresh: Refresh!

        
        init(scrollView: UIScrollView) {
            
            super.init()
            self.refresh = Refresh()
            self.loadMore = LoadMore()
            self.refresh.scrollView = scrollView
            self.loadMore.scrollView = scrollView
            scrollView.addObserver(self, forKeyPath: RefreshAndLoadMore.contentOffsetPath, options: [], context: &RefreshAndLoadMore.observeContext)
            scrollView.addObserver(self, forKeyPath: RefreshAndLoadMore.panStatePath, options: [.new], context: &RefreshAndLoadMore.observeContext)
            
        }

        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            
            switch keyPath! {
            case RefreshAndLoadMore.contentOffsetPath:
                refresh.updateWhenDragging()
                loadMore.check()
            case RefreshAndLoadMore.panStatePath:
                let state = change?[.newKey] as! Int
                switch state {
                case UIGestureRecognizer.State.ended.rawValue:
                    refresh.checkWhenEndDragging()
                case UIGestureRecognizer.State.began.rawValue:
                    refresh.startDragging()
                default:
                    break
                }
            default:
                console_assertFailure()
            }
        }
    }
    
    private static var refreshAndLoadMoreKey: Void?
    private var refreshAndLoadMore: RefreshAndLoadMore {
        return objc_getAssociatedObject(self, &UIScrollView.refreshAndLoadMoreKey) as? RefreshAndLoadMore ?? {
            let refreshAndLoadMore = RefreshAndLoadMore.init(scrollView: self)
            objc_setAssociatedObject(self, &UIScrollView.refreshAndLoadMoreKey, refreshAndLoadMore, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return refreshAndLoadMore
        }()
    }
    
    public var refresh: Refresh {
        return self.refreshAndLoadMore.refresh
    }
    
    public var loadMore: LoadMore {
        return self.refreshAndLoadMore.loadMore
    }
    
    public func removeRefreshAndLoadMoreObserver() {
        if let rl = objc_getAssociatedObject(self, &UIScrollView.refreshAndLoadMoreKey) as? RefreshAndLoadMore {
            objc_setAssociatedObject(self, &UIScrollView.refreshAndLoadMoreKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.removeObserver(rl, forKeyPath: RefreshAndLoadMore.contentOffsetPath, context: &RefreshAndLoadMore.observeContext)
            self.removeObserver(rl, forKeyPath: RefreshAndLoadMore.panStatePath, context: &RefreshAndLoadMore.observeContext)
        }
    }
}
