//
//  EditorContent.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 4/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import UIKit
import ProtonCore   // brings in EditorContentName, PRTextStorage, etc.

/// Type of attachment
public enum AttachmentType {
    case block
    case inline
}

/// Type of `EditorContent`
public enum EditorContentType {
    case text(name: EditorContent.Name, attributedString: NSAttributedString)
    case attachment(name: EditorContent.Name, attachment: Attachment, contentView: UIView, type: AttachmentType)
    case viewOnly
}

/// Defines "one piece of content" inside the Editor (either text, an attachment, or view‐only)
public struct EditorContent {
    /// Either text or attachment or view‐only
    public let type: EditorContentType

    /// The range in the overall NSAttributedString that this content occupies
    public let enclosingRange: NSRange?

    public init(type: EditorContentType) {
        self.type = type
        self.enclosingRange = nil
    }

    public init(type: EditorContentType, enclosingRange: NSRange) {
        self.type = type
        self.enclosingRange = enclosingRange
    }
}

public extension EditorContent {
    /// Everywhere in Proton’s Swift code, when they write `EditorContent.Name` they want this type:
    typealias Name = EditorContentName
}

// --------------------------------------------------------------------------------------------
// MARK: • RawRepresentable conformance for EditorContentName
//
// We imported `EditorContentName` from ProtonCore.  Now we give it a RawRepresentable
// conformance so that Swift code can treat it like a "String‐backed enum."

extension EditorContentName: RawRepresentable {
    public convenience init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }

    // `EditorContentName` already has `public let rawValue: String` and `init(rawValue: String)`,
    // so this satisfies RawRepresentable’s requirements automatically.
    // 
    // Now we add the static constants that Swift code expects as "shortcuts."

    public static let paragraph = EditorContentName.paragraph()
    public static let viewOnly = EditorContentName.viewOnly()
    public static let newline = EditorContentName.newline()
    public static let text = EditorContentName.text()
    public static let unknown = EditorContentName.unknown()
    public static let blockContentType = EditorContentName.blockContentType()
    public static let inlineContentType = EditorContentName.inlineContentType()
    public static let isBlockAttachment = EditorContentName.isBlockAttachment()
    public static let isInlineAttachment = EditorContentName.isInlineAttachment()
}