import Foundation

/// The Swift class that used to be PREditorContentName in Objective-C.
/// All of the Swift code refers to EditorContentName.blockContentType(), etc.
public final class EditorContentName: NSObject, NSSecureCoding {
  public static var supportsSecureCoding: Bool { true }
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public func encode(with coder: NSCoder) {
    coder.encode(rawValue, forKey: "rawValue")
  }

  public required init?(coder: NSCoder) {
    guard let value = coder.decodeObject(of: NSString.self, forKey: "rawValue") as String? else {
      return nil
    }
    self.rawValue = value
  }

  public override func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? EditorContentName else { return false }
    return rawValue == other.rawValue
  }

  public override var hash: Int { rawValue.hashValue }

  public override var description: String {
    "EditorContent.Name(rawValue: \"\(rawValue)\")"
  }

  // --------------------------------------------------------------------------------------------
  // MARK: • Static factory methods
  //
  // Swift code in Proton/Sources/Swift expects to call:
  //    EditorContentName.paragraph(),
  //    EditorContentName.newline(),
  //    EditorContentName.blockContentType(),
  //    EditorContentName.inlineContentType(),
  //    EditorContentName.isBlockAttachment(), etc.
  // So we provide them all here:

  /// "Paragraph" content (used for ordinary blocks)
  public static func paragraph() -> EditorContentName {
    EditorContentName(rawValue: "_paragraph")
  }

  /// "View‐only" marker
  public static func viewOnly() -> EditorContentName {
    EditorContentName(rawValue: "_viewOnly")
  }

  /// "Newline" marker
  public static func newline() -> EditorContentName {
    EditorContentName(rawValue: "_newline")
  }

  /// "Text" marker (inline text)
  public static func text() -> EditorContentName {
    EditorContentName(rawValue: "_text")
  }

  /// "Unknown" marker
  public static func unknown() -> EditorContentName {
    EditorContentName(rawValue: "_unknown")
  }

  /// Swift code treats "blockContentType" as the same rawValue as paragraph()
  public static func blockContentType() -> EditorContentName {
    EditorContentName(rawValue: "_paragraph")
  }

  /// Swift code treats "inlineContentType" (we pick "_inline" here)
  public static func inlineContentType() -> EditorContentName {
    EditorContentName(rawValue: "_inline")
  }

  /// Marker for "Block Attachment"
  public static func isBlockAttachment() -> EditorContentName {
    EditorContentName(rawValue: "_isBlockAttachment")
  }

  /// Marker for "Inline Attachment"
  public static func isInlineAttachment() -> EditorContentName {
    EditorContentName(rawValue: "_isInlineAttachment")
  }
}

/// In many Swift files they refer to `EditorContent.Name`.
/// We do *not* introduce a second "EditorContent" type here--that’s in Proton/Sources/Swift.
/// But if any code ever imports ProtonCore directly and writes `EditorContent`,
/// it’ll see this alias. It does not interfere with the `struct EditorContent` in the Proton module.
public typealias EditorContent = EditorContentName