//
//  NSAttributedString+Content.swift
//

import Foundation
import UIKit
import ProtonCore   // so that EditorContent, EditorContentName, and those keys exist

public extension NSAttributedString.Key {
    /// Make ".blockContentType" available everywhere
    static let blockContentType = NSAttributedString.Key(EditorContent.Name.blockContentType.rawValue)
    static let viewOnlyContentType = NSAttributedString.Key(EditorContent.Name.viewOnly.rawValue)
    static let newlineContentType = NSAttributedString.Key(EditorContent.Name.newline.rawValue)
    static let textContentType = NSAttributedString.Key(EditorContent.Name.text.rawValue)
    static let unknownContentType = NSAttributedString.Key(EditorContent.Name.unknown.rawValue)
    static let inlineContentType = NSAttributedString.Key(EditorContent.Name.inlineContentType.rawValue)
    static let isBlockAttachment = NSAttributedString.Key(EditorContent.Name.isBlockAttachment.rawValue)
    static let isInlineAttachment = NSAttributedString.Key(EditorContent.Name.isInlineAttachment.rawValue)
}

public extension NSAttributedString {

    /// A convenience to get a mutable copy
    var asMutable: NSMutableAttributedString {
        NSMutableAttributedString(attributedString: self)
    }

    /// Adds attributes to a given range (or full string if range == nil)
    func addingAttributes(_ attributes: [NSAttributedString.Key: Any], to range: NSRange? = nil) -> NSAttributedString {
        let range = range?.clamped(upperBound: length) ?? NSRange(location: 0, length: length)
        let mutable = asMutable
        mutable.addAttributes(attributes, range: range)
        return mutable
    }

    /// Enumerate **block** content runs.  Default‐if‐missing is ".paragraph".
    func enumerateContents(in range: NSRange? = nil) -> AnySequence<EditorContent> {
        enumerateContentType(.blockContentType, options: [], defaultIfMissing: .paragraph, in: range)
    }

    /// Enumerate **inline** content runs.  Default‐if‐missing is ".text"
    func enumerateInlineContents(in range: NSRange? = nil) -> AnySequence<EditorContent> {
        enumerateContentType(
            .inlineContentType,
            options: [.longestEffectiveRangeNotRequired],
            defaultIfMissing: .text,
            in: range
        )
    }

    /// Enumerate over contiguous ranges that have (or don’t have) a given attribute.
    /// This is utility code you already had; no changes needed here.
    func enumerateContinuousRangesByAttribute(
        _ attributeName: NSAttributedString.Key,
        in range: NSRange? = nil,
        using block: (_ isPresent: Bool, _ range: NSRange) -> Void
    ) {
        let enumerationRange = range ?? NSRange(location: 0, length: length)
        var lastRange: NSRange? = nil
        var isAttributePresentInLastRange = false

        enumerateAttributes(in: enumerationRange, options: []) { attributes, currentRange, _ in
            let isAttributePresent = attributes[attributeName] != nil
            if let last = lastRange {
                if isAttributePresentInLastRange != isAttributePresent {
                    // state changed → report previous
                    block(isAttributePresentInLastRange, last)
                    lastRange = currentRange
                } else {
                    // extend the previous run
                    lastRange = NSRange(location: last.location, length: NSMaxRange(currentRange) - last.location)
                }
            } else {
                lastRange = currentRange
            }
            isAttributePresentInLastRange = isAttributePresent
        }

        if let last = lastRange {
            block(isAttributePresentInLastRange, last)
        }
    }
}

/// The shared implementation that drives both `enumerateContents` and `enumerateInlineContents`.
/// It yields an iterator of `EditorContent` entries (or returns `nil` when done).
public extension NSAttributedString {
    func enumerateContentType(
        _ key: NSAttributedString.Key,
        options: NSAttributedString.EnumerationOptions,
        defaultIfMissing: EditorContent.Name,
        in range: NSRange? = nil
    ) -> AnySequence<EditorContent> {
        let searchRange = range ?? NSRange(location: 0, length: length)
        let contentString = attributedSubstring(from: searchRange)

        return AnySequence { () -> AnyIterator<EditorContent> in
            var substringRange = NSRange(location: 0, length: contentString.length)

            return AnyIterator<EditorContent> {
                // If we’ve walked past the end, stop.
                guard substringRange.location < contentString.length else {
                    return nil
                }

                var foundContent: EditorContent? = nil

                // Look at the next run of "key" in substringRange
                var effectiveRange = NSRange()
                let value = contentString.attribute(key, at: substringRange.location, longestEffectiveRange: &effectiveRange, in: substringRange)

                // Advance substringRange past this run
                let nextLocation = effectiveRange.location + effectiveRange.length
                substringRange = NSRange(location: nextLocation, length: contentString.length - nextLocation)

                // Determine which kind of content we have here:
                let contentName = (value as? EditorContent.Name) ?? defaultIfMissing

                // If it’s a "viewOnly" run, yield that:
                if contentName == EditorContent.Name.viewOnly {
                    foundContent = EditorContent(type: .viewOnly, enclosingRange: effectiveRange)

                // If it’s an attachment (and has a contentView), yield attachment variant:
                } else if
                    let attachment = contentString.attribute(.attachment, at: effectiveRange.location, effectiveRange: nil) as? Attachment,
                    let contentView = attachment.contentView
                {
                    let isBlock = (contentString.attribute(.isBlockAttachment, at: effectiveRange.location, effectiveRange: nil) as? Bool) == true
                    let attachType: AttachmentType = isBlock ? .block : .inline

                    foundContent = EditorContent(
                        type: .attachment(
                            name: contentName,
                            attachment: attachment,
                            contentView: contentView,
                            type: attachType
                        ),
                        enclosingRange: effectiveRange
                    )

                // Otherwise it’s just text; yield a text run:
                } else {
                    let attributedSubstring = contentString.attributedSubstring(from: effectiveRange)
                    // If the substring is literally just a newline character, treat that as a single newline:
                    if attributedSubstring.string == "\n" {
                        let newlineRange = NSRange(location: effectiveRange.location, length: 1)
                        foundContent = EditorContent(type: .text(name: contentName, attributedString: attributedSubstring), enclosingRange: newlineRange)
                    } else {
                        foundContent = EditorContent(type: .text(name: contentName, attributedString: attributedSubstring), enclosingRange: effectiveRange)
                    }
                }

                return foundContent
            }
        }
    }
}