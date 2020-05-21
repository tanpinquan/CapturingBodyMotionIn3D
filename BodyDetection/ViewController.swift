/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The sample app's main view controller.
*/

import UIKit
import RealityKit
import ARKit
import Combine

class ViewController: UIViewController, ARSessionDelegate, UIPickerViewDelegate, UIPickerViewDataSource, ARSCNViewDelegate {

    

    @IBOutlet var arView: ARView!
    @IBOutlet weak var messageLabel: MessageLabel!
    @IBOutlet weak var messageLabel2: MessageLabel!
    @IBOutlet weak var messageLabel3: MessageLabel!
    @IBOutlet weak var jointPicker: UIPickerView!
    
    
    // The 3D character to display.
    var character: BodyTrackedEntity?
    let characterOffset: SIMD3<Float> = [1.0, 0, 0] // Offset the character by one meter to the left
    let characterAnchor = AnchorEntity()
    
    let boxEntity = ModelEntity(mesh: MeshResource.generateBox(size: 0.01), materials: [SimpleMaterial(color: .green, isMetallic: true)])
    let imageDisplayAnchor = AnchorEntity()
    
    // A tracked raycast which is used to place the character accurately
    // in the scene wherever the user taps.
    var placementRaycast: ARTrackedRaycast?
    var tapPlacementAnchor: AnchorEntity?
    
    //Picker data
    var pickerData: [[String]] = [[String]]()
    var leftPosIndex: Int = 0
    var rightPosIndex: Int = 0
    var trackingMode: Int = 0
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Picker:
        self.jointPicker.delegate = self
        self.jointPicker.dataSource = self
        pickerData = [ARSkeletonDefinition.defaultBody3D.jointNames,
                      ARSkeletonDefinition.defaultBody3D.jointNames]
        
        arView.session.delegate = self




        //resetImageTracking()
        resetBodyTracking()
        
    }
    
    func resetImageTracking() {
        
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        if #available(iOS 12.0, *) {
            let configuration = ARImageTrackingConfiguration()
            configuration.trackingImages = referenceImages
            configuration.maximumNumberOfTrackedImages = 2
            arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            arView.scene.addAnchor(imageDisplayAnchor)
            
            
            jointPicker.isHidden = true
            print("Image tracking enabled")

        } else {
            // Fallback on earlier versions
        }


    }
    
    func resetBodyTracking(){
        // If the iOS device doesn't support body tracking, raise a developer error for
        // this unhandled case.
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }
        jointPicker.isHidden = false

        // Run a body tracking configration.
        let configuration = ARBodyTrackingConfiguration()
        configuration.maximumNumberOfTrackedImages = 2
        configuration.detectionImages = referenceImages
        configuration.automaticSkeletonScaleEstimationEnabled = true
        configuration.automaticImageScaleEstimationEnabled = true
        configuration.isAutoFocusEnabled = true
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        arView.scene.addAnchor(characterAnchor)
        arView.scene.addAnchor(imageDisplayAnchor)

        
        // Asynchronously load the 3D character.
        var cancellable: AnyCancellable? = nil
        cancellable = Entity.loadBodyTrackedAsync(named: "character/robot").sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error: Unable to load model: \(error.localizedDescription)")
                }
                cancellable?.cancel()
            }, receiveValue: { (character: Entity) in
                if let character = character as? BodyTrackedEntity {
                    // Scale the character to human size
                    character.scale = [1.0, 1.0, 1.0]
                    self.character = character
                    cancellable?.cancel()
                } else {
                    print("Error: Unable to load model as BodyTrackedEntity")
                }
            }
        )
        for(i, jointName) in ARSkeletonDefinition.defaultBody3D.jointNames.enumerated(){
            //print(jointTransform)
            print("joint: " + i.description + " " + jointName )
        }
        print("Body tracking enabled")

    }
    
    
    
//    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        guard let imageAnchor = anchor as? ARImageAnchor else { return }
//        //let referenceImage = imageAnchor.referenceImage
//        let imagePosition = String(format: ": %.2f,\t%.2f,\t%.2f", imageAnchor.transform.columns.3.x, imageAnchor.transform.columns.3.y, imageAnchor.transform.columns.3.z)
//        print((imageAnchor.referenceImage.name ?? "") + imagePosition)
//
//
//    }
    
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let imageAnchor = anchor as? ARImageAnchor {
                //let referenceImage = imageAnchor.referenceImage
                let imagePosition = String(format: ": %.2f,\t%.2f,\t%.2f", imageAnchor.transform.columns.3.x, imageAnchor.transform.columns.3.y, imageAnchor.transform.columns.3.z)
                print((imageAnchor.referenceImage.name ?? "") + imagePosition)
                messageLabel.displayMessage("Tracking Images", duration: 5)

                if(imageAnchor.referenceImage.name == "fatburger"){
                    messageLabel2.displayMessage((imageAnchor.referenceImage.name ?? "") + imagePosition, duration: 1)
                }else{
                    messageLabel3.displayMessage((imageAnchor.referenceImage.name ?? "") + imagePosition, duration: 1)
                    imageDisplayAnchor.position = simd_make_float3(imageAnchor.transform.columns.3)
                    imageDisplayAnchor.orientation = Transform(matrix: imageAnchor.transform).rotation
                    imageDisplayAnchor.addChild(boxEntity)
                }
            }
            
            guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
            
            let skeleton = bodyAnchor.skeleton
            
            let jointModelTransforms = skeleton.jointModelTransforms
            let jointLocalTransforms = skeleton.jointLocalTransforms

            var trackedJoints = 0

            for(i, _) in jointModelTransforms.enumerated(){
                //print(jointTransform)
                let parentIndex = skeleton.definition.parentIndices[ i ]
                if(skeleton.isJointTracked(i)){ 
                   trackedJoints = trackedJoints+1;
                }else{
                    guard parentIndex != -1 else {continue}
//                    print("joint: " + i.description + " " + ARSkeletonDefinition.defaultBody3D.jointNames[i] + "\t parent: " + parentIndex.description + " " + ARSkeletonDefinition.defaultBody3D.jointNames[parentIndex] + "\t tracked:" + skeleton.isJointTracked(i).description )
                }

            }
            
            
            //let leftFootIndex = ARSkeletonDefinition.defaultBody3D.index(for: .leftFoot)
            let leftJointName = ARSkeletonDefinition.defaultBody3D.jointNames[leftPosIndex]
            let leftModelTransform = jointModelTransforms[leftPosIndex]
            let leftModelPosition = String(format: ": %.2f,\t%.2f,\t%.2f", leftModelTransform.columns.3.x, leftModelTransform.columns.3.y, leftModelTransform.columns.3.z)
            
            //let rightFootIndex = ARSkeletonDefinition.defaultBody3D.index(for: .rightFoot)
            let rightJointName = ARSkeletonDefinition.defaultBody3D.jointNames[rightPosIndex]
            let rightModelTransform = jointModelTransforms[rightPosIndex]
            let rightModelPosition = String(format: ": %.2f,\t%.2f,\t%.2f", rightModelTransform.columns.3.x, rightModelTransform.columns.3.y, rightModelTransform.columns.3.z)
            
            let leftLocalTransform = jointLocalTransforms[leftPosIndex]
            let leftLocalPosition = String(format: ": %.2f,\t%.2f,\t%.2f", leftLocalTransform.columns.3.x, leftLocalTransform.columns.3.y, leftLocalTransform.columns.3.z)

            let rightLocalTransform = jointLocalTransforms[rightPosIndex]
            let rightLocalPosition = String(format: ": %.2f,\t%.2f,\t%.2f", rightLocalTransform.columns.3.x, rightLocalTransform.columns.3.y, rightLocalTransform.columns.3.z)
            
            
            messageLabel.displayMessage("Tracked joints: " + trackedJoints.description, duration: 5)
            messageLabel2.displayMessage("Model:\t" + leftJointName + leftModelPosition + "\t" + rightJointName + rightModelPosition, duration: 5)
            messageLabel3.displayMessage("Local:\t" + leftJointName + leftLocalPosition + "\t" + rightJointName + rightLocalPosition, duration: 5)


            
            // Update the position of the character anchor's position.
            let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
            characterAnchor.position = bodyPosition + characterOffset
            // Also copy over the rotation of the body anchor, because the skeleton's pose
            // in the world is relative to the body anchor's rotation.
            characterAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation
               
            if let character = character, character.parent == nil {
                // Attach the character to its anchor as soon as
                // 1. the body anchor was detected and
                // 2. the character was loaded.
                characterAnchor.addChild(character)
            }
        }
    }
    
    // Picker functions
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData[component].count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[component][row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0:
            leftPosIndex = row
        case 1:
            rightPosIndex = row
        default:
            leftPosIndex = 0
            rightPosIndex = 0
        }
    }
    
    // MARK: Actions
    @IBAction func swapTracking(_ sender: UIButton) {
        if(trackingMode==0){
            trackingMode = 1
            resetImageTracking()
        }else if(trackingMode==1){
            trackingMode = 0
            resetBodyTracking()
        }
        
        print(trackingMode.description)
    }
    
    
    
}
