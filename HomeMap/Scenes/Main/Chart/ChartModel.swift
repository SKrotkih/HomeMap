//
//  ChartModel.swift
//  HomeMap
//
//  Created by Сергей Кротких on 06/05/2018.
//  Copyright © 2018 skappledev. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ChartModel: NSObject {

    // Constants
    private let kWallsHeight: Float = 0.1
    private let kWallsColor = UIColor.yellow
    
    // Private vars
    private var mScene: SCNScene

    private var mLineSets: [LineSetNode] = []
    private var mNodes: [SCNNode] = []

    private var mPositionNodes: [SCNVector3] {
        var arr = [SCNVector3]()
        mLineSets.forEach() { lineSetNode in
            lineSetNode.lines.forEach() { lineNode in
                let startPos = lineNode.startNode.position
                let endPos = lineNode.endNode.position
                arr.append(startPos)
                arr.append(endPos)
            }
        }
        return arr
    }
    
    // Public vars
    var lineSet: LineSetNode? {
        didSet {
            guard let lineSet = lineSet else {
                return
            }
            mLineSets.append(lineSet)
            buildScene()
        }
    }
    
    init(_ scene: SCNScene) {
        self.mScene = scene
        super.init()
    }

    private func buildScene() {
        guard mLineSets.count > 0 else {
            return
        }
        buildWalls()
        drawTexts()
        setUpLight()
        setUpCamera()
        
        mScene.rootNode.rotation = SCNVector4Make(1, 0, 0, .pi/2)
        
    }

    private func buildWalls() {
        mLineSets.forEach() { lineSetNode in
            lineSetNode.lines.forEach() { lineNode in
                lineNode.startNode.position.y = 0.0
                lineNode.endNode.position.y = 0.0
                let startPos = lineNode.startNode.position
                let endPos = lineNode.endNode.position
                let wallNode = WallNode(parentNode: mScene.rootNode, startPos: startPos, endPos: endPos, color: kWallsColor, height: kWallsHeight)
                mScene.rootNode.addChildNode(wallNode)
                mNodes.append(wallNode)
            }
        }
    }
    
    private func drawTexts() {
        mLineSets.forEach() { lineSetNode in
            if let textNode = lineSetNode.textNode?.clone() {    // If you have node hierarchy, you can use
                // the flattenedClone() method and obtain a new
                // single node containing the combined geometries
                // and materials of the node and its child node subtree.
                textNode.position.y = 0
                mScene.rootNode.addChildNode(textNode)
                mNodes.append(textNode)
            }
            lineSetNode.lines.forEach() { lineNode in
                if let textNode = lineNode.textNode?.clone() {
                    textNode.position.y = 0
                    mScene.rootNode.addChildNode(textNode)
                    mNodes.append(textNode)
                }
            }
        }
    }
    
    private func setUpLight() {
        let coords = self.mPositionNodes
        
        coords.forEach() { coord in
            print("\(coord)")
        }

        let spotLight = SCNLight()
        spotLight.type = .omni    //spot
        spotLight.color = UIColor.white
        spotLight.castsShadow = true
        spotLight.shadowColor = UIColor.lightGray
        spotLight.spotInnerAngle = 45
        spotLight.spotOuterAngle = 45
        
        let spotNode = SCNNode()
        spotNode.light = spotLight
        spotNode.position = SCNVector3Make(0.0, 0.0, 0.2)

//        spotNode.rotation = SCNVector4Make(1, 0, 0, .pi/2.0)
//        spotNode.eulerAngles = SCNVector3Make(-.pi/2.0, 0, 0);
        
        mScene.rootNode.addChildNode(spotNode)
    }
    
    private func setUpCamera() {
        let camera = SCNCamera()
        let cameraNode = SCNNode()
        camera.automaticallyAdjustsZRange = true
        cameraNode.camera = camera
        cameraNode.rotation = SCNVector4Make(1, 0, 0, .pi/2.0)
        // cameraNode.position = SCNVector3Make(0.0, 0.3, 0.0)
        // cameraNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1, 0, 0)
        // cameraNode.eulerAngles = SCNVector3Make(.pi/2.0, 0, 0);
        mScene.rootNode.addChildNode(cameraNode)
    }
    
    func cleanScene() {

//        for node in mScene.rootNode.childNodes {
//            node.removeFromParentNode()
//        }
        
        mNodes.forEach() {
            $0.removeFromParentNode()
        }
        mNodes.removeAll()
        mLineSets.removeAll()
    }
}
