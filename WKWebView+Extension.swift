//
//  WKWebView+Extension.swift
//
//
//  Created by Michael Sidoruk on 11.02.2020.
//  Copyright © 2020 PKP. All rights reserved.
//

import Foundation
import WebKit

fileprivate final class InputAccessoryHelper: NSObject {
    @objc var inputAccessoryView: AnyObject? { return nil }
}

extension WKWebView {
    ///Удаляет AccessoryView у клавиатуры при ее появлении в WKWebView.
    func removeInputAccessoryView() {
        let targetView = scrollView.subviews.first{ String(describing: type(of: $0)).hasPrefix("WKContent") }
        
        guard let target = targetView, let superclass = target.superclass else { return }
        
        let noInputAccessoryViewClassName = "\(superclass)_NoInputAccessoryView"
        var newClass: AnyClass? = NSClassFromString(noInputAccessoryViewClassName)
        
        if newClass == nil, let targetClass: AnyClass = object_getClass(target), let classNameCString = noInputAccessoryViewClassName.cString(using: .ascii) {
            
            newClass = objc_allocateClassPair(targetClass, classNameCString, 0)
            
            if let newClass = newClass {
                objc_registerClassPair(newClass)
            }
        }
        
        guard
            let noInputAccessoryClass = newClass,
            let originalMethod = class_getInstanceMethod(InputAccessoryHelper.self, #selector(getter: InputAccessoryHelper.inputAccessoryView)) else { return }
        
        class_addMethod(noInputAccessoryClass.self,
                        #selector(getter: InputAccessoryHelper.inputAccessoryView),
                        method_getImplementation(originalMethod),
                        method_getTypeEncoding(originalMethod))
        object_setClass(target, noInputAccessoryClass)
    }
}
