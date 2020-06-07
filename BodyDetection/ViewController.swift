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
    @IBOutlet weak var modeLabel: MessageLabel!
    @IBOutlet weak var rightLabelX: MessageLabel!
    @IBOutlet weak var rightLabelY: MessageLabel!
    @IBOutlet weak var rightLabelZ: MessageLabel!
    @IBOutlet weak var fileLabels: UILabel!
    @IBOutlet var predLabel: MessageLabel!
    
    
    @IBOutlet weak var jointPicker: UIPickerView!
    @IBOutlet weak var toggleRecordButton: UIButton!
    
    
    // The 3D character to display.
    var character: BodyTrackedEntity?
    let characterOffset: SIMD3<Float> = [0.5, 0, 0] // Offset the character by one meter to the left
    let characterAnchor = AnchorEntity()
    
    var replayCharacter: BodyTrackedEntity?
    let characterReplayAnchor = AnchorEntity()

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
    var numRecordedJoints: Int = 12
    let jointIndexArr: [Int] = [19, 20, 21, 22,
                                63, 64, 65, 66,
                                2, 3, 4,
                                7, 8, 9]
    
    var replay: Bool = false
    var bodyAnchorArr: [ARBodyAnchor] = []

    var recording: Bool = false
    var selectedExercise: Int = 0
    var selectedAngle: Float = 0
    
    var latestPreditcion: String = ""
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Picker:
        var angleArr: [Int] = []
        for angle in stride(from: -180, to: 180, by: 10) {
            angleArr.append(angle)
        }
        self.jointPicker.delegate = self
        self.jointPicker.dataSource = self
        pickerData = [ARSkeletonDefinition.defaultBody3D.jointNames,
                      ["Knee","Shoulder"],
                      angleArr.map(String.init)
        ]
        
        arView.session.delegate = self
        jointPicker.selectRow(19, inComponent: 0, animated: true)
        jointPicker.selectRow(18, inComponent: 2, animated: true)

        //resetImageTracking()
        resetBodyTracking()
        refreshFiles()
//        readFile()
        numRecordedJoints = jointIndexArr.count
        
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
//        arView.scene.addAnchor(characterReplayAnchor)

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
    
    func resetReplayConfiguration() {
        guard ARBodyTrackingConfiguration.isSupported else {
             fatalError("This feature is only supported on devices with an A12 chip")
         }
   
        
        if #available(iOS 12.0, *) {
            let configuration = ARWorldTrackingConfiguration()
    
            arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            arView.scene.addAnchor(characterReplayAnchor)
            
            print("Replay tracking enabled")

            
            var cancellableReplay: AnyCancellable? = nil
            cancellableReplay = Entity.loadBodyTrackedAsync(named: "character/robot_replay").sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        print("Error: Unable to load model: \(error.localizedDescription)")
                    }
                    cancellableReplay?.cancel()
                }, receiveValue: { (character: Entity) in
                    if let character = character as? BodyTrackedEntity {
                        // Scale the character to human size
                        character.scale = [0.25, 0.25, 0.25]
                        self.replayCharacter = character
                        cancellableReplay?.cancel()
                    } else {
                        print("Error: Unable to load model as BodyTrackedEntity")
                    }
                }
            )
        } else {
            // Fallback on earlier versions
        }
    }
    
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        var imageIndex:Int = 0
        imagePosArr.append(Array(repeating: 0, count: 6))
        bodyPosArr.append(Array(repeating: 0, count: numRecordedJoints*6))
        
        for anchor in anchors {
            /// Processsing for image detection
            if let imageAnchor = anchor as? ARImageAnchor {
                imageTrackingProcess(imageAnchor: imageAnchor, imageIndex: imageIndex)
                imageIndex += 1
            }
            
            /// Processing for body detection
            guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
            bodyTrackingProcess(bodyAnchor: bodyAnchor)
            

        }
//        if(replay){
//        /// Replay recorded positio
//            if(bodyAnchorArr.count>1){
//                bodyReplayProcess(bodyAnchor: bodyAnchorArr[0])
//            }
//        }
    }
    var currentReplayIndex = 0

    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if(replay){
          /// Replay recorded positio
              if(bodyAnchorArr.count>1){
                  bodyReplayProcess(bodyAnchor: bodyAnchorArr[currentReplayIndex])
                currentReplayIndex += 1
                if(currentReplayIndex == bodyAnchorArr.count){
                    currentReplayIndex = 0
                }
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
            selectedExercise = row
        case 2:
            selectedAngle = Float(row*10-180)
            print("angle" + selectedAngle.description)
        default:
            leftPosIndex = 0
        }
    }
    

    
    
    // MARK: Actions
    @IBAction func swapTracking(_ sender: UIButton) {
        if(trackingMode==0){
            trackingMode = 1
            resetImageTracking()
            sender.setTitle("Track Body", for: .normal)
            modeLabel.text = "Image tracking only"

        }else if(trackingMode==1){
            trackingMode = 0
            resetBodyTracking()
            sender.setTitle("Track Image", for: .normal)
            modeLabel.text = "Image and body tracking"

        }
        
        print(trackingMode.description)
    }
    
    @IBAction func toggleRecording(_ sender: UIButton) {
        recording = !recording
        print(recording)
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

    @IBAction func toggleReplay(_ sender: UIButton) {
        
//        if(trackingMode==0){
//            trackingMode = 1
//            resetImageTracking()
//            sender.setTitle("Track Body", for: .normal)
//            modeLabel.text = "Image tracking only"
//
//        }else if(trackingMode==1){
//            trackingMode = 0
//            resetBodyTracking()
//            sender.setTitle("Track Image", for: .normal)
//            modeLabel.text = "Image and body tracking"
//
//        }
        
        print(trackingMode.description)
        replay = !replay
        if(!replay){
            sender.setTitle("Replay", for: .normal)
            resetBodyTracking()

        }else{
            sender.setTitle("Track", for: .normal)
            resetReplayConfiguration()

        }
    }
    
    @IBAction func replayScreen(_ sender: UIButton) {
        if(!bodyAnchorArr.isEmpty){
            arView.session.pause()
            performSegue(withIdentifier: "goToReplay", sender: nil)
        }
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
//    {
//        // Determine what the segue destination is
//        if segue.destination is ReplayViewController
//        {
//            let vc = segue.destination as? ReplayViewController
//            vc?.bodyAnchorArr = bodyAnchorArr
//        }
//    }
    /// Exercise Prediction
   
    
    struct ModelConstants {
        static let predictionWindowSize = 75
        static let stateInLength = 400
        static let numFeatures = 84
    }
    let shoulderAbductionModel = ShoulderAbductionClassifier75()
    var currentIndexInPredictionWindow = 0
    
    let lShoulderX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lShoulderY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lShoulderZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lShoulderR = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lShoulderP = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lShoulderYaw = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    
    let lArmX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lArmY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lArmZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lArmR = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lArmP = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lArmYaw = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    
    let lElbowX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lElbowY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lElbowZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lElbowR = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lElbowP = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lElbowYaw = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    
    let lWristX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lWristY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lWristZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lWristR = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lWristP = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let lWristYaw = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    
    let rShoulderX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rShoulderY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rShoulderZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rShoulderR = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rShoulderP = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rShoulderYaw = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    
    let rArmX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rArmY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rArmZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rArmR = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rArmP = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rArmYaw = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    
    let rElbowX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rElbowY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rElbowZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rElbowR = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rElbowP = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rElbowYaw = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    
    let rWristX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rWristY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rWristZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rWristR = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rWristP = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let rWristYaw = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)

    var lElbowAngle:[Float] = Array(repeating: 0.0, count: ModelConstants.predictionWindowSize)
    var rElbowAngle:[Float] = Array(repeating: 0.0, count: ModelConstants.predictionWindowSize)
//    var inputArr: [MLMultiArray] = Array(repeating: try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double), count: ModelConstants.numFeatures)
    
    var stateOutput = try! MLMultiArray(shape:[ModelConstants.stateInLength as NSNumber], dataType: MLMultiArrayDataType.double)

    
    func addAccelSampleToDataArray (posSample: [Float], jointAngleSample: [Float]) {
           // Add the current accelerometer reading to the data array
        
//        lShoulderX[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[0] as NSNumber
//        lShoulderY[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[1] as NSNumber
//        lShoulderZ[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[2] as NSNumber
//        lShoulderR[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[3] as NSNumber
//        lShoulderP[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[4] as NSNumber
//        lShoulderYaw[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[5] as NSNumber
        
//        lArmX[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[6] as NSNumber
//        lArmY[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[7] as NSNumber
//        lArmZ[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[8] as NSNumber
        lArmR[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[9] as NSNumber
        lArmP[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[10] as NSNumber
        lArmYaw[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[11] as NSNumber
        
        lElbowX[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[12] as NSNumber
        lElbowY[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[13] as NSNumber
        lElbowZ[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[14] as NSNumber
//        lElbowR[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[15] as NSNumber
//        lElbowP[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[16] as NSNumber
//        lElbowYaw[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[17] as NSNumber
        
        lWristX[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[18] as NSNumber
        lWristY[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[19] as NSNumber
        lWristZ[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[20] as NSNumber
//        lWristR[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[21] as NSNumber
//        lWristP[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[22] as NSNumber
//        lWristYaw[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[23] as NSNumber

//        rShoulderX[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[24] as NSNumber
//        rShoulderY[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[25] as NSNumber
//        rShoulderZ[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[26] as NSNumber
//        rShoulderR[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[27] as NSNumber
//        rShoulderP[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[28] as NSNumber
//        rShoulderYaw[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[29] as NSNumber
        
//        rArmX[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[30] as NSNumber
//        rArmY[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[31] as NSNumber
//        rArmZ[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[32] as NSNumber
        rArmR[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[33] as NSNumber
        rArmP[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[34] as NSNumber
        rArmYaw[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[35] as NSNumber
        
        rElbowX[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[36] as NSNumber
        rElbowY[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[37] as NSNumber
        rElbowZ[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[38] as NSNumber
//        rElbowR[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[39] as NSNumber
//        rElbowP[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[40] as NSNumber
//        rElbowYaw[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[41] as NSNumber
        
        rWristX[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[42] as NSNumber
        rWristY[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[43] as NSNumber
        rWristZ[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[44] as NSNumber
//        rWristR[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[45] as NSNumber
//        rWristP[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[46] as NSNumber
//        rWristYaw[[currentIndexInPredictionWindow] as [NSNumber]] = posSample[47] as NSNumber
        
        lElbowAngle[currentIndexInPredictionWindow] = jointAngleSample[0]
        rElbowAngle[currentIndexInPredictionWindow] = jointAngleSample[1]
        
           
           
       // Update the index in the prediction window data array
       currentIndexInPredictionWindow += 1

           // If the data array is full, call the prediction method to get a new model prediction.
           // We assume here for simplicity that the Gyro data was added to the data arrays as well.
        if (currentIndexInPredictionWindow == ModelConstants.predictionWindowSize) {
//            print(rArmR.description)
           if let predictedActivity = performModelPrediction() {
            latestPreditcion = predictedActivity
            
               // Use the predicted activity here
  
            print(predictedActivity)
            var labelText:String = ""

            if(predictedActivity.starts(with: "shoulder_left")){
                let averageElbowAngle = lElbowAngle.reduce(0,+) / Float(ModelConstants.predictionWindowSize)
                labelText = predictedActivity + ", Elbow Angle: " + averageElbowAngle.description.prefix(3)
                if averageElbowAngle < 140 {
                    labelText = labelText + ", STRAIGHTEN ELBOW"
                }
                predLabel.backgroundColor = .green
            }else if(predictedActivity.starts(with: "shoulder_right")){
                let averageElbowAngle = rElbowAngle.reduce(0,+) / Float(ModelConstants.predictionWindowSize)
                labelText = predictedActivity + ", Elbow Angle: " + averageElbowAngle.description.prefix(3)
                if averageElbowAngle < 140 {
                    labelText = labelText + ", STRAIGHTEN ELBOW"
                }
                predLabel.backgroundColor = .blue
            }else if(predictedActivity=="standing"){
                labelText = predictedActivity
                predLabel.backgroundColor = .red
            }
            predLabel.text = labelText


            // Start a new prediction window
            currentIndexInPredictionWindow = 0
           }
       }
   }
    
   func performModelPrediction () -> String? {
//    print(rArmR)
//    print(lArmR)
    
       // Perform model prediction
    let modelPrediction = try!shoulderAbductionModel.prediction(

        l_arm_r: lArmR, l_arm_p: lArmP,
        l_elbow_x: lElbowX, l_elbow_y: lElbowY,
        l_wrist_x: lWristX, l_wrist_y: lWristY,
        
        r_arm_r: rArmR, r_arm_p: rArmP,
        r_elbow_x: rElbowX, r_elbow_y: rElbowY,
        r_wrist_x: rWristX, r_wrist_y: rWristY,
                
        stateIn: stateOutput)
    
//    let modelPrediction = try!shoulderAbductionModel.prediction(
//        l_shoulder_x: lShoulderX, l_shoulder_y: lShoulderY, l_shoulder_z: lShoulderZ,
//        l_shoulder_r: lShoulderR, l_shoulder_p: lShoulderP, l_shoupder_yaw: lShoulderY,
//
//        l_arm_x: lArmX, l_arm_y: lArmY, l_arm_z: lArmZ,
//        l_arm_r: lArmR, l_arm_p: lArmP, l_arm_yaw: lArmYaw,
//
//        l_elbow_x: lElbowX, l_elbow_y: lElbowY, l_elbow_z: lElbowZ,
//        l_elbow_r: lElbowR, l_elbow_p: lElbowP, l_elbow_yaw: lElbowYaw,
//
//        l_wrist_x: lWristX, l_wrist_y: lWristY, l_wrist_z: lWristZ,
//        l_wrist_r: lWristR, l_wrist_p: lWristP, l_wrist_yaw: lWristYaw,
//
//        r_shoulder_x: rShoulderX, r_shoulder_y: rShoulderY, r_shoulder_z: rShoulderZ,
//        r_shoulder_r: rShoulderR, r_shoulder_p: rShoulderP, r_shoupder_yaw: rShoulderYaw,
//
//        r_arm_x: rArmX, r_arm_y: rArmY, r_arm_z: rArmZ,
//        r_arm_r: rArmR, r_arm_p: rArmP, r_arm_yaw: rArmYaw,
//
//        r_elbow_x: rElbowX, r_elbow_y: rElbowY, r_elbow_z: rElbowZ,
//        r_elbow_r: rElbowR, r_elbow_p: rElbowP, r_elbow_yaw: rElbowYaw,
//
//        r_wrist_x: rWristX, r_wrist_y: rWristY, r_wrist_z: rWristZ,
//        r_wrist_r: rWristR, r_wrist_p: rWristP, r_wrist_yaw: rWristYaw,
//
//        stateIn: stateOutput)
//

       // Update the state vector
       stateOutput = modelPrediction.stateOut

       // Return the predicted activity - the activity with the highest probability
       return modelPrediction.activity
   }
   
}
