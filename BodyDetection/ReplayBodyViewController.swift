//
//  ReplayViewController.swift
//  BodyDetection
//
//  Created by Pin Quan Tan on 6/6/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ReplayBodyViewController: UIViewController, SCNSceneRendererDelegate {
    var bodyAnchorArr: [ARBodyAnchor] = []
    var recordingKey:String = ""
    @IBOutlet var scnView: SCNView!
    
    let scene = SCNScene()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.navigationController?.navigationBar.isHidden = false

        bodyAnchorArr = loadBodyRecording(key: recordingKey)
  
        
        // create and add a camera to the scene
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)

        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 5)

        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)

        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        
        createSkeleton(bodyAnchor: bodyAnchorArr[0], scene: scene)
        // retrieve the SCNView
//        let scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
        scnView.delegate = self
        scnView.isPlaying = true
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view
//        scnView.backgroundColor = UIColor.black
    }
    
    var currReplayIndex : Int = 0
    var updateTime:TimeInterval = 0
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time:
        TimeInterval) {
//        print("render: " + time.description + " " + updateTime.description + " " + currReplayIndex.description)

        
        if(time > updateTime){
            updateSkeleton(bodyAnchor: bodyAnchorArr[currReplayIndex], scene: scene)
            currReplayIndex += 1
            if(currReplayIndex == bodyAnchorArr.count){
                currReplayIndex = 0
            }
            updateTime = time + TimeInterval(1/60)

        }
            
        

    }
    func createSkeleton(bodyAnchor: ARBodyAnchor, scene: SCNScene) -> Void {
        let jointModelTransforms = bodyAnchor.skeleton.jointModelTransforms
        for(jointIndex, jointName) in ARSkeletonDefinition.defaultBody3D.jointNames.enumerated(){
            let parentIndex = ARSkeletonDefinition.defaultBody3D.parentIndices[jointIndex]
            if(parentIndex>0){
                let jointPos = SCNVector3(simd_make_float3(jointModelTransforms[jointIndex].columns.3))
                let parentPos = SCNVector3(simd_make_float3(jointModelTransforms[parentIndex].columns.3))
                let node = lineBetweenNodes(positionA: parentPos, positionB: jointPos, inScene: scene)
                node.name = jointName
                scene.rootNode.addChildNode(node)

            }
        }
        
//        for node in scene.rootNode.childNodes{
//            print(node.name ?? "NO NAME")
//        }
    }
    
    func updateSkeleton(bodyAnchor: ARBodyAnchor, scene: SCNScene) -> Void {
        let jointModelTransforms = bodyAnchor.skeleton.jointModelTransforms
        for(jointIndex, jointName) in ARSkeletonDefinition.defaultBody3D.jointNames.enumerated(){
            let parentIndex = ARSkeletonDefinition.defaultBody3D.parentIndices[jointIndex]
            if(parentIndex>0){
                let jointPos = SCNVector3(simd_make_float3(jointModelTransforms[jointIndex].columns.3))
                let parentPos = SCNVector3(simd_make_float3(jointModelTransforms[parentIndex].columns.3))
                let node = scene.rootNode.childNode(withName: jointName, recursively: true)
                updateNode(node: node!, positionA: parentPos, positionB: jointPos, inScene: scene)
          

            }
        }
        
    }
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

func lineBetweenNodes(positionA: SCNVector3, positionB: SCNVector3, inScene: SCNScene) -> SCNNode {
    let vector = SCNVector3(positionA.x - positionB.x, positionA.y - positionB.y, positionA.z - positionB.z)
    let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
    let midPosition = SCNVector3 (x:(positionA.x + positionB.x) / 2, y:(positionA.y + positionB.y) / 2, z:(positionA.z + positionB.z) / 2)

    let lineGeometry = SCNCylinder()
    lineGeometry.radius = 0.02
    lineGeometry.height = CGFloat(distance)
    lineGeometry.radialSegmentCount = 5
    lineGeometry.firstMaterial!.diffuse.contents = UIColor.gray

    let lineNode = SCNNode(geometry: lineGeometry)
    lineNode.position = midPosition
    lineNode.look (at: positionB, up: inScene.rootNode.worldUp, localFront: lineNode.worldUp)
    return lineNode
}

func updateNode(node: SCNNode, positionA: SCNVector3, positionB: SCNVector3, inScene: SCNScene) -> Void {
    let vector = SCNVector3(positionA.x - positionB.x, positionA.y - positionB.y, positionA.z - positionB.z)
    let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
    let midPosition = SCNVector3 (x:(positionA.x + positionB.x) / 2, y:(positionA.y + positionB.y) / 2, z:(positionA.z + positionB.z) / 2)

    let lineGeometry = SCNCylinder()
    lineGeometry.radius = 0.02
    lineGeometry.height = CGFloat(distance)
    lineGeometry.radialSegmentCount = 5
    lineGeometry.firstMaterial!.diffuse.contents = UIColor.gray

    node.position = midPosition
    node.look (at: positionB, up: inScene.rootNode.worldUp, localFront: inScene.rootNode.worldUp)
//    print(positionA)
//    print(positionB)
//    print(inScene.rootNode.worldUp)
//    print(node.worldUp)
}

extension SCNGeometry {
    class func line(from vector1: SCNVector3, to vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        return SCNGeometry(sources: [source], elements: [element])
    }
}
