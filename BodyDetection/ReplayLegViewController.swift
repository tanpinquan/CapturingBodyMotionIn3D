//
//  ReplayLegViewController.swift
//  BodyDetection
//
//  Created by Pin Quan Tan on 8/6/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit
import SceneKit

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
        
        
        let node = SCNNode(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0))

        node.position = SCNVector3(0,0,0)

        scene.rootNode.addChildNode(node)
        
        // set the scene to the view
        scnView.scene = scene
        scnView.delegate = self
        scnView.isPlaying = true
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
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
