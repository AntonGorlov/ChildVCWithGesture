import UIKit

private enum State: Equatable {
    case open
    case closed
    
    static prefix func!(_ state: State) -> State {
        switch state {
        case .open:
            return .closed
        case .closed:
            return .open
        }
    }
}

class TransitionCoordinator: NSObject {
    
    var showKeyboard: (() -> Void)?
    
    private weak var mainViewController: UIViewController!
    private weak var presentationViewController: UIViewController!
    
    private lazy var panGestureRecognizer = createPanGestureRecognizer()
    private lazy var tapGestureRecognizer = createTapGestureRecognizer()
    private var state: State = .closed
    private var runningAnimators = [UIViewPropertyAnimator]()
    private var totalAnimationDistance: CGFloat {
        let distance = mainViewController.view.bounds.height / 2
        return distance
    }
    
    init(mainViewController: UIViewController, childViewController: UIViewController) {
        self.mainViewController = mainViewController
        self.presentationViewController = childViewController
        super.init()
        presentationViewController.view.addGestureRecognizer(panGestureRecognizer)
        presentationViewController.view.addGestureRecognizer(tapGestureRecognizer)
        updateUI(with: state)
        installKeyboardDismissRecognizer()
        KeyboardListener.shared.addListener(self)
    }
    
    deinit {
        KeyboardListener.shared.removeListener(self)
    }
}

extension TransitionCoordinator {
    
    @objc private func didPanPlayer(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            startInteractiveTransition(for: !state)
        case .changed:
            let translation = recognizer.translation(in: recognizer.view!)
            updateInteractiveTransition(distanceTraveled: translation.y)
        case .ended:
            let velocity = recognizer.velocity(in: recognizer.view!).y
            let isCancelled = isGestureCancelled(with: velocity)
            continueInteractiveTransition(cancel: isCancelled)
            if velocity <= 0 && state == .open {
                showKeyboard?()
            } else {
                dismissKeyboard()
            }
        case .cancelled, .failed:
            continueInteractiveTransition(cancel: true)
        default:
            break
        }
    }
    
    @objc private func didTapPlayer(recognizer: UITapGestureRecognizer) {
        animateTransition(for: !state)
    }
    
    private func startInteractiveTransition(for state: State) {
        animateTransition(for: state)
        runningAnimators.pauseAnimations()
    }
    
    private func updateInteractiveTransition(distanceTraveled: CGFloat) {
        var fraction = distanceTraveled / totalAnimationDistance
        if state == .open { fraction *= -1 }
        runningAnimators.fractionComplete = fraction
    }
    
    private func continueInteractiveTransition(cancel: Bool) {
        if cancel {
            runningAnimators.reverse()
            state = !state
        }
        runningAnimators.continueAnimations()
    }
    
    private func animateTransition(for newState: State) {
        state = newState
        runningAnimators = createTransitionAnimators(with: TransitionCoordinator.animationDuration)
        runningAnimators.startAnimations()
    }
    
    private func isGestureCancelled(with velocity: CGFloat) -> Bool {
        guard velocity != 0 else { return false }
        
        let isPanningDown = velocity > 0
        return (state == .open && isPanningDown) || (state == .closed && !isPanningDown)
    }
}

extension TransitionCoordinator: UIGestureRecognizerDelegate {
    private func createPanGestureRecognizer() -> UIPanGestureRecognizer {
        let recognizer = UIPanGestureRecognizer()
        recognizer.addTarget(self, action: #selector(didPanPlayer(recognizer:)))
        recognizer.delegate = self
        return recognizer
    }
    
    private func createTapGestureRecognizer() -> UITapGestureRecognizer {
        let recognizer = UITapGestureRecognizer()
        recognizer.addTarget(self, action: #selector(didTapPlayer(recognizer:)))
        recognizer.delegate = self
        return recognizer
    }
}

extension TransitionCoordinator {
    
    private static let animationDuration = TimeInterval(0.7)
    
    private func createTransitionAnimators(with duration: TimeInterval) -> [UIViewPropertyAnimator] {
        switch state {
        case .open:
            return [
                openViewAnimator(with: duration)
            ]
        case .closed:
            return [
                closeViewAnimator(with: duration)
            ]
        }
    }
    
    private func openViewAnimator(with duration: TimeInterval) -> UIViewPropertyAnimator {
        let animator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1.0)
        addAnimation(to: animator, animations: {
            self.updatePresentationContainer(with: self.state)
        })
        return animator
    }
    
    private func closeViewAnimator(with duration: TimeInterval) -> UIViewPropertyAnimator {
        let animator = UIViewPropertyAnimator(duration: duration, dampingRatio: 0.9)
        addAnimation(to: animator, animations: {
            self.updatePresentationContainer(with: self.state)
            self.dismissKeyboard()
        })
        return animator
    }
    
    private func addAnimation(to animator: UIViewPropertyAnimator, animations: @escaping () -> Void) {
        animator.addAnimations { animations() }
        animator.addCompletion({ _ in
            animations()
            self.runningAnimators.remove(animator)
        })
    }
    
    private func addKeyframeAnimation(to animator: UIViewPropertyAnimator,
                                      withRelativeStartTime frameStartTime: Double = 0.0,
                                      relativeDuration frameDuration: Double = 1.0,
                                      animations: @escaping () -> Void) {
        animator.addAnimations {
            UIView.animateKeyframes(withDuration: 0, delay: 0, options: [], animations: {
                UIView.addKeyframe(withRelativeStartTime: frameStartTime, relativeDuration: frameDuration) {
                    animations()
                }
            })
        }
        animator.addCompletion({ _ in
            animations()
            self.runningAnimators.remove(animator)
        })
    }
}

extension TransitionCoordinator {
    
    private func updateUI(with state: State) {
        updatePresentationContainer(with: state)
    }
    
    private func updatePresentationContainer(with state: State) {
        presentationViewController?.view.transform = state == .open ? .identity : CGAffineTransform(translationX: 0, y: totalAnimationDistance)
    }
}

extension TransitionCoordinator: KeyboardListeningType {
    
    func keyboardStateChangeWithFrame(frame: CGRect, willBeShown: Bool) {
        state = willBeShown ? .open : .closed
        updateUI(with: state)
    }
    
    private func installKeyboardDismissRecognizer() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        presentationViewController.view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        presentationViewController.view.endEditing(true)
    }
}
