//
//  PYView.swift
//  PurePinyin
//
//  Created by Joakim Fännick on 2018-09-23.
//  Copyright © 2018 Joakim Fännick. All rights reserved.
//
import UIKit
import WebKit
import Foundation

/*extension UIView {
    private static var _portraitFrame = [String:CGRect]()
    @IBInspectable var portraitFrame:CGRect {
        get {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            return UIView._portraitFrame[tmpAddress] ?? CGRect(x: -1, y: -1, width: -1, height: -1)
        }
        set(newValue) {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            UIView._portraitFrame[tmpAddress] = newValue
        }
    }
    private static var _landscapeFrame = [String:CGRect]()
    @IBInspectable var landscapeFrame:CGRect {
        get {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            return UIView._landscapeFrame[tmpAddress] ?? CGRect(x: -1, y: -1, width: -1, height: -1)
        }
        set(newValue) {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            UIView._landscapeFrame[tmpAddress] = newValue
        }
    }
    func updateFrame()
    {
        if let parent = self.superview
        {
            let islandscape = UIScreen.main.bounds.width > UIScreen.main.bounds.height
            let useLandscape = self.landscapeFrame != CGRect(x: -1, y: -1, width: -1, height: -1)
            let parentWidth = parent.frame.width
            let parentHeight = parent.frame.height
            var thisWidth = self.frame.width
            var thisHeight = self.frame.height
            var thisTop = self.frame.minY
            var thisLeft = self.frame.minX
            let whichRect = islandscape && useLandscape ? landscapeFrame : portraitFrame
            if whichRect.minX >= 0 { thisLeft = (parentWidth/100) * whichRect.minX }
            if whichRect.minY >= 0 { thisTop = (parentHeight/100) * whichRect.minY }
            if whichRect.height >= 0 { thisHeight = ((parentHeight/100) * whichRect.height) }
            if whichRect.width >= 0 { thisWidth = ((parentWidth/100) * whichRect.width) }
            self.frame = CGRect.init(x: thisLeft, y: thisTop, width: thisWidth, height: thisHeight)
        }
        for child in self.subviews
        {
            child.updateFrame()
        }
    }
}*/
