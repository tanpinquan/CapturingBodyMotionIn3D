//
//  ViewController+BodyTracking.swift
//  BodyDetection
//
//  Created by Pin Quan Tan on 24/5/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import RealityKit
import ARKit

extension ViewController{
    
    func imageTrackingProcess(imageAnchor:ARImageAnchor, imageIndex:Int) -> Void {
        let imagePosition = String(format: ": %.2f,\t%.2f,\t%.2f", imageAnchor.transform.columns.3.x, imageAnchor.transform.columns.3.y, imageAnchor.transform.columns.3.z)
        print((imageAnchor.referenceImage.name ?? "") + imagePosition)

        if(imageIndex==0){
            rightLabelX.displayMessage((imageAnchor.referenceImage.name ?? "") + imagePosition, duration: 1)
            imageDisplayAnchor.position = simd_make_float3(imageAnchor.transform.columns.3)
            imageDisplayAnchor.orientation = Transform(matrix: imageAnchor.transform).rotation
            imageDisplayAnchor.addChild(planeEntity)
//            imageDisplayAnchor.addChild(textEntity)
        }else if(imageIndex==1){
            rightLabelY.displayMessage((imageAnchor.referenceImage.name ?? "") + imagePosition, duration: 1)
            imageDisplayAnchor2.position = simd_make_float3(imageAnchor.transform.columns.3)
            imageDisplayAnchor2.orientation = Transform(matrix: imageAnchor.transform).rotation
            imageDisplayAnchor2.addChild(planeEntity2)
        }else{
            rightLabelZ.displayMessage((imageAnchor.referenceImage.name ?? "") + imagePosition, duration: 1)

        }
        
        if(imageAnchor.referenceImage.name == "meiji1"){
            
            imagePosArr[imagePosArr.count-1][0...2] = [imageAnchor.transform.columns.3.x, imageAnchor.transform.columns.3.y, imageAnchor.transform.columns.3.z]
//            imagePosArr0.append([imageAnchor.transform.columns.3.x, imageAnchor.transform.columns.3.y, imageAnchor.transform.columns.3.z])
        }else if(imageAnchor.referenceImage.name == "meiji2"){
            imagePosArr[imagePosArr.count-1][3...5] = [imageAnchor.transform.columns.3.x, imageAnchor.transform.columns.3.y, imageAnchor.transform.columns.3.z]
//            imagePosArr1.append([imageAnchor.transform.columns.3.x, imageAnchor.transform.columns.3.y, imageAnchor.transform.columns.3.z])
        }
    }
    
    func bodyTrackingProcess(bodyAnchor:ARBodyAnchor) -> Void {
        
        let skeleton = bodyAnchor.skeleton
                    
        let jointModelTransforms = skeleton.jointModelTransforms
        let jointLocalTransforms = skeleton.jointLocalTransforms

        var trackedJoints = 0
        /// Count tracked joints
        for(i, _) in jointModelTransforms.enumerated(){
            //print(jointTransform)
            let parentIndex = skeleton.definition.parentIndices[ i ]
            if(skeleton.isJointTracked(i)){
               trackedJoints = trackedJoints+1;
            }else{
                guard parentIndex != -1 else {continue}

            }

        }
        
        /// Display selected joints
        let selectedJointLocalTransform = jointLocalTransforms[leftPosIndex]
        let selectedJointModelTransform = jointModelTransforms[leftPosIndex]

        let estimatedHeight = bodyAnchor.estimatedScaleFactor * 1.8
        let labelString = "Tracked joints: " + trackedJoints.description + ", Scale: " + bodyAnchor.estimatedScaleFactor.description + ", Height: " + estimatedHeight.description

        jointsLabel.displayMessage(labelString, duration: 1)

        let selectedJointLocalNode = SCNNode()
        let selectedJointModelNode = SCNNode()
        selectedJointLocalNode.transform = SCNMatrix4(selectedJointLocalTransform)
        selectedJointModelNode.transform = SCNMatrix4(selectedJointModelTransform)

        leftLabelX.displayMessage("X: " + selectedJointModelNode.position.x.description.prefix(5), duration: 1)
        leftLabelY.displayMessage("Y: " + selectedJointModelNode.position.y.description.prefix(5), duration: 1)
        leftLabelZ.displayMessage("Z: " + selectedJointModelNode.position.z.description.prefix(5), duration: 1)
    
        rightLabelX.displayMessage("R: " + selectedJointLocalNode.eulerAngles.x.description.prefix(5), duration: 1)
        rightLabelY.displayMessage("P: " + selectedJointLocalNode.eulerAngles.y.description.prefix(5), duration: 1)
        rightLabelZ.displayMessage("Ymu: " + selectedJointLocalNode.eulerAngles.z.description.prefix(5), duration: 1)
        
        
        let jointAngle = computeJointAngle(
            startJointPos: simd_make_float3(jointModelTransforms[64].columns.3),
            middleJointPos: simd_make_float3(jointModelTransforms[65].columns.3),
            endJointPos: simd_make_float3(jointModelTransforms[66].columns.3)
            ) * 180 / .pi
        modeLabel.text = jointAngle.description
        
//            let dataSample: [Float] = [n.position.x]
        
        /// Record data
        let jointLocalNodesArr: [SCNNode] = Array(repeating: SCNNode(), count: numRecordedJoints)
        let jointModelNodesArr: [SCNNode] = Array(repeating: SCNNode(), count: numRecordedJoints)

        var dataSample: [Float] = Array(repeating: 0.0, count: numRecordedJoints*6)
//        print("START RECORD")
        for (arrIndex, jointIndex) in jointIndexArr.enumerated() {
            jointLocalNodesArr[arrIndex].transform = SCNMatrix4(jointLocalTransforms[jointIndex])
            jointModelNodesArr[arrIndex].transform = SCNMatrix4(jointModelTransforms[jointIndex])
            dataSample[arrIndex*6+0] = jointModelNodesArr[arrIndex].position.x
            dataSample[arrIndex*6+1] = jointModelNodesArr[arrIndex].position.y
            dataSample[arrIndex*6+2] = jointModelNodesArr[arrIndex].position.z
            dataSample[arrIndex*6+3] = jointLocalNodesArr[arrIndex].eulerAngles.x
            dataSample[arrIndex*6+4] = jointLocalNodesArr[arrIndex].eulerAngles.y
            dataSample[arrIndex*6+5] = jointLocalNodesArr[arrIndex].eulerAngles.x
            
//            print(arrIndex, jointIndex)
            
        }
//        print(dataSample.description)
        
        
        
        
        
//        
//        let leftShoulderTransform = jointLocalTransforms[20]
//        let leftElbowTransform = jointLocalTransforms[21]
//        let leftWristTransform = jointLocalTransforms[22]
//
//        let leftThighTransform = jointLocalTransforms[2]
//        let leftKneeTransform = jointLocalTransforms[3]
//        let leftAnkleTransform = jointLocalTransforms[4]
//        
//        let rightShoulderTransform = jointLocalTransforms[64]
//        let rightElbowTransform = jointLocalTransforms[65]
//        let rightWristTransform = jointLocalTransforms[66]
//
//        let rightThighTransform = jointLocalTransforms[7]
//        let rightKneeTransform = jointLocalTransforms[8]
//        let rightAnkleTransform = jointLocalTransforms[9]
//        
//
//        
//        let dataSample: [Float] = [leftShoulderTransform.columns.3.x, leftShoulderTransform.columns.3.y, leftShoulderTransform.columns.3.z,
//        leftElbowTransform.columns.3.x, leftElbowTransform.columns.3.y, leftElbowTransform.columns.3.z,
//        leftWristTransform.columns.3.x, leftWristTransform.columns.3.y, leftWristTransform.columns.3.z,
//        
//        rightShoulderTransform.columns.3.x, rightShoulderTransform.columns.3.y, rightShoulderTransform.columns.3.z,
//        rightElbowTransform.columns.3.x, rightElbowTransform.columns.3.y, rightElbowTransform.columns.3.z,
//        rightWristTransform.columns.3.x, rightWristTransform.columns.3.y, rightWristTransform.columns.3.z,
//        
//        leftThighTransform.columns.3.x, leftThighTransform.columns.3.y, leftThighTransform.columns.3.z,
//        leftKneeTransform.columns.3.x, leftKneeTransform.columns.3.y, leftKneeTransform.columns.3.z,
//        leftAnkleTransform.columns.3.x, leftAnkleTransform.columns.3.y, leftAnkleTransform.columns.3.z,
//        
//        rightThighTransform.columns.3.x, rightThighTransform.columns.3.y, rightThighTransform.columns.3.z,
//        rightKneeTransform.columns.3.x, rightKneeTransform.columns.3.y, rightKneeTransform.columns.3.z,
//        rightAnkleTransform.columns.3.x, rightAnkleTransform.columns.3.y, rightAnkleTransform.columns.3.z]
        
        if(recording){
            bodyPosArr[bodyPosArr.count-1] = dataSample
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
    
    func computeJointAngle(startJointPos: simd_float3, middleJointPos: simd_float3, endJointPos: simd_float3) -> Float {
        let vec1 = startJointPos-middleJointPos
        let vec2 = endJointPos-middleJointPos
        return acos(simd_dot(vec1, vec2)/(simd_length(vec1)*simd_length(vec2)))
    }

    
}
