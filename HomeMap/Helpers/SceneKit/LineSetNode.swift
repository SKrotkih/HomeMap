//
//  LineSetNode.swift
//  HomeMap
//

import UIKit
import SceneKit
import ARKit

class LineSetNode: NSObject {
    
    private let kLinesColor = (UIColor.blue, UIColor.blue)
    private let kLinesFont = UIFont.systemFont(ofSize: 6)
    
    // Public vars
    private(set) var lines = [LineNode]()
    private(set) var textNode: SCNNode?
    
    // Private vars
    private var mCurrentLine: LineNode!
    private var mCloseLine: LineNode?
    private let mSceneView: ARSCNView
    
    init(sceneView: ARSCNView) {
        mSceneView = sceneView
        super.init()
    }
    
    func startLine() {
        let currentEndPosition = mCurrentLine.endNode.position
        startLine(at: currentEndPosition)
        resetCloseLine()
    }

    func startLine(at startPos: SCNVector3) {
        let line = LineNode(startPos: startPos,
                            sceneV: mSceneView,
                            color: kLinesColor,
                            font: kLinesFont)
        mCurrentLine = line
        lines.append(line)
        createTextIfNeeded()
    }
    
    func terminateLine(at pos: SCNVector3, camera: ARCamera?) {
        _ = mCurrentLine.terminateLine(at: pos, camera: camera)
        _ = mCloseLine?.terminateLine(at: pos, camera: camera)
        updateText()
    }

    func terminateSet() {
        guard let closeLine = mCloseLine else {
            return
        }
        updateText()
        mCurrentLine = closeLine
        lines.append(closeLine)
        createTextIfNeeded()
    }
    
    func removeLastLine() -> Bool {
        guard let lastLine = lines.popLast(), lines.count >= 1 else {
            resetCloseLine()
            return false
        }
        lastLine.removeFromParent()
        mCurrentLine = lines.last!
        resetCloseLine()
        return true
    }
    
    func removeAllLines() {
        lines.forEach() {
            $0.removeFromParent()
        }
        textNode?.removeFromParentNode()
    }
    
    var area: Float {
        guard lines.count >= 2 else {
            textNode?.isHidden = true
            return 0
        }
        var points = lines.map({ $0.endNode.position })
        points.append(lines[0].startNode.position)
        let area = computePolygonArea(points: points)
        return area
    }
}

// MARK: - Private

extension LineSetNode {
    
    private func createTextIfNeeded() {
        if let _ = textNode {
            return
        }
        let text = SCNText (string: "--", extrusionDepth: 0.1)
        text.font = UIFont.boldSystemFont(ofSize: 10)
        text.firstMaterial?.diffuse.contents = UIColor.white
        text.alignmentMode  = kCAAlignmentCenter
        text.truncationMode = kCATruncationMiddle
        text.firstMaterial?.isDoubleSided = true
        textNode = SCNNode(geometry: text)
        textNode?.scale = SCNVector3(1/500.0, 1/500.0, 1/500.0)
        textNode?.isHidden = true
    }

    private func updateText() {
        if lines.count >= 2 {
            var points = lines.map({ $0.endNode.position })
            points.append(lines[0].startNode.position)
            if let textNode = self.textNode {
                var center = points.average ?? points[0]
                center.y += 0.002
                let text = textNode.geometry as! SCNText
                let unit = ApplicationSetting.Status.defaultUnit
                text.string = MeasurementUnit(meterUnitValue: area, isArea: true).string(type: unit)
                textNode.setPivot()
                textNode.position = center
                textNode.isHidden = false
                if textNode.parent == nil {
                    mSceneView.scene.rootNode.addChildNode(textNode)
                }
            }
        } else {
            textNode?.isHidden = true
        }
    }
    
    private func resetCloseLine() {
        mCloseLine?.removeFromParent()
        mCloseLine = nil
        if lines.count > 1 {
            let closeLine = LineNode(startPos: lines[0].startNode.position,
                                     sceneV: mSceneView,
                                     color: kLinesColor,
                                     font: kLinesFont)
            mCloseLine = closeLine
        }
    }
    
    private func computePolygonArea(points: [SCNVector3]) -> Float {
        return abs(area3DPolygonFormPointCloud(points: points))
    }
}
