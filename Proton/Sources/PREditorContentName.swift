import Foundation
import UIKit

@objc(EditorContentName)
public final class PREditorContentName: NSObject, NSSecureCoding {
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
    guard let other = object as? PREditorContentName else { return false }
    return rawValue == other.rawValue
  }

  public override var hash: Int {
    rawValue.hashValue
  }

  public override var description: String {
    "EditorContent.Name(rawValue: \"\(rawValue)\")"
  }

  public static func paragraphName() -> PREditorContentName {
    PREditorContentName(rawValue: "_paragraph")
  }

  public static func viewOnlyName() -> PREditorContentName {
    PREditorContentName(rawValue: "_viewOnly")
  }

  public static func newlineName() -> PREditorContentName {
    PREditorContentName(rawValue: "_newline")
  }

  public static func textName() -> PREditorContentName {
    PREditorContentName(rawValue: "_text")
  }

  public static func unknownName() -> PREditorContentName {
    PREditorContentName(rawValue: "_unknown")
  }
}
