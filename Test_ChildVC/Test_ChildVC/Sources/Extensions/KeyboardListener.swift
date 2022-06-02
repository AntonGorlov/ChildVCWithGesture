import UIKit

public protocol KeyboardListeningType: class {
    func keyboardStateChangeWithFrame(frame: CGRect, willBeShown: Bool)
}

public class KeyboardListener {
    
    public static let shared = KeyboardListener()
    
    private var listeners = [KeyboardListeningType]()
    
    private
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func handleKeyboard(keyboardNotification: NSNotification) {
        guard
            let userInfo = keyboardNotification.userInfo,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curveRawValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int,
            let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            else {
                return
        }
        let curve = UIView.AnimationCurve.init(rawValue: curveRawValue)
        let keyboardWillBeShown = keyboardNotification.name == UIResponder.keyboardWillShowNotification
        
        UIView.beginAnimations("KeyboardAnimationID", context: nil)
        UIView.setAnimationCurve(curve!)
        
        if keyboardWillBeShown {
            UIView.setAnimationDelegate(self)
        } else {
            UIView.setAnimationDelegate(nil)
        }
        
        UIView.setAnimationDuration(duration)
        
        for listener in listeners {
            listener.keyboardStateChangeWithFrame(frame: keyboardFrame, willBeShown: keyboardWillBeShown)
        }
        
        UIView.commitAnimations()
    }
    
    public func addListener(_ listener: KeyboardListeningType) {
        listeners.append(listener)
    }
    
    public func removeListener(_ listener: KeyboardListeningType) {
        listeners = listeners.filter { ($0 !== listener) }
    }
}
