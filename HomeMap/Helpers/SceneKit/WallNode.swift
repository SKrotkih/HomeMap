//
//  CylinderLine.swift
//  HomeMap
//

import SceneKit

class WallNode: SCNNode {

    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(parentNode: SCNNode, startPos: SCNVector3, endPos: SCNVector3, color: UIColor, height: Float)
    {
        super.init()

        //                                parentNode
        //          |                                               |
        //         self   .position = v1 (startNode.position)     endNode    .position = endPos (endNode.position)
        //          |
        //       zAlignNode :
        //          |
        //      planeNode  .SCNGeometry = planeGeometry: SCNPlane
        //
        //        let planeGeometry = SCNPlane()
        //        let planeMaterial = SCNMaterial.material(withDiffuse: color, respondsToLighting: true)
        //        planeMaterial.isDoubleSided = true
        //        planeGeometry.materials = [planeMaterial]
        //        planeNode.geometry = planeGeometry
        //        planeNode.position = SCNVector3Make(0.0, -width/2.0, 0.0)
        //        planeNode.eulerAngles = SCNVector3Make(0.0, .pi/2, 0.0)     // Vertical
        
        let endNode = SCNNode()
        parentNode.addChildNode(endNode)
        let zAlignNode = SCNNode()
        let planeNode = buildPlaneNode(startPos: startPos, endPos: endPos, color: color, height: height)
        zAlignNode.addChildNode(planeNode)
        self.addChildNode(zAlignNode)
        self.constraints = [SCNLookAtConstraint(target: endNode)]
        
        // Geometry
        self.position = startPos
        endNode.position = endPos
        zAlignNode.eulerAngles.x = .pi/2
    }
    
    private func buildPlaneNode(startPos: SCNVector3, endPos: SCNVector3, color: UIColor, height h: Float) -> SCNNode {
        let w = startPos.distance(receiver: endPos)
        let vertices:[SCNVector3] = [
            SCNVector3(x: 0, y: 0, z: 0),   // 0 0
            SCNVector3(x: 0, y: -w, z: -h), // 1 2
            SCNVector3(x: 0, y: -w, z: 0),  // 2 3
            SCNVector3(x: 0, y: 0, z: 0),   // 3 0
            SCNVector3(x: 0, y: 0, z: -h),  // 4 1
            SCNVector3(x: 0, y: -w, z: -h)  // 5 2
        ]
        let normals: [SCNVector3] = [
            SCNVector3(x: 0, y: 0, z: 1),   // 0
            SCNVector3(x: 0, y: 0, z: 1),   // 2
            SCNVector3(x: 0, y: 0, z: 1),   // 3
            SCNVector3(x: 0, y: 0, z: 1),   // 0
            SCNVector3(x: 0, y: 0, z: 1),   // 1
            SCNVector3(x: 0, y: 0, z: 1)    // 2
        ]
        let indices: [Int32] = [0, 1, 2, 3, 4, 5]

        let vertexSource = SCNGeometrySource(vertices: vertices)
        let normalSource = SCNGeometrySource(vertices: normals)
        let pointer = UnsafeRawPointer(indices)
        let indexData = NSData(bytes: pointer, length: MemoryLayout<Int32>.size * indices.count)
        let element = SCNGeometryElement(data: indexData as Data, primitiveType: .triangles, primitiveCount: indices.count / 3, bytesPerIndex: MemoryLayout<Int32>.size)
        let geometry = SCNGeometry(sources: [vertexSource, normalSource], elements: [element])
        let planeMaterial = SCNMaterial.material(withDiffuse: color)
        geometry.materials = [planeMaterial]
        let node = SCNNode()
        node.geometry = geometry
        return node
    }
}
