//
//  SegementSlideContentView.swift
//  SegementSlide
//
//  Created by Jiar on 2018/12/7.
//  Copyright © 2018 Jiar. All rights reserved.
//

import UIKit

@objc public protocol SegementSlideContentScrollViewDelegate where Self: UIViewController {
    /// must implement this variable, when use class `SegementSlideViewController` or it's subClass.
    /// you can ignore this variable, when you use `SegementSlideContentView` alone.
    @objc optional var scrollView: UIScrollView { get }
}

public protocol SegementSlideContentDelegate: class {
    
    var segementSlideContentScrollViewCount: Int { get }
    
    func segementSlideContentScrollView(at index: Int) -> SegementSlideContentScrollViewDelegate?
   
    func segementSlideContentView(_ segementSlideContentView: SegementSlideContentView, didSelectAtIndex index: Int, animated: Bool)
    
    func segementSlideContentView(_ segmentSlideContentView: SegementSlideContentView, didScroll progress: CGFloat, currentPage: Int, nexPage: Int)
}

public class SegementSlideContentView: UIView {
    
    private let scrollView = UIScrollView()
    private var viewControllers: [Int: SegementSlideContentScrollViewDelegate] = [:]
    private var initSelectedIndex: Int?
    private var segementContentScrollKeyValueObservation: NSKeyValueObservation?
    
    public private(set) var selectedIndex: Int?
    public weak var delegate: SegementSlideContentDelegate?
    public weak var viewController: UIViewController?
    
    internal var isObserving: Bool = false
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    deinit {
        segementContentScrollKeyValueObservation?.invalidate()
        segementContentScrollKeyValueObservation = nil
        debugPrint("xxx\(type(of: self)) deinit")
    }
    
    private func setup() {
        addSubview(scrollView)
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        scrollView.constraintToSuperview()
        scrollView.delegate = self
        scrollView.isScrollEnabled = true
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        backgroundColor = .white
        
        self.segementContentScrollKeyValueObservation = self.scrollView.observe(\.contentOffset, options: [.new, .old], changeHandler: { [weak self] (scrollView, change) in
            guard let sSelf = self, sSelf.isObserving else { return }
            sSelf.contentViewScrollViewDidScroll(scrollView: scrollView, change: change)
        })
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateScrollViewContentSize()
        layoutViewControllers()
        recoverInitSelectedIndex()
    }
    
    public override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if let _ = newWindow {
            isObserving = true
        } else {
            isObserving = false
        }
    }
    
    /// remove subViews
    ///
    /// you should call `scrollToSlide(at index: Int, animated: Bool)` after call the method.
    /// otherwise, none of them will be selected.
    /// However, if an item was previously selected, it will be reSelected.
    public func reloadData() {
        removeViewControllers()
        updateScrollViewContentSize()
        guard let selectedIndex = selectedIndex else { return }
        updateSelectedViewController(at: selectedIndex, animated: false)
    }
    
    /// select one item by index
    public func scrollToSlide(at index: Int, animated: Bool) {
        updateSelectedViewController(at: index, animated: animated)
    }
    
    /// reuse the `SegementSlideContentScrollViewDelegate`
    public func dequeueReusableViewController(at index: Int) -> SegementSlideContentScrollViewDelegate? {
        if let childViewController = viewControllers[index] {
            return childViewController
        } else {
            return nil
        }
    }
    
}

extension SegementSlideContentView: UIScrollViewDelegate {

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate { return }
        scrollViewDidEndScroll(scrollView)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDidEndScroll(scrollView)
    }

    private func scrollViewDidEndScroll(_ scrollView: UIScrollView) {
        let indexFloat = scrollView.contentOffset.x/scrollView.bounds.width
        guard !indexFloat.isNaN, indexFloat.isFinite else { return }
        let index = Int(indexFloat)
        updateSelectedViewController(at: index, animated: true)
    }

}

extension SegementSlideContentView {
    
    private func updateScrollViewContentSize() {
        guard let count = delegate?.segementSlideContentScrollViewCount else { return }
        let contentSize = CGSize(width: CGFloat(count)*scrollView.bounds.width, height: scrollView.bounds.height)
        guard scrollView.contentSize != contentSize else { return }
        scrollView.contentSize = contentSize
    }
    
    private func removeViewControllers() {
        for (_, value) in viewControllers {
            value.view.removeFromSuperview()
            value.removeFromParent()
        }
        viewControllers.removeAll()
    }
    
    private func layoutViewControllers() {
        for (index, value) in viewControllers {
            let offsetX = CGFloat(index)*scrollView.bounds.width
            value.view.widthConstraint?.constant = scrollView.bounds.width
            value.view.heightConstraint?.constant = scrollView.bounds.height
            value.view.leadingConstraint?.constant = offsetX
        }
    }
    
    private func recoverInitSelectedIndex() {
        guard let initSelectedIndex = initSelectedIndex else { return }
        self.initSelectedIndex = nil
        updateSelectedViewController(at: initSelectedIndex, animated: false)
    }
    
    private func segementSlideContentViewController(at index: Int) -> SegementSlideContentScrollViewDelegate? {
        if let childViewController = dequeueReusableViewController(at: index) {
            return childViewController
        } else if let childViewController = delegate?.segementSlideContentScrollView(at: index) {
            viewControllers[index] = childViewController
            return childViewController
        }
        return nil
    }
    
    private func updateSelectedViewController(at index: Int, animated: Bool) {
        guard isObserving else { return }
        
        guard scrollView.frame != .zero else {
            initSelectedIndex = index
            return
        }
        guard index != selectedIndex,
            let viewController = viewController,
            let count = delegate?.segementSlideContentScrollViewCount,
            count != 0, index >= 0, index < count else {
            return
        }
        if let lastIndex = selectedIndex, let lastChildViewController = segementSlideContentViewController(at: lastIndex) {
            lastChildViewController.beginAppearanceTransition(false, animated: animated)
        }
        guard let childViewController = segementSlideContentViewController(at: index) else { return }
        let isAdded = childViewController.view.superview != nil
        if isAdded {
            childViewController.beginAppearanceTransition(true, animated: animated)
        } else {
            viewController.addChild(childViewController)
            scrollView.addSubview(childViewController.view)
        }
        let offsetX = CGFloat(index)*scrollView.bounds.width
        childViewController.view.translatesAutoresizingMaskIntoConstraints = false
        childViewController.view.topConstraint = childViewController.view.topAnchor.constraint(equalTo: scrollView.topAnchor)
        childViewController.view.widthConstraint = childViewController.view.widthAnchor.constraint(equalToConstant: scrollView.bounds.width)
        childViewController.view.heightConstraint = childViewController.view.heightAnchor.constraint(equalToConstant: scrollView.bounds.height)
        childViewController.view.leadingConstraint = childViewController.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: offsetX)
        scrollView.setContentOffset(CGPoint(x: offsetX, y: scrollView.contentOffset.y), animated: animated)
        if let lastIndex = selectedIndex, let lastChildViewController = segementSlideContentViewController(at: lastIndex) {
            lastChildViewController.endAppearanceTransition()
        }
        if isAdded {
            childViewController.endAppearanceTransition()
        }
        selectedIndex = index
        delegate?.segementSlideContentView(self, didSelectAtIndex: index, animated: animated)
    }
    
}


extension SegementSlideContentView {
    
    func contentViewScrollViewDidScroll(scrollView: UIScrollView, change: NSKeyValueObservedChange<CGPoint>) {
        
        guard let newValue = change.newValue?.x, let oldValue = change.oldValue?.x else {
            return
        }
        
        guard scrollView.contentOffset.x > 0, scrollView.contentOffset.x < scrollView.contentSize.width else {
            return
        }
        
        let floatIndex = scrollView.contentOffset.x/(scrollView.bounds.width)
        
        let progress = scrollView.contentOffset.x.truncatingRemainder(dividingBy: scrollView.bounds.width)
        let rotio = progress / scrollView.bounds.width
        
        var currentPage: Int = 0
        var nextPage: Int = 1
        if newValue > oldValue {
            // 右滑
            nextPage = min(Int(scrollView.contentSize.width/scrollView.bounds.width), Int(floatIndex) + 1)
            currentPage = Int(floatIndex)

        } else {
            // 左滑
            nextPage = max(0, Int(floatIndex))
            currentPage = min(Int(scrollView.contentSize.width/scrollView.bounds.width), Int(floatIndex) + 1)
        }
    
        delegate?.segementSlideContentView(self, didScroll: rotio, currentPage: currentPage, nexPage: nextPage)
    }
}
