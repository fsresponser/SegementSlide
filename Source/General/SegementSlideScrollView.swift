//
//  SegementSlideScrollView.swift
//  SegementSlide
//
//  Created by Jiar on 2019/1/16.
//  Copyright © 2019 Jiar. All rights reserved.
//

import UIKit

protocol SegementSlideScrollViewDelegate: class {
    
    func segementSlideScrollView(didScroll scrollView: SegementSlideScrollView)
}

internal class SegementSlideScrollView: UIScrollView, UIGestureRecognizerDelegate {
    
    weak var slideScrollViewDelegate: SegementSlideScrollViewDelegate?
    
    override var contentOffset: CGPoint {
        didSet {
            guard contentOffset != oldValue else { return }
            slideScrollViewDelegate?.segementSlideScrollView(didScroll: self)
        }
    }
    
    private var otherGestureRecognizers: [UIGestureRecognizer]?
    
    internal init(otherGestureRecognizers: [UIGestureRecognizer]? = nil) {
        self.otherGestureRecognizers = otherGestureRecognizers
        super.init(frame: .zero)
    }
    
    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let otherGestureRecognizers = otherGestureRecognizers, otherGestureRecognizers.contains(otherGestureRecognizer) {
            return false
        }
        return true
    }
    
}
