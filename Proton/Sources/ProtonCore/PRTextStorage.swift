import UIKit

@objc(DefaultTextFormattingProviding)
public protocol DefaultTextFormattingProviding: AnyObject {
  var font: UIFont { get }
  var paragraphStyle: NSMutableParagraphStyle { get }
  var textColor: UIColor { get }
}

// @objc(TextStorageDelegate)
public protocol TextStorageDelegate: AnyObject {
  func textStorage(_ textStorage: PRTextStorage, didDelete attachment: NSTextAttachment)
  func textStorage(_ textStorage: PRTextStorage, will deleteText: NSAttributedString, insertText: NSAttributedString, in range: NSRange)
  func textStorage(_ textStorage: PRTextStorage, edited actions: NSTextStorage.EditActions, in editedRange: NSRange, changeInLength delta: Int)
}

 public class PRTextStorage: NSTextStorage {
  public weak var defaultTextFormattingProvider: DefaultTextFormattingProviding?
  public weak var textStorageDelegate: TextStorageDelegate

  private let storage = NSTextStorage()

  public override init() {
    super.init()
  }

  public required init?(coder: NSCoder) {
    storage.replaceCharacters(in: NSRange(location: 0, length: 0), with: "")
    super.init(coder: coder)
  }

  public override var string: String {
    storage.string
  }

  public override func attributes(
    at location: Int,
    effectiveRange range: NSRangePointer?
  ) -> [NSAttributedString.Key: Any] {
    guard location < storage.length else { return [:] }
    return storage.attributes(at: location, effectiveRange: range)
  }

  public override func attributes(
    at location: Int,
    longestEffectiveRange range: NSRangePointer?,
    in textRange: NSRange
  ) -> [NSAttributedString.Key: Any] {
    guard location < storage.length else { return [:] }
    return storage.attributes(
      at: location,
      longestEffectiveRange: range,
      in: textRange
    )
  }

  public override func attributedSubstring(from range: NSRange) -> NSAttributedString {
    let clamped = clampedRange(range, upperBound: length)
    return super.attributedSubstring(from: clamped)
  }

  private func clampedRange(_ range: NSRange, upperBound: Int) -> NSRange {
    let loc = max(min(range.location, upperBound), 0)
    let len = max(min(range.length, upperBound - loc), 0)
    return NSRange(location: loc, length: len)
  }

  public override func replaceCharacters(
    in range: NSRange,
    with str: String
  ) {
    // Capture attachments to delete afterward
    let attachments = attachments(in: range)

    beginEditing()
    let delta = str.count - range.length
    storage.replaceCharacters(in: range, with: str)
    storage.fixAttributes(in: NSRange(location: 0, length: storage.length))
    edited([.editedCharacters, .editedAttributes], range: range, changeInLength: delta)
    endEditing()

    deleteAttachments(attachments)
  }

  public override func replaceCharacters(
    in range: NSRange,
    with attrString: NSAttributedString
  ) {
    // Prevent out-of-bounds
    guard range.location + range.length <= storage.length else { return }

    // Fix missing attrs at first character of replacement
    let replacement = NSMutableAttributedString(attributedString: attrString)
    if range.length > 0 && attrString.length > 0 {
      let outgoingAttrs = storage.attributes(
        at: range.location + range.length - 1,
        effectiveRange: nil
      )
      let incomingAttrs = attrString.attributes(at: 0, effectiveRange: nil)

      var diff: [NSAttributedString.Key: Any] = [:]
      for (key, value) in outgoingAttrs {
        if incomingAttrs[key] == nil && key != .underlineStyle {
          diff[key] = value
        }
      }
      replacement.addAttributes(diff, range: NSRange(location: 0, length: replacement.length))
    }

    let deletedText = storage.attributedSubstring(from: range)
    textStorageDelegate?.textStorage(self, will: deletedText, insertText: replacement, in: range)

    super.replaceCharacters(in: range, with: replacement)
  }

  public override func setAttributes(
    _ attrs: [NSAttributedString.Key: Any]?,
    range: NSRange
  ) {
    guard range.location + range.length <= storage.length else { return }

    beginEditing()
    let updated = applyDefaultFormattingIfNeeded(to: attrs)
    storage.setAttributes(updated, range: range)
    storage.fixAttributes(in: NSRange(location: 0, length: storage.length))
    edited(.editedAttributes, range: range, changeInLength: 0)
    endEditing()
  }

  public override func addAttributes(
    _ attrs: [NSAttributedString.Key: Any],
    range: NSRange
  ) {
    guard range.location + range.length <= storage.length else { return }

    beginEditing()
    storage.addAttributes(attrs, range: range)
    storage.fixAttributes(in: NSRange(location: 0, length: storage.length))
    edited(.editedAttributes, range: range, changeInLength: 0)
    endEditing()
  }

  public func removeAttributes(_ attrs: [NSAttributedString.Key], range: NSRange) {
    guard range.location + range.length <= storage.length else { return }

    beginEditing()
    for key in attrs {
      storage.removeAttribute(key, range: range)
    }
    fixMissingAttributes(forDeleted: attrs, range: range)
    storage.fixAttributes(in: NSRange(location: 0, length: storage.length))
    edited(.editedAttributes, range: range, changeInLength: 0)
    endEditing()
  }

  public override func removeAttribute(
    _ name: NSAttributedString.Key,
    range: NSRange
  ) {
    guard range.location + range.length <= storage.length else { return }
    storage.removeAttribute(name, range: range)
  }

  public func insertAttachment(
    in range: NSRange,
    attachment: NSTextAttachment,
    withSpacer spacer: NSAttributedString
  ) {
    let spacerSet = CharacterSet.whitespaces
    var hasNextSpacer = false
    if range.location + 1 < length {
      let idx = range.location + 1
      let ch = (string as NSString).character(at: idx)
      hasNextSpacer = spacerSet.contains(UnicodeScalar(ch)!)
    }

    let attachmentString = NSMutableAttributedString(attachment: attachment)
    if !hasNextSpacer {
      attachmentString.append(spacer)
    }
    replaceCharacters(in: range, with: attachmentString)
  }

  public override func edited(
    _ editedMask: NSTextStorage.EditActions,
    range editedRange: NSRange,
    changeInLength delta: Int
  ) {
    super.edited(editedMask, range: editedRange, changeInLength: delta)
    textStorageDelegate?.textStorage(self, edited: editedMask, in: editedRange, changeInLength: delta)
  }

  // MARK: – Private helpers

  private func fixMissingAttributes(
    forDeleted attrs: [NSAttributedString.Key],
    range: NSRange
  ) {
    if attrs.contains(.foregroundColor) {
      storage.addAttribute(.foregroundColor, value: defaultTextColor, range: range)
    }
    if attrs.contains(.paragraphStyle) {
      storage.addAttribute(.paragraphStyle, value: defaultParagraphStyle, range: range)
    }
    if attrs.contains(.font) {
      storage.addAttribute(.font, value: defaultFont, range: range)
    }
  }

  private func applyDefaultFormattingIfNeeded(
    to attributes: [NSAttributedString.Key: Any]?
  ) -> [NSAttributedString.Key: Any] {
    var updated = attributes ?? [:]
    if updated[.paragraphStyle] == nil {
      updated[.paragraphStyle] = defaultTextFormattingProvider?.paragraphStyle.copy() ?? defaultParagraphStyle
    }
    if updated[.font] == nil {
      updated[.font] = defaultTextFormattingProvider?.font ?? defaultFont
    }
    if updated[.foregroundColor] == nil {
      updated[.foregroundColor] = defaultTextFormattingProvider?.textColor ?? defaultTextColor
    }
    return updated
  }

  private func attachments(in range: NSRange) -> [NSTextAttachment] {
    var result: [NSTextAttachment] = []
    storage.enumerateAttribute(
      .attachment,
      in: range,
      options: .longestEffectiveRangeNotRequired
    ) { value, _, _ in
      if let att = value as? NSTextAttachment {
        result.append(att)
      }
    }
    return result
  }

  private func deleteAttachments(_ attachments: [NSTextAttachment]) {
    for att in attachments {
      textStorageDelegate?.textStorage(self, didDelete: att)
    }
  }

  // MARK: – Default formatting accessors

  public var defaultFont: UIFont {
    UIFont.preferredFont(forTextStyle: .body)
  }

  public var defaultParagraphStyle: NSParagraphStyle {
    NSParagraphStyle()
  }

  public var defaultTextColor: UIColor {
    if #available(iOS 13, *) {
      return .label
    } else {
      return .black
    }
  }
}
