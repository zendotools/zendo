//
//  UIView+Nib.swift
//  Zendo
//
//  Created by Anton Pavlov on 07/08/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit

extension UIView {
    
    static var xibName: String {
        return String(describing: classForCoder())
    }
    
    static var nib: UINib{
        return UINib(nibName: self.xibName, bundle: nil)
    }
    
    /// Load self view from xib. Owner of the xib should be empty, xib's type
    /// should be self.
    static func loadFromNib() -> UIView? {
        return UINib(nibName: xibName, bundle: Bundle(for: classForCoder())).instantiate(withOwner: nil, options: nil).first as? UIView
    }
    
    /// Add view from xib as subview. Owner of the xib shuold be self.
    func loadNib() {
        let view = UINib(nibName: String(describing: classForCoder), bundle: Bundle(for: self.classForCoder)).instantiate(withOwner: self, options: nil).first as! UIView
        addSubview(view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        view.topAnchor.constraint(equalTo: topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
    }
    
}

extension UIView {
    
    func shadowView() {
        self.clipsToBounds = true
        let shadowPath = UIBezierPath(rect: self.bounds)
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        self.layer.shadowOpacity = 0.2
        self.layer.shadowPath = shadowPath.cgPath
        self.layer.shadowRadius = 10.0
    }
    
}
