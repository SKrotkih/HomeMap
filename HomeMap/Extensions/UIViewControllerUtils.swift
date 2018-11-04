
import UIKit

extension UIViewController {
  var viewCenter: CGPoint {
    let screenSize = view.bounds
    return CGPoint(x: screenSize.width / 2.0, y: screenSize.height / 2.0)
  }
  
  func showMessage(_ message: String, label: UILabel, seconds: Double) {
    label.text = message
    
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
      if label.text == message {
        label.text = ""
      }
    }
  }
}
