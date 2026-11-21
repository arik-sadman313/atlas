import UIKit
import ObjectiveC

/// The bar iOS puts over the keyboard in a web view (previous and next field, Done), hidden: the page draws its own row
/// there for every field (web/src/components/KeyboardKeys.tsx), with Done and the keys of what's being typed in.
enum KeyboardBar {
    /// WebKit's content view answers no accessory view. Added on that class only (`class_replaceMethod`), so no other
    /// view's is touched.
    static func hide() {
        guard let content = NSClassFromString("WKContentView") else { return }
        let selector = #selector(getter: UIResponder.inputAccessoryView)
        guard let method = class_getInstanceMethod(content, selector) else { return }
        let none: @convention(block) (AnyObject) -> UIView? = { _ in nil }
        class_replaceMethod(content, selector, imp_implementationWithBlock(none), method_getTypeEncoding(method))
    }
}
