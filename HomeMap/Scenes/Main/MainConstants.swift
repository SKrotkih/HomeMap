//
//  MainConstants.swift
//  HomeMap
//
//  Created by Сергей Кротких on 12/05/2018.
//  Copyright © 2018 skappledev. All rights reserved.
//

import UIKit

class MainConstants: NSObject {

    struct Image {
        struct Menu {
            static let vase = #imageLiteral(resourceName: "menu_vase")
            static let chair = #imageLiteral(resourceName: "menu_chair")
            static let candle = #imageLiteral(resourceName: "menu_candle")
            static let area = #imageLiteral(resourceName: "menu_area")
            static let length = #imageLiteral(resourceName: "menu_length")
            static let reset = #imageLiteral(resourceName: "menu_reset")
            static let setting = #imageLiteral(resourceName: "menu_setting")
            static let save = #imageLiteral(resourceName: "menu_save")
        }
        struct Gallery {
            static let vase = #imageLiteral(resourceName: "menu_vase")
            static let chair = #imageLiteral(resourceName: "menu_chair")
            static let candle = #imageLiteral(resourceName: "menu_candle")
        }
        struct Indicator {
            static let enable = #imageLiteral(resourceName: "img_indicator_enable")
            static let disable = #imageLiteral(resourceName: "img_indicator_disable")
        }
        struct More {
            static let close = #imageLiteral(resourceName: "more_off")
            static let open = #imageLiteral(resourceName: "more_on")
        }
        struct Place {
            static let area = #imageLiteral(resourceName: "place_area")
            static let length = #imageLiteral(resourceName: "place_length")
            static let done = #imageLiteral(resourceName: "place_done")
        }
        struct Result {
            static let copy = #imageLiteral(resourceName: "result_copy")
        }
        struct Close {
            static let delete = #imageLiteral(resourceName: "cancle_delete")
            static let cancel = #imageLiteral(resourceName: "cancle_back")
        }
    }
    
    static let MainButtonSize: CGFloat = 80.0
    static let SecondButtonsSize: CGFloat = 60.0
    static let MenuButtonsSize: CGFloat = 50.0
    static let IndicatorSize: CGFloat = 60
    static let CopyButtonSize: CGFloat = 30
    
}
