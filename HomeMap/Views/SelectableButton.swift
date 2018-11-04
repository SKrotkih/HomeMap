
import UIKit

class SelectableButton: UIButton {
  override var isSelected: Bool {
    didSet {
      if isSelected {
        layer.borderColor = UIColor.yellow.cgColor
        layer.borderWidth = 3
      } else {
        layer.borderWidth = 0
      }
    }
  }
}
