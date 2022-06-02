import UIKit

final class MainViewController: UIViewController {
    
    private lazy var additionalVCChild: AdditionalViewController = assembleAdditionalViewController()
    private var animationCoordinator: TransitionCoordinator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
    }
}

private extension MainViewController {
    
    func commonInit() {
        addChildControllers()
        showChild()
    }
    
    func addChildControllers() {
        for childController in [additionalVCChild] {
            add(childController)
            setupAnimationCoordinator(childViewController: childController)
        }
    }
    
    func showChild() {
        for child in children {
            child.view.isHidden = true
        }
        
        let childToDisplay: UIViewController = additionalVCChild
        childToDisplay.beginAppearanceTransition(true, animated: true)
        childToDisplay.view.isHidden = false
        childToDisplay.endAppearanceTransition()
    }
    
    func setupAnimationCoordinator(childViewController: UIViewController) {
        animationCoordinator = TransitionCoordinator(mainViewController: self, childViewController: childViewController)
    }
    
    func assembleAdditionalViewController() -> AdditionalViewController {
        let additionalVC = AdditionalViewController(nibName: AdditionalViewController.nameOfClass, bundle: nil)
        return additionalVC
    }
}
