//
//  LineNode.swift
//  HomeMap
//

import UIKit
import SceneKit
import ARKit

class LineNode: NSObject {
    
    // Public vars
    let startNode: SCNNode
    let endNode: SCNNode
    var lineNode: SCNNode?
    var wallNode: SCNNode?
    
    // Private vars
    private(set) var textNode: SCNNode?
    private let mTextFont: UIFont
    private let mSceneView: ARSCNView?
    private var mRecentFocusSquarePositions = [SCNVector3]()

    let occlusionPlaneVerticalOffset: Float = -0.01

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        removeFromParent()
    }
    
    init(startPos: SCNVector3, sceneV: ARSCNView, color: (start: UIColor, end: UIColor) = (UIColor.green, UIColor.red), font: UIFont = UIFont.boldSystemFont(ofSize: 10) ) {
        mSceneView = sceneV
        mTextFont = font

        func buildSCNSphere(color: UIColor) -> SCNSphere {
            let dot = SCNSphere(radius: 1)
            dot.firstMaterial?.diffuse.contents = color
            dot.firstMaterial?.lightingModel = .constant
            dot.firstMaterial?.isDoubleSided = true
            return dot
        }

        let scale = 1/400.0
        let scaleVector = SCNVector3(scale, scale, scale)
        // Start Sphere
        startNode = SCNNode(geometry: buildSCNSphere(color: color.start))
        startNode.scale = scaleVector
        startNode.position = startPos
        mSceneView?.scene.rootNode.addChildNode(startNode)
        // End Sphere
        endNode = SCNNode(geometry: buildSCNSphere(color: color.end))
        endNode.scale = scaleVector
        
        lineNode = nil
        super.init()
    }
    
    public func terminateLine(at pos: SCNVector3, camera: ARCamera?) {
        let posEnd = updateTransform(for: pos, camera: camera)
        
        if endNode.parent == nil {
            // Add the EndSphere
            mSceneView?.scene.rootNode.addChildNode(endNode)
        }
        endNode.position = posEnd
        setTextBetween(nodeA: startNode, nodeB: endNode)
        
        lineNode?.removeFromParentNode()
        lineNode = lineBetweenNodeA(nodeA: startNode, nodeB: endNode)
        mSceneView?.scene.rootNode.addChildNode(lineNode!)
    }

    var length: Float {
        return endNode.position.distanceFromPos(pos: startNode.position)
    }
    
    private func setTextBetween(nodeA startNode: SCNNode, nodeB endNode: SCNNode) {
        createTextNode()
        if let textNode = textNode {
            let posStart = startNode.position
            let posEnd = endNode.position
            let middle = SCNVector3((posStart.x+posEnd.x)/2.0, (posStart.y+posEnd.y)/2.0+0.002, (posStart.z+posEnd.z)/2.0)
            let length = posEnd.distanceFromPos(pos: startNode.position)
            let text = textNode.geometry as! SCNText
            let unit = ApplicationSetting.Status.defaultUnit
            text.string = MeasurementUnit(meterUnitValue: length).string(type: unit)
            textNode.setPivot()
            textNode.position = middle
            if textNode.parent == nil {
                mSceneView?.scene.rootNode.addChildNode(textNode)
            }
        }
    }
    
    private func createTextNode() {
        if let _ = textNode {
            return
        }
        let text = SCNText (string: "--", extrusionDepth: 0.1)
        text.font = mTextFont
        text.firstMaterial?.diffuse.contents = UIColor.white
        text.alignmentMode  = kCAAlignmentCenter
        text.truncationMode = kCATruncationMiddle
        text.firstMaterial?.isDoubleSided = true
        textNode = SCNNode(geometry: text)
        textNode?.scale = SCNVector3(1/500.0, 1/500.0, 1/500.0)
    }
    
    func removeFromParent() -> Void {
        startNode.removeFromParentNode()
        endNode.removeFromParentNode()
        lineNode?.removeFromParentNode()
        textNode?.removeFromParentNode()
        wallNode?.removeFromParentNode()
    }
    
    // MARK: - Private
    
    private func lineBetweenNodeA(nodeA: SCNNode, nodeB: SCNNode) -> SCNNode {
        
        return CylinderLine(parent: mSceneView!.scene.rootNode,
                            v1: nodeA.position,
                            v2: nodeB.position,
                            radius: 0.001,
                            radSegmentCount: 16,
                            color: UIColor.white)
        
    }
    
    
    private func updateTransform(for position: SCNVector3, camera: ARCamera?) -> SCNVector3 {
        mRecentFocusSquarePositions.append(position)
        mRecentFocusSquarePositions.keepLast(8)
        if let camera = camera {
            let tilt = abs(camera.eulerAngles.x)
            let threshold1: Float = Float.pi / 2 * 0.65
            let threshold2: Float = Float.pi / 2 * 0.75
            let yaw = atan2f(camera.transform.columns.0.x, camera.transform.columns.1.x)
            var angle: Float = 0
            
            switch tilt {
            case 0..<threshold1:
                angle = camera.eulerAngles.y
            case threshold1..<threshold2:
                let relativeInRange = abs((tilt - threshold1) / (threshold2 - threshold1))
                let normalizedY = normalize(camera.eulerAngles.y, forMinimalRotationTo: yaw)
                angle = normalizedY * (1 - relativeInRange) + yaw * relativeInRange
            default:
                angle = yaw
            }
            textNode?.runAction(SCNAction.rotateTo(x: 0, y: CGFloat(angle), z: 0, duration: 0))
        }
        
        if let average = mRecentFocusSquarePositions.average {
            return average
        }
        
        return SCNVector3Zero
    }
    
    private func normalize(_ angle: Float, forMinimalRotationTo ref: Float) -> Float {

        var normalized = angle
        while abs(normalized - ref) > Float.pi / 4 {
            if angle > ref {
                normalized -= Float.pi / 2
            } else {
                normalized += Float.pi / 2
            }
        }
        return normalized
    }
}

