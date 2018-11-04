//
//  ChartView.swift
//  HomeMap
//
//  Created by Сергей Кротких on 11/05/2018.
//  Copyright © 2018 skappledev. All rights reserved.
//

import UIKit
import RxSwift

class ChartView: UIView {

    enum State {
        case hide
        case middle
        case full
    }

    var currentViewSize = Variable<State>(.hide)
    
    @IBOutlet var previewSceneView: SCNView!
    @IBOutlet weak var previewResizeButtonImageView: UIImageView!
    
    private var chartModel: ChartModel!

    func configure(_ superView: UIView, y: CGFloat) {
        var frame = self.frame
        frame.origin.y = y
        frame.size.width = superView.frame.width
        self.frame = frame
        superView.addSubview(self)
        
        self.backgroundColor = UIColor.white.withAlphaComponent(0.8)

        previewSceneView.allowsCameraControl = true
        previewSceneView.backgroundColor = UIColor.black
        guard let scene = SCNScene(named: "Assets.scnassets/CameraSetup.scn")
            else {
                print("Impossible to load the scene")
                return
        }
        previewSceneView.scene = scene
        
        chartModel = ChartModel(scene)

        do {
            let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDownGesture(_:)))
            swipeDown.direction = .down
            previewResizeButtonImageView.addGestureRecognizer(swipeDown)
            let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeUpGesture(_:)))
            swipeUp.direction = .up
            previewResizeButtonImageView.addGestureRecognizer(swipeUp)
        }
        setState(to: .hide)
    }
    
    @objc func handleSwipeDownGesture(_ recognizer: UIPanGestureRecognizer) {
        guard currentState == .hide || currentState == .middle else {
            return
        }
        setState(to: currentState == .hide ? .middle : .full)
    }
    
    @objc func handleSwipeUpGesture(_ recognizer: UIPanGestureRecognizer) {
        guard currentState == .full || currentState == .middle else {
            return
        }
        setState(to: currentState == .full ? .middle : .hide)
    }

    private var currentState: State = .hide
    
    private func setState(to state: State) {
        guard let superView = self.superview else {
            return
        }
        let screenWidth = superView.bounds.width
        let screenHeight = superView.bounds.height
        var _frame = self.frame
        _frame.size.width = screenWidth
        
        let midleHeight = screenHeight * 0.3
        let kStatBarHeight: CGFloat = 20.0
        let fullHeight = screenHeight - (_frame.minY + kStatBarHeight)

        switch state {
        case .hide:
            _frame.size.height = previewResizeButtonImageView.frame.height
            currentViewSize.value = .middle
        case .middle:
            _frame.size.height = midleHeight
            currentViewSize.value = .middle
        case .full:
            _frame.size.height = fullHeight
            currentViewSize.value = .full
        }
        
        UIView.animate(withDuration: 0.3, animations: {[unowned self] in
            self.frame = _frame
            superView.setNeedsLayout()
            }, completion: { [unowned self] (finished) in
                self.currentState = state
        })
    }

    func cleanGraph() {
        chartModel.cleanScene()
    }

    func present(lineSet: LineSetNode) {
        chartModel.lineSet = lineSet
    }
}
