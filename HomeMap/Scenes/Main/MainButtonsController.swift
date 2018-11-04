//
//  MainButtonsController.swift
//  HomeMap
//
//  Created by Сергей Кротких on 12/05/2018.
//  Copyright © 2018 skappledev. All rights reserved.
//

import UIKit
import RxSwift

class MainButtonsController: NSObject {

    enum ActionType {
        case finish
        case cancel
        case home
    }
    
    var action = Variable<ActionType>(.home)
    
    private let homeButton = UIButton(size: CGSize(width: MainConstants.MainButtonSize, height: MainConstants.MainButtonSize), image: MainConstants.Image.Place.length)
    private let cancelButton = UIButton(size: CGSize(width: MainConstants.SecondButtonsSize, height: MainConstants.SecondButtonsSize), image: MainConstants.Image.Close.delete)
    private let finishButton = UIButton(size: CGSize(width: MainConstants.SecondButtonsSize, height: MainConstants.SecondButtonsSize), image: MainConstants.Image.Place.done)

    private func layoutButtons(on view: UIView) {
        let width = view.bounds.width
        let height = view.bounds.height
        let x = (width - MainConstants.MainButtonSize)/2
        let y = (height - 20 - MainConstants.MainButtonSize)
        homeButton.frame = CGRect(x: x, y: y, width: MainConstants.MainButtonSize, height: MainConstants.MainButtonSize)
        finishButton.center = homeButton.center
        cancelButton.frame = CGRect(x: 40, y: homeButton.frame.origin.y + 10, width: MainConstants.SecondButtonsSize, height: MainConstants.SecondButtonsSize)
        view.addSubview(finishButton)
        view.addSubview(homeButton)
        view.addSubview(cancelButton)
    }

    private func bindToActions() {
        _ = finishButton.rx.tap.bind {
            self.action.value = .finish
        }
        _ = cancelButton.rx.tap.bind {
            self.action.value = .cancel
        }
        _ = homeButton.rx.tap.bind {
            self.doAnimation(button: self.homeButton)
            self.action.value = .home
        }
    }
    
    private var finishButtonState = false
    
    required convenience init(view: UIView) {
        self.init()
        layoutButtons(on: view)
        bindToActions()
    }

    var isHidden: Bool = false {
        didSet {
            homeButton.isHidden = isHidden
            cancelButton.isHidden = isHidden
            finishButton.isHidden = isHidden
        }
    }

    private func doAnimation(button: UIButton) {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.allowUserInteraction,.curveEaseOut], animations: {
            button.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { (value) in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.allowUserInteraction,.curveEaseIn], animations: {
                button.transform = CGAffineTransform.identity
            }) { (value) in
            }
        }
    }
    
    func finishButton(show: Bool) {
        guard finishButtonState != show else {
            return
        }
        finishButtonState = show
        var center = homeButton.center
        if show {
            center.y -= 100
        }
        UIView.animate(withDuration: 0.3) {
            self.finishButton.center = center
        }
    }

    func setUpActionButtons(to actionState: MainViewController.ActionState) {
        switch actionState {
        case .area:
            finishButton(show: false)
            homeButton.normalImage  = MainConstants.Image.Place.length
            homeButton.disabledImage = MainConstants.Image.Place.length
        case .length:
            homeButton.normalImage  = MainConstants.Image.Place.area
            homeButton.disabledImage = MainConstants.Image.Place.area
        case .vase:
            homeButton.normalImage  = MainConstants.Image.Gallery.vase
            homeButton.disabledImage = MainConstants.Image.Gallery.vase
        case .chair:
            homeButton.normalImage  = MainConstants.Image.Gallery.chair
            homeButton.disabledImage = MainConstants.Image.Gallery.chair
        case .candle:
            homeButton.normalImage  = MainConstants.Image.Gallery.candle
            homeButton.disabledImage = MainConstants.Image.Gallery.candle
        }
    }

    enum HomeCancelState {
        case HomeEnabled
        case HomeDisabled
        case Delete
        case Cancel
    }
    
    var homeCancelState: HomeCancelState = .HomeEnabled {
        didSet {
            switch homeCancelState {
            case .HomeEnabled:
                homeButton.isEnabled = true
            case .HomeDisabled:
                homeButton.isEnabled = false
            case .Delete:
                cancelButton.normalImage = MainConstants.Image.Close.delete
            case .Cancel:
                cancelButton.normalImage = MainConstants.Image.Close.cancel
            }
        }
    }
}
