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
    @IBOutlet weak var jointsLabel: MessageLabel!
    @IBOutlet weak var leftLabelX: MessageLabel!
    @IBOutlet weak var leftLabelY: MessageLabel!
    @IBOutlet weak var leftLabelZ: MessageLabel!
    @IBOutlet weak var modeLabel: UILabel!
    @IBOutlet weak var rightLabelX: MessageLabel!
    @IBOutlet weak var rightLabelY: MessageLabel!
    @IBOutlet weak var rightLabelZ: MessageLabel!
    @IBOutlet weak var fileLabels: UILabel!
    
    
    @IBOutlet weak var jointPicker: UIPickerView!
    @IBOutlet weak var toggleRecordButton: UIButton!
    
    
    // The 3D character to display.
    var character: BodyTrackedEntity?
    let characterOffset: SIMD3<Float> = [0.2, 0, 0] // Offset the character by one meter to the left
    let characterAnchor = AnchorEntity()
    
    let boxEntity = ModelEntity(mesh: MeshResource.generateBox(size: 0.01), materials: [SimpleMaterial(color: .green, isMetallic: true)])
    let boxEntity2 = ModelEntity(mesh: MeshResource.generateBox(size: 0.01), materials: [SimpleMaterial(color: .green, isMetallic: true)])
    let imageDisplayAnchor = AnchorEntity()
    let imageDisplayAnchor2 = AnchorEntity()

    // A tracked raycast which is used to place the character accurately
    // in the scene wherever the user taps.
    var placementRaycast: ARTrackedRaycast?
    var tapPlacementAnchor: AnchorEntity?
    
    //Picker data
    var pickerData: [[String]] = [[String]]()
    var leftPosIndex: Int = 19
    var rightPosIndex: Int = 0
    var trackingMode: Int = 0
    
    // Body position array
    var bodyPosArr: [[Float]] = []
    var imagePosArr: [[Float]] = []

    var recording: Bool = false
    var selectedExercise: Int = 0
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Picker:
        self.jointPicker.delegate = self
        self.jointPicker.dataSource = self
        pickerData = [ARSkeletonDefinition.defaultBody3D.jointNames,
                      ARSkeletonDefinition.defaultBody3D.jointNames,
                      ["Knee","Shoulder"]]
        
        arView.session.delegate = self
        jointPicker.selectRow(19, inComponent: 0, animated: true)




        //resetImageTracking()
        resetBodyTracking()
        refreshFiles()
        
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
            arView.scene.addAnchor(imageDisplayAnchor2)

            
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
        arView.scene.addAnchor(imageDisplayAnchor2)

        
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
                    character.scale = [0.5, 0.5, 0.5]
                    self.character = character
                    cancellable?.cancel()
                } else {
                    print("Error: Unable to load model as BodyTrackedEntity")
                }
            }
        )
        for(i, jointName) in ARSkeletonDefinition.defaultBody3D.jointNames.enumerated(){
            var parentIndex = ARSkeletonDefinition.defaultBody3D.parentIndices[i]
            if(parentIndex<0){
                parentIndex=0
            }
            //print(jointTransform)
            print("joint: " + i.description + " " + jointName + ", Parent: " + ARSkeletonDefinition.defaultBody3D.jointNames[parentIndex])
        }
        print("Body tracking enabled")

    }
    
    
    func resetWorldTracking() {
        
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        if #available(iOS 12.0, *) {
            let configuration = ARWorldTrackingConfiguration()
            configuration.detectionImages = referenceImages
            configuration.maximumNumberOfTrackedImages = 2
            configuration.automaticImageScaleEstimationEnabled = true
            arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            arView.scene.addAnchor(imageDisplayAnchor)
            arView.scene.addAnchor(imageDisplayAnchor2)
            
            jointPicker.isHidden = true
            print("Image tracking enabled")

        } else {
            // Fallback on earlier versions
        }
    }
    
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        var imageIndex:Int = 0
        imagePosArr.append(Array(repeating: 0, count: 6))
        bodyPosArr.append(Array(repeating: 0, count: 36))
        
        for anchor in anchors {
            /// Processsing for image detection
            if let imageAnchor = anchor as? ARImageAnchor {
                imageTrackingProcess(imageAnchor: imageAnchor, imageIndex: imageIndex)
                imageIndex += 1
            }
            
            /// Processing for body detection
            guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
            
            let skeleton = bodyAnchor.skeleton
            
            let jointModelTransforms = skeleton.jointModelTransforms
//            let jointLocalTransforms = skeleton.jointLocalTransforms

            var trackedJoints = 0
            /// Count tracked joints
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
            
            /// Display selected joints
            let leftModelTransform = jointModelTransforms[leftPosIndex]
            let rightModelTransform = jointModelTransforms[rightPosIndex]

        
            
            
            let estimatedHeight = bodyAnchor.estimatedScaleFactor * 1.8
            let labelString = "Tracked joints: " + trackedJoints.description + ", Scale: " + bodyAnchor.estimatedScaleFactor.description + ", Height: " + estimatedHeight.description
//            let labelString = "Tracked joints: " + trackedJoints.description + ", Scale: " + bodyAnchor.estimatedScaleFactor + ", Height: " + estimatedHeight.description
            jointsLabel.displayMessage(labelString, duration: 1)
//            leftLabelX.displayMessage("Model:\t" + leftJointName + leftModelPosition + "\t" + rightJointName + rightModelPosition, duration: 5)
//            leftLabelY.displayMessage("Local:\t" + leftJointName + leftLocalPosition + "\t" + rightJointName + rightLocalPosition, duration: 5)
            
            leftLabelX.displayMessage("X: " + leftModelTransform.columns.3.x.description.prefix(5), duration: 1)
            leftLabelY.displayMessage("Y: " + leftModelTransform.columns.3.y.description.prefix(5), duration: 1)
            leftLabelZ.displayMessage("Z: " + leftModelTransform.columns.3.z.description.prefix(5), duration: 1)

            rightLabelX.displayMessage("X: " + rightModelTransform.columns.3.x.description.prefix(5), duration: 1)
            rightLabelY.displayMessage("Y: " + rightModelTransform.columns.3.y.description.prefix(5), duration: 1)
            rightLabelZ.displayMessage("Z: " + rightModelTransform.columns.3.z.description.prefix(5), duration: 1)
            
            /// Record data
            let leftShoulderTransform = jointModelTransforms[20]
            let leftElbowTransform = jointModelTransforms[21]
            let leftWristTransform = jointModelTransforms[22]

            let leftThighTransform = jointModelTransforms[2]
            let leftKneeTransform = jointModelTransforms[3]
            let leftAnkleTransform = jointModelTransforms[4]
            
            let rightShoulderTransform = jointModelTransforms[64]
            let rightElbowTransform = jointModelTransforms[65]
            let rightWristTransform = jointModelTransforms[66]

            let rightThighTransform = jointModelTransforms[7]
            let rightKneeTransform = jointModelTransforms[8]
            let rightAnkleTransform = jointModelTransforms[9]
            
            if(recording){
                bodyPosArr[bodyPosArr.count-1] = [leftShoulderTransform.columns.3.x, leftShoulderTransform.columns.3.y, leftShoulderTransform.columns.3.z,
                                   leftElbowTransform.columns.3.x, leftElbowTransform.columns.3.y, leftElbowTransform.columns.3.z,
                                   leftWristTransform.columns.3.x, leftWristTransform.columns.3.y, leftWristTransform.columns.3.z,
                                   
                                   rightShoulderTransform.columns.3.x, rightShoulderTransform.columns.3.y, rightShoulderTransform.columns.3.z,
                                   rightElbowTransform.columns.3.x, rightElbowTransform.columns.3.y, rightElbowTransform.columns.3.z,
                                   rightWristTransform.columns.3.x, rightWristTransform.columns.3.y, rightWristTransform.columns.3.z,
                                   
                                   leftThighTransform.columns.3.x, leftThighTransform.columns.3.y, leftThighTransform.columns.3.z,
                                   leftKneeTransform.columns.3.x, leftKneeTransform.columns.3.y, leftKneeTransform.columns.3.z,
                                   leftAnkleTransform.columns.3.x, leftAnkleTransform.columns.3.y, leftAnkleTransform.columns.3.z,
                                   
                                   rightThighTransform.columns.3.x, rightThighTransform.columns.3.y, rightThighTransform.columns.3.z,
                                   rightKneeTransform.columns.3.x, rightKneeTransform.columns.3.y, rightKneeTransform.columns.3.z,
                                   rightAnkleTransform.columns.3.x, rightAnkleTransform.columns.3.y, rightAnkleTransform.columns.3.z]
                
//                bodyPosArr.append([leftShoulderTransform.columns.3.x, leftShoulderTransform.columns.3.y, leftShoulderTransform.columns.3.z,
//                                   leftElbowTransform.columns.3.x, leftElbowTransform.columns.3.y, leftElbowTransform.columns.3.z,
//                                   leftWristTransform.columns.3.x, leftWristTransform.columns.3.y, leftWristTransform.columns.3.z,
//
//                                   rightShoulderTransform.columns.3.x, rightShoulderTransform.columns.3.y, rightShoulderTransform.columns.3.z,
//                                   rightElbowTransform.columns.3.x, rightElbowTransform.columns.3.y, rightElbowTransform.columns.3.z,
//                                   rightWristTransform.columns.3.x, rightWristTransform.columns.3.y, rightWristTransform.columns.3.z,
//
//                                   leftThighTransform.columns.3.x, leftThighTransform.columns.3.y, leftThighTransform.columns.3.z,
//                                   leftKneeTransform.columns.3.x, leftKneeTransform.columns.3.y, leftKneeTransform.columns.3.z,
//                                   leftAnkleTransform.columns.3.x, leftAnkleTransform.columns.3.y, leftAnkleTransform.columns.3.z,
//
//                                   rightThighTransform.columns.3.x, rightThighTransform.columns.3.y, rightThighTransform.columns.3.z,
//                                   rightKneeTransform.columns.3.x, rightKneeTransform.columns.3.y, rightKneeTransform.columns.3.z,
//                                   rightAnkleTransform.columns.3.x, rightAnkleTransform.columns.3.y, rightAnkleTransform.columns.3.z,
//                ])
            }

            
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
        return 3
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
        case 2:
            selectedExercise = row
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
            modeLabel.text = "Image tracking only"

        }else if(trackingMode==1){
            trackingMode = 0
            resetImageTracking()
            modeLabel.text = "Image and body tracking"

        }
        
        print(trackingMode.description)
    }
    
    @IBAction func toggleRecording(_ sender: UIButton) {
        recording = !recording
        print(recording)
        print(bodyPosArr)
        if(!recording){
            toggleRecordButton.setTitle("Start Recording", for: .normal)
            createCSV()
        }else{
            toggleRecordButton.setTitle("Stop Recording", for: .normal)
            
        }
    }
    
    
    @IBAction func deleteFilesPressed(_ sender: UIButton) {
        deleteFiles()
    }
    
    @IBAction func uploadDataPressed(_ sender: UIButton) {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            print(dir)
            
            do{
                let fileURLs = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
                print(fileURLs)

                let activity = UIActivityViewController(activityItems: fileURLs, applicationActivities: nil)
                if let popoverController = activity.popoverPresentationController {
                    popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
                    popoverController.sourceView = self.view
                    popoverController.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
                }
                present(activity, animated: true)
            }catch{
                
            }
        }
    }
    
    @IBAction func refreshFilesPressed(_ sender: UIButton) {
        refreshFiles()
//        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
//             print(dir)
//
//             do{
//                let fileURLs = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
//                print(fileURLs)
//
//                var fileStr:String = ""
//
//                fileURLs.forEach({URL in
//                    fileStr += URL.lastPathComponent + ","
//
//                })
//                fileLabels.text = fileStr
//
//             }catch{
//
//             }
//         }
    }
    
    
}
