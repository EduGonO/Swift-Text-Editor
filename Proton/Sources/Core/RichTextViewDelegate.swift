//
//  RichTextViewDelegate.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 7/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

public enum EditorKey {
    case enter
    case backspace
}

protocol RichTextViewDelegate: class {
    func richTextView(_ richTextView: RichTextView, didChangeSelection range: NSRange, attributes: [EditorAttribute], contentType: EditorContent.Name)
    func richTextView(_ richTextView: RichTextView, didReceiveKey key: EditorKey, at range: NSRange, handled: inout Bool)
    func richTextView(_ richTextView: RichTextView, didReceiveFocusAt range: NSRange)
    func richTextView(_ richTextView: RichTextView, didLoseFocusFrom range: NSRange)
}
