//
//  MarkupTextProcessor.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 9/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton
class MarkupProcessor: TextProcessing {
    private let markupKey = NSAttributedString.Key(rawValue: "markup")
    private let rangeMarker = "start"

    var name: String {
        return "Markup"
    }

    var priority: TextProcessingPriority {
        return .medium
    }

    func process(editor: EditorView, range editedRange: NSRange, changeInLength delta: Int, processed: inout Bool) {
        let textStorage = editor.attributedText
        let char = textStorage.attributedSubstring(from: editedRange)

        guard char.string == "*" else { return }

        guard let markupRange = textStorage.reverseRange(of: "*", currentPosition: editedRange.location),
            let attr = textStorage.attribute(markupKey, at: markupRange.location, effectiveRange: nil) as? String,
            attr == rangeMarker
            else {
                editor.addAttributes([markupKey : rangeMarker], at: editedRange)
                processed = true
                return
        }

        let attrs = textStorage.attributes(at: markupRange.location, effectiveRange: nil)
        guard let font = attrs[NSAttributedString.Key.font] as? UIFont else { return }
        let boldFont = font.adding(trait: .traitBold)
        editor.addAttribute(.font, value: boldFont, at: markupRange)
        editor.replaceCharacters(in: markupRange.firstCharacterRange, with: " ")
        editor.replaceCharacters(in: markupRange.lastCharacterRange, with: " ")

        processed = true
    }

    func processInterrupted(editor: EditorView, at range: NSRange) {
        let rangeToCheck = NSRange(location: 0, length: range.location)
        let textStorage = editor.attributedText
        textStorage.enumerateAttribute(markupKey, in: rangeToCheck, options: .reverse) { val, range, stop in
            guard let value = val as? String,
                value == rangeMarker else { return }
            editor.removeAttribute(markupKey, at: range)
            stop.pointee = true
        }
    }
}
