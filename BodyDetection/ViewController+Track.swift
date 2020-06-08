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
//        print((imageAnchor.referenceImage.name ?? "") + imagePosition)
        let rotateY = simd_quatf(angle: GLKMathDegreesToRadians(90), axis: SIMD3(x: 0, y: 1, z: 0))
        let rotateX = simd_quatf(angle: GLKMathDegreesToRadians(270), axis: SIMD3(x: 1, y: 0, z: 0))
        let rotate = simd_mul(rotateY, rotateX)

        if(imageAnchor.referenceImage.name == "meiji2"){
            let thighNode:SCNNode = SCNNode()
            thighNode.transform = SCNMatrix4(imageAnchor.transform)
            
            leftLabelX.displayMessage("X: " + thighNode.position.x.description.prefix(5), duration: 1)
            leftLabelY.displayMessage("Y: " + thighNode.position.y.description.prefix(5), duration: 1)
            leftLabelZ.displayMessage("Z: " + thighNode.position.z.description.prefix(5), duration: 1)
        
            rightLabelX.displayMessage("Roll: " + radiansToDegrees(thighNode.eulerAngles.x).description.prefix(5), duration: 1)
            rightLabelY.displayMessage("Pitch: " + radiansToDegrees(thighNode.eulerAngles.y).description.prefix(5), duration: 1)
            rightLabelZ.displayMessage("Yaw: " + radiansToDegrees(thighNode.eulerAngles.z).description.prefix(5), duration: 1)
            
            imageDisplayAnchor.position = simd_make_float3(imageAnchor.transform.columns.3)
            imageDisplayAnchor.orientation = Transform(matrix: imageAnchor.transform).rotation
            imageDisplayAnchor.addChild(planeEntity)
   
            thighTextEntity.transform.rotation = rotate
            imageDisplayAnchor.addChild(thighTextEntity)
            if(recording && allImagesDetected){
                thighAnchorArr.append(imageAnchor)
            }

            
        }else if(imageAnchor.referenceImage.name == "jatz"){
            let calfNode:SCNNode = SCNNode()
            calfNode.transform = SCNMatrix4(imageAnchor.transform)

            leftLabelX.displayMessage("X: " + calfNode.position.x.description.prefix(5), duration: 1)
            leftLabelY.displayMessage("Y: " + calfNode.position.y.description.prefix(5), duration: 1)
            leftLabelZ.displayMessage("Z: " + calfNode.position.z.description.prefix(5), duration: 1)

            rightLabelX.displayMessage("Roll: " + radiansToDegrees(calfNode.eulerAngles.x).description.prefix(5), duration: 1)
            rightLabelY.displayMessage("Pitch: " + radiansToDegrees(calfNode.eulerAngles.y).description.prefix(5), duration: 1)
            rightLabelZ.displayMessage("Yaw: " + radiansToDegrees(calfNode.eulerAngles.z).description.prefix(5), duration: 1)

            imageDisplayAnchor2.position = simd_make_float3(imageAnchor.transform.columns.3)
            imageDisplayAnchor2.orientation = Transform(matrix: imageAnchor.transform).rotation
            imageDisplayAnchor2.addChild(planeEntity2)
            
            calfTextEntity.transform.rotation = rotate
            imageDisplayAnchor2.addChild(calfTextEntity)
            
            if(recording && allImagesDetected){
                calfAnchorArr.append(imageAnchor)
            }
            
            
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
    
        rightLabelX.displayMessage("Roll: " + radiansToDegrees(selectedJointLocalNode.eulerAngles.x).description.prefix(5), duration: 1)
        rightLabelY.displayMessage("Pitch: " + radiansToDegrees(selectedJointLocalNode.eulerAngles.y).description.prefix(5), duration: 1)
        rightLabelZ.displayMessage("Yaw: " + radiansToDegrees(selectedJointLocalNode.eulerAngles.z).description.prefix(5), duration: 1)
        
        let lElbowAngle = computeJointAngle(
            startJointPos: simd_make_float3(jointModelTransforms[20].columns.3),
            middleJointPos: simd_make_float3(jointModelTransforms[21].columns.3),
            endJointPos: simd_make_float3(jointModelTransforms[22].columns.3)
            ) * 180 / .pi
        let rElbowAngle = computeJointAngle(
            startJointPos: simd_make_float3(jointModelTransforms[64].columns.3),
            middleJointPos: simd_make_float3(jointModelTransforms[65].columns.3),
            endJointPos: simd_make_float3(jointModelTransforms[66].columns.3)
            ) * 180 / .pi
        
        
        var leftAngleSign = -1
        if(jointModelTransforms[21].columns.3.y - jointModelTransforms[20].columns.3.y>0){
            leftAngleSign = 1
        }
        var rightAngleSign = -1
        if(jointModelTransforms[65].columns.3.y - jointModelTransforms[64].columns.3.y>0){
            rightAngleSign = 1
        }
//        let rightAngleSign = (jointModelTransforms[65].columns.3.y - jointModelTransforms[64].columns.3.y).sign.rawValue

        
        let lShoulderAngle = computeJointAngle(
            startJointPos: simd_make_float3(jointModelTransforms[19].columns.3),
            middleJointPos: simd_make_float3(jointModelTransforms[20].columns.3),
            endJointPos: simd_make_float3(jointModelTransforms[21].columns.3)
            ) * 180 / .pi * Float(leftAngleSign)
        let rShoulderAngle = computeJointAngle(
            startJointPos: simd_make_float3(jointModelTransforms[63].columns.3),
            middleJointPos: simd_make_float3(jointModelTransforms[64].columns.3),
            endJointPos: simd_make_float3(jointModelTransforms[65].columns.3)
            ) * 180 / .pi * Float(rightAngleSign)
        
        if(latestPreditcion.starts(with: "shoulder_left")){
            modeLabel.text = "L Shoulder: " + lShoulderAngle.description.prefix(4) + "\t L Elbow: " + lElbowAngle.description.prefix(3)
        }else if(latestPreditcion.starts(with: "shoulder_right")){
            modeLabel.text = "R Shoulder: " + rShoulderAngle.description.prefix(4) + "\t R Elbow: " + rElbowAngle.description.prefix(3)
        }


        
        let jointAngleSample:[Float] = [lElbowAngle, rElbowAngle, lShoulderAngle, rShoulderAngle]

        
        /// Record data
        let jointLocalNodesArr: [SCNNode] = Array(repeating: SCNNode(), count: numRecordedJoints)
        let jointModelNodesArr: [SCNNode] = Array(repeating: SCNNode(), count: numRecordedJoints)

        var dataSample: [Float] = Array(repeating: 0.0, count: numRecordedJoints*6)

        for (arrIndex, jointIndex) in jointIndexArr.enumerated() {
            jointLocalNodesArr[arrIndex].transform = SCNMatrix4(jointLocalTransforms[jointIndex])
            jointModelNodesArr[arrIndex].transform = SCNMatrix4(jointModelTransforms[jointIndex])
            dataSample[arrIndex*6+0] = jointModelNodesArr[arrIndex].position.x
            dataSample[arrIndex*6+1] = jointModelNodesArr[arrIndex].position.y
            dataSample[arrIndex*6+2] = jointModelNodesArr[arrIndex].position.z
            dataSample[arrIndex*6+3] = jointLocalNodesArr[arrIndex].eulerAngles.x
            dataSample[arrIndex*6+4] = jointLocalNodesArr[arrIndex].eulerAngles.y
            dataSample[arrIndex*6+5] = jointLocalNodesArr[arrIndex].eulerAngles.z
                        
        }
        /// Predict
        addAccelSampleToDataArray(posSample: dataSample, jointAngleSample: jointAngleSample)
        if(recording){
            bodyPosArr[bodyPosArr.count-1] = dataSample
            bodyAnchorArr.append(bodyAnchor)

        }

        
        // Update the position of the character anchor's position.
        let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
        characterAnchor.position = bodyPosition + characterOffset
        // Also copy over the rotation of the body anchor, because the skeleton's pose
        // in the world is relative to the body anchor's rotation.

        //characterAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation
        let quaternion = simd_quatf(angle: degreesToRadians(selectedAngle),
                                    axis: simd_float3(x: 0,
                                                      y: 1,
                                                      z: 0))
        characterAnchor.orientation = quaternion

        if let character = character, character.parent == nil {
            // Attach the character to its anchor as soon as
            // 1. the body anchor was detected and
            // 2. the character was loaded.
            characterAnchor.addChild(character)
            print("added anchor")

        }

//        print("Track Body " + bodyAnchorArr.count.description)

        
    }


    
    func computeJointAngle(startJointPos: simd_float3, middleJointPos: simd_float3, endJointPos: simd_float3) -> Float {
        let vec1 = startJointPos-middleJointPos
        let vec2 = endJointPos-middleJointPos
        return acos(simd_dot(vec1, vec2)/(simd_length(vec1)*simd_length(vec2)))
    }

    func degreesToRadians(_ degrees: Float) -> Float {
        return degrees * .pi / 180
    }
    
    func radiansToDegrees(_ radians: Float) -> Float {
        return radians * 180 / .pi
    }
}
