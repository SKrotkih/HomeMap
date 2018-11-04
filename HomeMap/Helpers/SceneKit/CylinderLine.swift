//
//  CylinderLine.swift
//  HomeMap
//

import SceneKit

class CylinderLine: SCNNode {
    init( parent: SCNNode, v1: SCNVector3, v2: SCNVector3, radius: CGFloat, radSegmentCount: Int, color: UIColor)
    {
        super.init()
        
        let  height = v1.distance(receiver: v2)
        position = v1
        let nodeV2 = SCNNode()
        nodeV2.position = v2
        parent.addChildNode(nodeV2)
        
        let zAlign = SCNNode()
        zAlign.eulerAngles.x = Float(CGFloat.pi / 2)
        
        let cyl = SCNCylinder(radius: radius, height: CGFloat(height))
        cyl.radialSegmentCount = radSegmentCount
        cyl.firstMaterial?.diffuse.contents = color
        
        let nodeCyl = SCNNode(geometry: cyl )
        nodeCyl.position.y = -height/2
        zAlign.addChildNode(nodeCyl)
        
        addChildNode(zAlign)
        
        constraints = [SCNLookAtConstraint(target: nodeV2)]
    }
    
    override init() {
        super.init()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
