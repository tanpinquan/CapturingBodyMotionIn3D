//
//  ReplayLegViewController.swift
//  BodyDetection
//
//  Created by Pin Quan Tan on 8/6/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ReplayLegViewController: UIViewController, SCNSceneRendererDelegate {
    var recordingKey:String = ""
    var legRecording:LegRecording = LegRecording(thighAnchors: [], calfAnchors: [])

    @IBOutlet var scnView: SCNView!
    let scene = SCNScene()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.navigationController?.navigationBar.isHidden = false

        legRecording = loadLegRecording(key: recordingKey)
        print(legRecording.thighAnchors.count.description)
        
        
        // create and add a camera to the scene
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)

        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0.25, z: 5)

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
        
        createLeg(thighAnchor: legRecording.thighAnchors[0], calfAnchor: legRecording.calfAnchors[0], scene: scene)
        
//        let rotateY = simd_quatf(angle: GLKMathDegreesToRadians(90), axis: SIMD3(x: 0, y: 1, z: 0))
        let plane = SCNPlane(width: 5, height: 5)
        plane.firstMaterial?.diffuse.contents = UIColor.lightGray
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3(0,legRecording.thighAnchors[0].transform.columns.3.y-0.15,legRecording.thighAnchors[0].transform.columns.3.z)
        planeNode.eulerAngles = SCNVector3Make(-.pi/2, 0, 0)
        scene.rootNode.addChildNode(planeNode)
        
        // set the scene to the view
        scnView.scene = scene
        scnView.delegate = self
        scnView.isPlaying = true
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
    }
    
    var currReplayIndex : Int = 0
    var updateTime:TimeInterval = 0
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    //        print("render: " + time.description + " " + updateTime.description + " " + currReplayIndex.description)

        
        if(time > updateTime){
            updateLeg(thighAnchor: legRecording.thighAnchors[currReplayIndex], calfAnchor: legRecording.calfAnchors[currReplayIndex], scene: scene)
            currReplayIndex += 1
            if(currReplayIndex == legRecording.thighAnchors.count){
                currReplayIndex = 0
            }
            updateTime = time + TimeInterval(1/60)

        }

    }
    

    
    func createLeg(thighAnchor: ARImageAnchor, calfAnchor: ARImageAnchor, scene: SCNScene) -> Void {
        let jointLength = simd_float3(x: 0.1, y: 0, z: 0)
        let rotateY = simd_quatf(angle: GLKMathDegreesToRadians(90), axis: SIMD3(x: 0, y: 0, z: 1))

//        let thighStart = SCNVector3(simd_make_float3(thighAnchor.transform.columns.3)-jointLength)
//        let thighEnd = SCNVector3(simd_make_float3(thighAnchor.transform.columns.3)+jointLength)
//        let thighNode = lineBetweenNodes(positionA: thighStart, positionB: thighEnd, inScene: scene)
        let trackingCylinder = SCNCylinder(radius: 0.01, height: 0.2)
        trackingCylinder.firstMaterial?.diffuse.contents = UIColor.green

        let thighNode = SCNNode(geometry: trackingCylinder)
        thighNode.position = SCNVector3(simd_make_float3(thighAnchor.transform.columns.3))
        thighNode.transform = SCNMatrix4(thighAnchor.transform)
        thighNode.name = "thigh"
//        let thighBox = SCNNode(geometry: SCNBox(width: 0.5, height: 0.1, length: 0.1, chamferRadius: 0.01))
//        thighBox.position = SCNVector3(-0.15, 0, 0)
//        thighNode.addChildNode(thighBox)
        scene.rootNode.addChildNode(thighNode)

        let thighCylinder = SCNNode(geometry: SCNCylinder(radius: 0.05, height: 0.5))
        thighCylinder.position = SCNVector3(-0.15, 0, 0)
        thighCylinder.simdOrientation = rotateY
        thighNode.addChildNode(thighCylinder)

        
        let calfNode = SCNNode(geometry: trackingCylinder)
        calfNode.position = SCNVector3(simd_make_float3(calfAnchor.transform.columns.3))
        calfNode.transform = SCNMatrix4(thighAnchor.transform)
        calfNode.name = "calf"
        
//        let calfBox = SCNNode(geometry: SCNBox(width: 0.3, height: 0.1, length: 0.1, chamferRadius: 0.01))
//        calfBox.position = SCNVector3(0.0, 0, 0)
//        calfNode.addChildNode(calfBox)
//        scene.rootNode.addChildNode(calfNode)

        let calfCylinder = SCNNode(geometry: SCNCylinder(radius: 0.05, height: 0.3))
        calfCylinder.position = SCNVector3(-0.0, 0, 0)
        calfCylinder.simdOrientation = rotateY
        calfNode.addChildNode(calfCylinder)
        
        
//        let calfStart = SCNVector3(simd_make_float3(calfAnchor.transform.columns.3)-jointLength)
//        let calfEnd = SCNVector3(simd_make_float3(calfAnchor.transform.columns.3)+jointLength)
//        let calfNode = lineBetweenNodes(positionA: calfStart, positionB: calfEnd, inScene: scene)
//        calfNode.name = "calf"
        scene.rootNode.addChildNode(calfNode)

        
    }
    
    func updateLeg(thighAnchor: ARImageAnchor, calfAnchor: ARImageAnchor, scene: SCNScene) -> Void {
        
        let jointLength = simd_float3(x: 0.1, y: 0, z: 0)
        
        let thighStart = SCNVector3(simd_make_float3(thighAnchor.transform.columns.3)-jointLength)
        let thighEnd = SCNVector3(simd_make_float3(thighAnchor.transform.columns.3)+jointLength)
        let thighNode = scene.rootNode.childNode(withName: "thigh", recursively: true)
        thighNode!.position = SCNVector3(simd_make_float3(thighAnchor.transform.columns.3))
        thighNode!.transform = SCNMatrix4(thighAnchor.transform)
//        updateNode(node: thighNode!, positionA: thighStart, positionB: thighEnd, inScene: scene)

        let calfNode = scene.rootNode.childNode(withName: "calf", recursively: true)
        calfNode!.position = SCNVector3(simd_make_float3(calfAnchor.transform.columns.3))
        calfNode!.transform = SCNMatrix4(calfAnchor.transform)
        
        
        
//        let calfStart = SCNVector3(simd_make_float3(calfAnchor.transform.columns.3)-jointLength)
//        let calfEnd = SCNVector3(simd_make_float3(calfAnchor.transform.columns.3)+jointLength)
//        let calfNode = scene.rootNode.childNode(withName: "calf", recursively: true)
//        updateNode(node: calfNode!, positionA: calfStart, positionB: calfEnd, inScene: scene)
        

        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */



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
    
}
