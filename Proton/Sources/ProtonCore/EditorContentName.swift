import Foundation

/// The Swift type that represents "content‐name" (was `PREditorContentName` in Obj-C).
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
    guard let value = coder.decodeObject(of: NSString.self, forKey: "rawValue") as String?
    else { return nil }
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

  // Exactly match what the rest of Proton’s Swift code calls "blockContentType," etc.
  public static var blockContentType: EditorContentName {
    EditorContentName(rawValue: "_paragraph")
  }
  public static var viewOnlyContentType: EditorContentName {
    EditorContentName(rawValue: "_viewOnly")
  }
  public static var newlineContentType: EditorContentName {
    EditorContentName(rawValue: "_newline")
  }
  public static var textContentType: EditorContentName {
    EditorContentName(rawValue: "_text")
  }
  public static var unknownContentType: EditorContentName {
    EditorContentName(rawValue: "_unknown")
  }
}

/// In some places Proton’s Swift code refers to "EditorContent" directly,
/// so we alias it here to this class.
public typealias EditorContent = EditorContentName