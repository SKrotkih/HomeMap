//
//  MainMenu.swift
//  HomeMap
//
//  Created by Сергей Кротких on 11/05/2018.
//  Copyright © 2018 skappledev. All rights reserved.
//

import UIKit
import RxSwift

class MainMenu: NSObject {

    var view: UIView {
        return menuButtonSet
    }
    
    private lazy var menuButtonSet: PopButton = PopButton(buttons:menuButton.vase,
                                                          menuButton.chair,
                                                          menuButton.candle,
                                                          menuButton.measurement,
                                                          menuButton.save,
                                                          menuButton.reset,
                                                          menuButton.setting,
                                                          menuButton.more
    )
    
    private let menuButton = (vase: UIButton(size: CGSize(width: MainConstants.MenuButtonsSize, height: MainConstants.MenuButtonsSize), image: MainConstants.Image.Menu.vase),
                              chair: UIButton(size: CGSize(width: MainConstants.MenuButtonsSize, height: MainConstants.MenuButtonsSize), image: MainConstants.Image.Menu.chair),
                              candle: UIButton(size: CGSize(width: MainConstants.MenuButtonsSize, height: MainConstants.MenuButtonsSize), image: MainConstants.Image.Menu.candle),
                              measurement: UIButton(size: CGSize(width: MainConstants.MenuButtonsSize, height: MainConstants.MenuButtonsSize), image: MainConstants.Image.Menu.area),
                              save: UIButton(size: CGSize(width: MainConstants.MenuButtonsSize, height: MainConstants.MenuButtonsSize), image: MainConstants.Image.Menu.save),
                              reset: UIButton(size: CGSize(width: MainConstants.MenuButtonsSize, height: MainConstants.MenuButtonsSize), image: MainConstants.Image.Menu.reset),
                              setting: UIButton(size: CGSize(width: MainConstants.MenuButtonsSize, height: MainConstants.MenuButtonsSize), image: MainConstants.Image.Menu.setting),
                              more: UIButton(size: CGSize(width: MainConstants.SecondButtonsSize, height: MainConstants.SecondButtonsSize), image: MainConstants.Image.More.close))
    
    enum ActionType {
        case vase
        case chair
        case candle
        case measurement
        case save
        case reset
        case setting
        case more
    }
    
    var action = Variable<ActionType>(.more)
    
    private func setUpMenu() {
        _ = menuButton.vase.rx.tap.bind {
            self.hideShowMenu()
            self.action.value = .vase
        }
        _ = menuButton.chair.rx.tap.bind {
            self.hideShowMenu()
            self.action.value = .chair
        }
        _ = menuButton.candle.rx.tap.bind {
            self.hideShowMenu()
            self.action.value = .candle
        }
        _ = menuButton.setting.rx.tap.bind {
            self.hideShowMenu()
            self.action.value = .measurement
        }
        _ = menuButton.reset.rx.tap.bind {
            self.hideShowMenu()
            self.action.value = .save
        }
        _ = menuButton.measurement.rx.tap.bind {
            let currentImage = self.menuButton.measurement.normalImage
            self.menuButton.measurement.normalImage = currentImage === MainConstants.Image.Menu.length ? MainConstants.Image.Menu.area : MainConstants.Image.Menu.length
            self.hideShowMenu()
            self.action.value = .reset
        }
        _ = menuButton.save.rx.tap.bind {
            self.hideShowMenu()
            self.action.value = .setting
        }
        _ = menuButton.more.rx.tap.bind {
            self.hideShowMenu()
            self.action.value = .more
        }
    }
    
    required convenience init(frame: CGRect) {
        self.init()
        menuButtonSet.frame = frame
        setUpMenu()
    }
    
    var isHidden: Bool = false {
        didSet {
            if isHidden {
                menuButtonSet.dismiss()
                menuButtonSet.hide()
            }
            menuButton.more.isHidden = isHidden
        }
    }

    private func hideShowMenu() {
        if menuButtonSet.isOn {
            menuButtonSet.dismiss()
            menuButton.more.normalImage = MainConstants.Image.More.close
        } else {
            menuButtonSet.show()
            menuButton.more.normalImage = MainConstants.Image.More.open
        }
    }
}
