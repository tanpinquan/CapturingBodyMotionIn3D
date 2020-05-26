/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The sample app's main view controller.
*/

import UIKit
import RealityKit
import ARKit
import Combine
import CoreML


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
    let characterOffset: SIMD3<Float> = [0.5, 0, 0] // Offset the character by one meter to the left
    let characterAnchor = AnchorEntity()
    
    let boxEntity = ModelEntity(mesh: MeshResource.generateBox(size: 0.03), materials: [SimpleMaterial(color: .green, isMetallic: true)])
    let boxEntity2 = ModelEntity(mesh: MeshResource.generateBox(size: 0.03), materials: [SimpleMaterial(color: .green, isMetallic: true)])
    let planeEntity = ModelEntity(mesh: MeshResource.generatePlane(width: 0.1, depth: 0.2), materials: [UnlitMaterial(color: .red)])
    let planeEntity2 = ModelEntity(mesh: MeshResource.generatePlane(width: 0.1, depth: 0.2), materials: [UnlitMaterial(color: .red)])
//    let textEntity = ModelEntity(mesh: MeshResource.generateText("✓",
//                                                                 extrusionDepth: 0.00,
//                                                                 font: .systemFont(ofSize: 0.03),
//                                                                 containerFrame: CGRect.zero,
//                                                                 alignment: .left,
//                                                                 lineBreakMode: .byCharWrapping)
//                                 )
    let imageDisplayAnchor = AnchorEntity()
    let imageDisplayAnchor2 = AnchorEntity()

    // A tracked raycast which is used to place the character accurately
    // in the scene wherever the user taps.
    var placementRaycast: ARTrackedRaycast?
    var tapPlacementAnchor: AnchorEntity?
    
    //Picker data
    var pickerData: [[String]] = [[String]]()
    var leftPosIndex: Int = 19
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
            configuration.isAutoFocusEnabled = true
        
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
        configuration.automaticSkeletonScaleEstimationEnabled = true

//        configuration.maximumNumberOfTrackedImages = 2
//        configuration.detectionImages = referenceImages
//        configuration.automaticImageScaleEstimationEnabled = true
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
                    character.scale = [0.7, 0.7, 0.7]
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
//            let rightModelTransform = jointModelTransforms[rightPosIndex]

        
            
            
            let estimatedHeight = bodyAnchor.estimatedScaleFactor * 1.8
            let labelString = "Tracked joints: " + trackedJoints.description + ", Scale: " + bodyAnchor.estimatedScaleFactor.description + ", Height: " + estimatedHeight.description
//            let labelString = "Tracked joints: " + trackedJoints.description + ", Scale: " + bodyAnchor.estimatedScaleFactor + ", Height: " + estimatedHeight.description
            jointsLabel.displayMessage(labelString, duration: 1)
//            leftLabelX.displayMessage("Model:\t" + leftJointName + leftModelPosition + "\t" + rightJointName + rightModelPosition, duration: 5)
//            leftLabelY.displayMessage("Local:\t" + leftJointName + leftLocalPosition + "\t" + rightJointName + rightLocalPosition, duration: 5)
            
            leftLabelX.displayMessage("X: " + leftModelTransform.columns.3.x.description.prefix(5), duration: 1)
            leftLabelY.displayMessage("Y: " + leftModelTransform.columns.3.y.description.prefix(5), duration: 1)
            leftLabelZ.displayMessage("Z: " + leftModelTransform.columns.3.z.description.prefix(5), duration: 1)

//            rightLabelX.displayMessage("X: " + rightModelTransform.columns.3.x.description.prefix(5), duration: 1)
//            rightLabelY.displayMessage("Y: " + rightModelTransform.columns.3.y.description.prefix(5), duration: 1)
//            rightLabelZ.displayMessage("Z: " + rightModelTransform.columns.3.z.description.prefix(5), duration: 1)
            
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
            
            let dataSample: [Float] = [leftShoulderTransform.columns.3.x, leftShoulderTransform.columns.3.y, leftShoulderTransform.columns.3.z,
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
            
            addAccelSampleToDataArray(posSample: dataSample)
            if(recording){
                bodyPosArr[bodyPosArr.count-1] = dataSample
                
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
            selectedExercise = row
        default:
            leftPosIndex = 0
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
            resetBodyTracking()
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

    }


    /// Exercise Prediction
    struct ModelConstants {
        static let predictionWindowSize = 350
        static let stateInLength = 400
    }

    
    let shoulderExerciseModel = ShoulderExerciseClassifier()
    
    var currentIndexInPredictionWindow = 0

    let lShoulderX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lShoulderY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lShoulderZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)

    let lElbowX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lElbowY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lElbowZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)

    let lWristX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lWristY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lWristZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    
    let rShoulderX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rShoulderY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rShoulderZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)

    let rElbowX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rElbowY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rElbowZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)

    let rWristX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rWristY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rWristZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    
    let lThighX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lThighY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lThighZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)

    let lKneeX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lKneeY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lKneeZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)

    let lAnkleX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lAnkleY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lAnkleZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    
    let rThighX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rThighY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rThighZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)

    let rKneeX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rKneeY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rKneeZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)

    let rAnkleX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rAnkleY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rAnkleZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)

    var stateOutput = try! MLMultiArray(shape:[ModelConstants.stateInLength as NSNumber], dataType: MLMultiArrayDataType.double)
    
    func addAccelSampleToDataArray (posSample: [Float]) {
        // Add the current accelerometer reading to the data array
        lShoulderX[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[0] as NSNumber
        lShoulderY[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[1] as NSNumber
        lShoulderZ[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[2] as NSNumber
        
        lElbowX[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[3] as NSNumber
        lElbowY[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[4] as NSNumber
        lElbowZ[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[5] as NSNumber
        
        lWristX[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[6] as NSNumber
        lWristY[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[7] as NSNumber
        lWristZ[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[8] as NSNumber
        
        rShoulderX[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[9] as NSNumber
        rShoulderY[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[10] as NSNumber
        rShoulderZ[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[11] as NSNumber
        
        rElbowX[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[12] as NSNumber
        rElbowY[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[13] as NSNumber
        rElbowZ[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[14] as NSNumber
        
        rWristX[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[15] as NSNumber
        rWristY[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[16] as NSNumber
        rWristZ[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[17] as NSNumber

        
        lThighX[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[18] as NSNumber
        lThighY[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[19] as NSNumber
        lThighZ[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[20] as NSNumber
        
        lKneeX[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[21] as NSNumber
        lKneeY[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[22] as NSNumber
        lKneeZ[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[23] as NSNumber
        
        lAnkleX[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[24] as NSNumber
        lAnkleY[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[25] as NSNumber
        lAnkleZ[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[26] as NSNumber
        
        rThighX[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[27] as NSNumber
        rThighY[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[28] as NSNumber
        rThighZ[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[29] as NSNumber
        
        rKneeX[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[30] as NSNumber
        rKneeY[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[31] as NSNumber
        rKneeZ[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[32] as NSNumber
        
        rAnkleX[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[33] as NSNumber
        rAnkleY[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[34] as NSNumber
        rAnkleZ[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[35] as NSNumber
        
        // Update the index in the prediction window data array
        currentIndexInPredictionWindow += 1

        // If the data array is full, call the prediction method to get a new model prediction.
        // We assume here for simplicity that the Gyro data was added to the data arrays as well.
        if (currentIndexInPredictionWindow == ModelConstants.predictionWindowSize) {
            if let predictedActivity = performModelPrediction() {

                // Use the predicted activity here
                rightLabelX.displayMessage(predictedActivity, duration: 1)
                print(predictedActivity)

                if(predictedActivity=="shoulder_left"){
                    rightLabelX.backgroundColor = .green
                }else if(predictedActivity=="shoulder_right"){
                    rightLabelX.backgroundColor = .blue
                }


                // Start a new prediction window
                currentIndexInPredictionWindow = 0
            }else{
                rightLabelX.displayMessage("No Activity", duration: 1)
                rightLabelX.backgroundColor = .red
                print("No Activity")
            }
        }
    }
    func performModelPrediction () -> String? {
        // Perform model prediction
        let modelPrediction = try! shoulderExerciseModel.prediction(
            l_shoulder_x: lShoulderX, l_shoulder_y: lShoulderY, l_shoulder_z: lShoulderZ,
            l_elbow_x: lElbowX, l_elbow_y: lElbowY, l_elbow_z: lElbowZ,
            l_wrist_x: lWristX, l_wrist_y: lWristY, l_wrist_z: lWristZ,
            r_shoulder_x: rShoulderX, r_shoulder_y: rShoulderY, r_shoulder_z: rShoulderZ,
            r_elbow_x: rElbowX, r_elbow_y: rElbowY, r_elbow_z: rElbowZ,
            r_wrist_x: rWristX, r_wrist_y: rWristY, r_wrist_z: rWristZ,
            l_thigh_x: lThighX, l_thigh_y: lThighY, l_thigh_z: lThighZ,
            l_knee_x: lKneeX, l_knee_y: lKneeY, l_knee_z: lKneeZ,
            l_ankle_x: lAnkleX, l_ankle_y: lAnkleY, l_ankle_z: lAnkleZ,
            r_thigh_x: rThighX, r_thigh_y: rThighY, r_thigh_z: rThighZ,
            r_knee_x: rKneeX, r_knee_y: rKneeY, r_knee_z: rKneeZ,
            r_ankle_x: rAnkleX, r_ankle_y: rAnkleY, r_ankle_z: rAnkleZ,
            stateIn: stateOutput)

        // Update the state vector
        stateOutput = modelPrediction.stateOut

        // Return the predicted activity - the activity with the highest probability
        return modelPrediction.activity
    }
    
    
}
