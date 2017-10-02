//
//  TextField.swift
//  Mova.io
//
//  Created by Oleg on 10/1/17.
//  Copyright © 2017 Oleg. All rights reserved.
//

import Foundation
import UIKit

class TextField: UITextField {
    
    @IBInspectable var disableSeparator: Bool = false
    @IBInspectable var trim: Bool = false
    @IBInspectable var strokeColor: UIColor?
    weak var highlighLabel: UILabel?
    @IBInspectable var highlightedStrokeColor: UIColor?
    @IBInspectable var localize: Bool = false {
        willSet {
            if let text = placeholder , !text.isEmpty {
                super.placeholder = text.ls
            }
        }
    }
    
    @IBInspectable var placeholderTextColor: UIColor? = nil {
        willSet {
            if let text = placeholder, let font = font, let color = newValue , !text.isEmpty {
                attributedPlaceholder = NSMutableAttributedString(string: text, attributes:
                    [NSForegroundColorAttributeName : color, NSFontAttributeName : font])
            }
        }
    }
    
    override var text: String? {
        didSet {
            sendActions(for: .editingChanged)
        }
    }
    
    override func resignFirstResponder() -> Bool {
        if trim == true, let text = text , !text.isEmpty {
            self.text = text.trim
        }
        
        let flag = super.resignFirstResponder()
        setNeedsDisplay()
        return flag
    }
    
    @discardableResult override func becomeFirstResponder() -> Bool {
        let flag = super.becomeFirstResponder()
        setNeedsDisplay()
        return flag
    }
    
}

extension NSAttributedString {
    
    var foregroundColor: UIColor? {
        return attribute(NSForegroundColorAttributeName, at: 0, effectiveRange: nil) as? UIColor
    }
}

