//
//  UIHelpersSwift.swift
//  iOS Demo
//
//  Created by Christopher Cornelius on 8/29/15.
//
//

import Foundation
import UIKit

class UIHelpersSwift {
    class func setX(x: CGFloat, view: UIView) {
        view.frame = CGRect(x: x,
                            y: view.frame.origin.y,
                            width:view.frame.size.width,
                            height:view.frame.size.height)
    }
    
    class func setY(y: CGFloat, view: UIView) {
        view.frame = CGRect(x: view.frame.origin.x,
                            y: y,
                            width:view.frame.size.width,
                            height:view.frame.size.height)
    }
    
    class func setW(w: CGFloat, view: UIView) {
        view.frame = CGRect(x: view.frame.origin.x,
                            y: view.frame.origin.y,
                            width:w,
                            height:view.frame.size.height)
    }
    
    class func setH(h: CGFloat, view: UIView) {
        view.frame = CGRect(x: view.frame.origin.x,
                            y: view.frame.origin.y,
                            width:view.frame.size.width,
                            height:h)
    }
}