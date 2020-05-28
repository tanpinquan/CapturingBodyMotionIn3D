////
////  ViewController+Predict.swift
////  BodyDetection
////
////  Created by Pin Quan Tan on 28/5/20.
////  Copyright © 2020 Apple. All rights reserved.
////
//
//import Foundation
//import CoreML
//import UIKit
//
//extension ViewController{
//    struct ModelConstants {
//        static let predictionWindowSize = 350
//        static let stateInLength = 400
//        static let numFeatures = 84
//    }
//    let shoulderAbductionModel = ShoulderAbductionClassifier()
//    var currentIndexInPredictionWindow = 0
//    
//
//    let inputArr: [MLMultiArray] = Array(repeating: try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double), count: ModelConstants.numFeatures)
//    var stateOutput = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
//    
//    
//    func addAccelSampleToDataArray (posSample: [Float]) {
//           // Add the current accelerometer reading to the data array
//        for (featureIndex, sample) in posSample.enumerated() {
//            inputArr[featureIndex][[currentIndexInPredictionWindow] as [NSNumber]] = sample as NSNumber
//        }
//           
//           
//       // Update the index in the prediction window data array
//       currentIndexInPredictionWindow += 1
//
//           // If the data array is full, call the prediction method to get a new model prediction.
//           // We assume here for simplicity that the Gyro data was added to the data arrays as well.
//       if (currentIndexInPredictionWindow == ModelConstants.predictionWindowSize) {
//           if let predictedActivity = performModelPrediction() {
//
//               // Use the predicted activity here
//               predLabel.displayMessage(predictedActivity, duration: 1)
//               print(predictedActivity)
//
//               if(predictedActivity=="shoulder_left"){
//                   predLabel.backgroundColor = .green
//               }else if(predictedActivity=="shoulder_right"){
//                   predLabel.backgroundColor = .blue
//               }
//
//
//               // Start a new prediction window
//               currentIndexInPredictionWindow = 0
//           }else{
//               predLabel.displayMessage("No Activity", duration: 1)
//               predLabel.backgroundColor = .red
//               print("No Activity")
//           }
//       }
//   }
//    
//   func performModelPrediction () -> String? {
//    
////    let classifierInput:ShoulderAbductionClassifierInput = ShoulderAbductionClassifierInput.
//       // Perform model prediction
//    let modelPrediction = try!shoulderAbductionModel.prediction(
//        l_shoulder_x: inputArr[0], l_shoulder_y: inputArr[1], l_shoulder_z: inputArr[2],
//        l_shoulder_r: inputArr[3], l_shoulder_p: inputArr[4], l_shoupder_yaw: inputArr[5],
//        
//        l_arm_x: inputArr[6], l_arm_y: inputArr[7], l_arm_z: inputArr[8],
//        l_arm_r: inputArr[9], l_arm_p: inputArr[10], l_arm_yaw: inputArr[11],
//        
//        l_elbow_x: inputArr[12], l_elbow_y: inputArr[13], l_elbow_z: inputArr[14],
//        l_elbow_r: inputArr[15], l_elbow_p: inputArr[16], l_elbow_yaw: inputArr[17],
//        
//        l_wrist_x: inputArr[18], l_wrist_y: inputArr[19], l_wrist_z: inputArr[20],
//        l_wrist_r: inputArr[21], l_wrist_p: inputArr[22], l_wrist_yaw: inputArr[23],
//        
//        r_shoulder_x: inputArr[24], r_shoulder_y: inputArr[25], r_shoulder_z: inputArr[26],
//        r_shoulder_r: inputArr[27], r_shoulder_p: inputArr[28], r_shoupder_yaw: inputArr[29],
//        
//        r_arm_x: inputArr[30], r_arm_y: inputArr[31], r_arm_z: inputArr[32],
//        r_arm_r: inputArr[33], r_arm_p: inputArr[34], r_arm_yaw: inputArr[35],
//        
//        r_elbow_x: inputArr[36], r_elbow_y: inputArr[37], r_elbow_z: inputArr[38],
//        r_elbow_r: inputArr[39], r_elbow_p: inputArr[40], r_elbow_yaw: inputArr[41],
//        
//        r_wrist_x: inputArr[42], r_wrist_y: inputArr[43], r_wrist_z: inputArr[44],
//        r_wrist_r: inputArr[45], r_wrist_p: inputArr[46], r_wrist_yaw: inputArr[47],
//        
//        l_thigh_x: inputArr[48], l_thigh_y: inputArr[49], l_thigh_z: inputArr[50],
//        l_thigh_r: inputArr[51], l_thigh_p: inputArr[52], l_thigh_yaw: inputArr[53],
//        
//        l_knee_x: inputArr[54], l_knee_y: inputArr[55], l_knee_z: inputArr[56],
//        l_knee_r: inputArr[57], l_knee_p: inputArr[58], l_knee_yaw: inputArr[59],
//        
//        l_ankle_x: inputArr[60], l_ankle_y: inputArr[61], l_ankle_z: inputArr[62],
//        l_ankle_l: inputArr[63], r_ankle_p: inputArr[64], l_ankle_yaw: inputArr[65],
//        
//        r_thigh_x: inputArr[66], r_thigh_y: inputArr[67], r_thigh_z: inputArr[68],
//        r_thigh_r: inputArr[69], r_thigh_p: inputArr[70], r_thigh_yaw: inputArr[71],
//        
//        r_knee_x: inputArr[72], r_knee_y: inputArr[73], r_knee_z: inputArr[74],
//        r_knee_r: inputArr[75], r_knee_p: inputArr[76], r_knee_yaw: inputArr[77],
//        
//        r_ankle_x: inputArr[78], r_ankle_y: inputArr[79], r_ankle_z: inputArr[80],
//        r_ankle_r: inputArr[81], r_ankle_p_1: inputArr[82], r_ankle_yaw: inputArr[83],
//        
//        stateIn: stateOutput)
//
//       // Update the state vector
//       stateOutput = modelPrediction.stateOut
//
//       // Return the predicted activity - the activity with the highest probability
//       return modelPrediction.activity
//   }
//   
//}
//
//
//
