import UIKit

final class AdditionalViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
    }
}

private extension AdditionalViewController {
    
    func commonInit() {
        view.layer.masksToBounds = false
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.cornerRadius = 20.0
    }
}

