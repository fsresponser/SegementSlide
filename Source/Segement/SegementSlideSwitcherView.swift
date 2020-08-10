//
//  SegementSlideSwitcherView.swift
//  SegementSlide
//
//  Created by Jiar on 2018/12/7.
//  Copyright © 2018 Jiar. All rights reserved.
//

import UIKit

public enum SwitcherType {
    case tab
    case segement
}

public protocol SegementSlideSwitcherViewDelegate: class {
    var titlesInSegementSlideSwitcherView: [String] { get }
    
    func segementSwitcherView(_ segementSlideSwitcherView: SegementSlideSwitcherView, didSelectAtIndex index: Int, animated: Bool)
    func segementSwitcherView(_ segementSlideSwitcherView: SegementSlideSwitcherView, showBadgeAtIndex index: Int) -> BadgeType
}

public class SegementSlideSwitcherView: UIView {
    
    private let scrollView = UIScrollView()
    private let indicatorView = UIView()
    private var titleButtons: [UIButton] = []
    private var initSelectedIndex: Int?
    private var innerConfig: SegementSlideSwitcherConfig = SegementSlideSwitcherConfig.shared
    internal var gestureRecognizersInScrollView: [UIGestureRecognizer]? {
        return scrollView.gestureRecognizers
    }
    
    public private(set) var selectedIndex: Int?
    public weak var delegate: SegementSlideSwitcherViewDelegate?
    
    /// you must call `reloadData()` to make it work, after the assignment.
    public var config: SegementSlideSwitcherConfig = SegementSlideSwitcherConfig.shared
    
    private var isClicking: Bool = false
    
    private let scaleIncrement: CGFloat = 1.0 / 3.0
    
    private lazy var indicatorFrame: CGRect = {
        /// 存储最初indicator的位置信息
        guard let titleButton = self.titleButtons.first else { return CGRect.zero }
        return CGRect(x: titleButton.center.x-(self.innerConfig.indicatorWidth)/2, y: self.frame.height-self.innerConfig.indicatorHeight, width: self.innerConfig.indicatorWidth, height: self.innerConfig.indicatorHeight)
    }()
    
    public override var intrinsicContentSize: CGSize {
        return scrollView.contentSize
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        addSubview(scrollView)
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        scrollView.constraintToSuperview()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        backgroundColor = .white
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutTitleButtons()
        reloadBadges()
        recoverInitSelectedIndex()
    }
    
    /// relayout subViews
    ///
    /// you should call `selectSwitcher(at index: Int, animated: Bool)` after call the method.
    /// otherwise, none of them will be selected.
    /// However, if an item was previously selected, it will be reSelected.
    public func reloadData() {
        for titleButton in titleButtons {
            titleButton.removeFromSuperview()
            titleButton.frame = .zero
        }
        titleButtons.removeAll()
        indicatorView.removeFromSuperview()
        indicatorView.frame = .zero
        scrollView.isScrollEnabled = innerConfig.type == .segement
        innerConfig = config
        guard let titles = delegate?.titlesInSegementSlideSwitcherView else { return }
        guard !titles.isEmpty else { return }
        for (index, title) in titles.enumerated() {
            let button = UIButton(type: .custom)
            button.clipsToBounds = false
            button.titleLabel?.font = innerConfig.normalTitleFont
            button.backgroundColor = .clear
            button.setTitle(title, for: .normal)
            button.tag = index
            button.setTitleColor(innerConfig.normalTitleColor, for: .normal)
            button.addTarget(self, action: #selector(didClickTitleButton), for: .touchUpInside)
            scrollView.addSubview(button)
            titleButtons.append(button)
        }
        guard !titleButtons.isEmpty else { return }
        scrollView.addSubview(indicatorView)
        if config.isCapIndicator {
            indicatorView.layer.masksToBounds = true
            indicatorView.layer.cornerRadius = innerConfig.indicatorHeight/2            
        }
        indicatorView.backgroundColor = innerConfig.indicatorColor
        layoutTitleButtons()
        reloadBadges()
        guard let selectedIndex = selectedIndex else { return }
        updateSelectedButton(at: selectedIndex, animated: false)
    }
    
    /// reload all badges in `SegementSlideSwitcherView`
    public func reloadBadges() {
        for (index, titleButton) in titleButtons.enumerated() {
            guard let type = delegate?.segementSwitcherView(self, showBadgeAtIndex: index) else {
                titleButton.badge.type = .none
                continue
            }
            titleButton.badge.type = type
            if case .none = type {
                continue
            }
            let titleLabelText = titleButton.titleLabel?.text ?? ""
            let width: CGFloat
            if selectedIndex == index {
                width = titleLabelText.boundingWidth(with: innerConfig.selectedTitleFont)
            } else {
                width = titleLabelText.boundingWidth(with: innerConfig.normalTitleFont)
            }
            let height = titleButton.titleLabel?.font.lineHeight ?? titleButton.bounds.height
            switch type {
            case .count:
                titleButton.badge.height = innerConfig.badgeHeightForCountType
                titleButton.badge.fontSize = innerConfig.badgeFontSize
                titleButton.badge.offset = CGPoint(x: width/2+titleButton.badge.height/2, y: -height/2)
            case .point:
                titleButton.badge.height = innerConfig.badgeHeightForPointType
                titleButton.badge.offset = CGPoint(x: width/2+titleButton.badge.height/2, y: -height/2)
            case .none:
                break
            }
        }
    }
    
    /// select one item by index
    public func selectSwitcher(at index: Int, animated: Bool) {
        updateSelectedButton(at: index, animated: animated)
    }
    
}

extension SegementSlideSwitcherView {
    
    private func recoverInitSelectedIndex() {
        guard let initSelectedIndex = initSelectedIndex else { return }
        self.initSelectedIndex = nil
        updateSelectedButton(at: initSelectedIndex, animated: false)
    }
    
    private func layoutTitleButtons() {
        guard scrollView.frame != .zero else { return }
        guard !titleButtons.isEmpty else {
            scrollView.contentSize = CGSize(width: bounds.width, height: bounds.height)
            return
        }
        var offsetX = innerConfig.horizontalMargin
        for titleButton in titleButtons {
            let buttonWidth: CGFloat
            switch innerConfig.type {
            case .tab:
                buttonWidth = (bounds.width-innerConfig.horizontalMargin*2)/CGFloat(titleButtons.count)
            case .segement:
                let title = titleButton.title(for: .normal) ?? ""
                let normalButtonWidth = title.boundingWidth(with: innerConfig.normalTitleFont)
                let selectedButtonWidth = title.boundingWidth(with: innerConfig.selectedTitleFont)
                buttonWidth = selectedButtonWidth > normalButtonWidth ? selectedButtonWidth : normalButtonWidth
            }
            titleButton.frame = CGRect(x: offsetX, y: 0, width: buttonWidth, height: scrollView.bounds.height)
            switch innerConfig.type {
            case .tab:
                offsetX += buttonWidth
            case .segement:
                offsetX += buttonWidth+innerConfig.horizontalSpace
            }
        }
        switch innerConfig.type {
        case .tab:
            scrollView.contentSize = CGSize(width: bounds.width, height: bounds.height)
        case .segement:
            scrollView.contentSize = CGSize(width: offsetX-innerConfig.horizontalSpace+innerConfig.horizontalMargin, height: bounds.height)
        }
    }
    
    private func updateSelectedButton(at index: Int, animated: Bool) {
        guard scrollView.frame != .zero else {
            initSelectedIndex = index
            return
        }
        guard titleButtons.count != 0 else { return }
        if let selectedIndex = selectedIndex, selectedIndex >= 0, selectedIndex < titleButtons.count {
            let titleButton = titleButtons[selectedIndex]
            titleButton.setTitleColor(innerConfig.normalTitleColor, for: .normal)
            titleButton.transform = .identity
        }
        guard index >= 0, index < titleButtons.count else { return }
        let titleButton = titleButtons[index]
        titleButton.setTitleColor(innerConfig.selectedTitleColor, for: .normal)
        titleButton.transform = CGAffineTransform(scaleX: 1.0 + scaleIncrement, y: 1.0 + scaleIncrement)
        
        if indicatorView.frame != .zero {
            UIView.animate(withDuration: 0.25) {
                self.indicatorView.frame = CGRect(x:titleButton.center.x-(self.innerConfig.indicatorWidth)/2, y: self.frame.height-self.innerConfig.indicatorHeight, width: self.innerConfig.indicatorWidth, height: self.innerConfig.indicatorHeight)
            }
        } else {
            self.indicatorView.frame = CGRect(x: titleButton.center.x-(self.innerConfig.indicatorWidth)/2, y: self.frame.height-self.innerConfig.indicatorHeight, width: self.innerConfig.indicatorWidth, height: self.innerConfig.indicatorHeight)
        }
        if case .segement = innerConfig.type {
            var offsetX = titleButton.frame.origin.x-(scrollView.bounds.width-titleButton.bounds.width)/2
            if offsetX < 0 {
                offsetX = 0
            } else if (offsetX+scrollView.bounds.width) > scrollView.contentSize.width {
                offsetX = scrollView.contentSize.width-scrollView.bounds.width
            }
            if scrollView.contentSize.width > scrollView.bounds.width {
                scrollView.setContentOffset(CGPoint(x: offsetX, y: scrollView.contentOffset.y), animated: animated)
            }
        }
        guard index != selectedIndex else { return }
        selectedIndex = index
        delegate?.segementSwitcherView(self, didSelectAtIndex: index, animated: animated)
    }
    
    @objc private func didClickTitleButton(_ button: UIButton) {
        selectSwitcher(at: button.tag, animated: false)
        isClicking = true
    }
    
}

extension SegementSlideSwitcherView {

    internal func animateSwitcherChanging(_ currentPage: Int, _ nextPage: Int, progress: CGFloat) {
        guard currentPage < titleButtons.count, nextPage < titleButtons.count, !isClicking else {
            isClicking = false 
            return
        }
        let currentTitleButton = self.titleButtons[currentPage]
        let nextTitleButton = self.titleButtons[nextPage]
        
        /// indicator animation
        let space = abs(nextTitleButton.center.x - currentTitleButton.center.x)
        let horizontalSpaceIncrement = progress * space
        var newFrame = self.indicatorFrame
        newFrame.origin.x += horizontalSpaceIncrement
        UIView.animate(withDuration: 0.1) {
            self.indicatorView.frame = newFrame
        }
        
        /// title color animation
        if let currentTitleColor = currentTitleButton.titleLabel?.textColor,
            let nextTitleColor = nextTitleButton.titleLabel?.textColor {
            currentTitleButton.setTitleColor(currentTitleColor
                .interpolateRGBColorTo(config.normalTitleColor, fraction: progress), for: .normal)
            nextTitleButton.setTitleColor(nextTitleColor
                .interpolateRGBColorTo(config.selectedTitleColor, fraction: progress), for: .normal)
        }
        
        /// title font animation
        let threshold = nextTitleButton.frame.origin.x - currentTitleButton.frame.origin.x
        var rotio: CGFloat = 0.0
        if threshold > 0 {
            rotio = progress
        } else {
            rotio = 1 - progress
        }
        
        currentTitleButton.transform = CGAffineTransform(scaleX: 1.0 + (1.0 - rotio) * self.scaleIncrement, y: 1.0 + (1.0 - rotio) * self.scaleIncrement)
        nextTitleButton.transform = CGAffineTransform(scaleX: 1.0 + rotio * self.scaleIncrement, y: 1.0 + rotio * self.scaleIncrement)
    }
}


extension UIColor {
    
    func interpolateRGBColorTo(_ end: UIColor, fraction: CGFloat) -> UIColor? {
        
        guard let c1 = self.cgColor.components, let c2 = end.cgColor.components else { return nil }
        
        let f = min(max(0, fraction), 1)
        
        let r: CGFloat = CGFloat(c1[0] + (c2[0] - c1[0]) * f)
        let g: CGFloat = CGFloat(c1[1] + (c2[1] - c1[1]) * f)
        let b: CGFloat = CGFloat(c1[2] + (c2[2] - c1[2]) * f)
        let a: CGFloat = CGFloat(c1[3] + (c2[3] - c1[3]) * f)
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
}

