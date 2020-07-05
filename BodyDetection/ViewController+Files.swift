//
//  ViewController+Files.swift
//  BodyDetection
//
//  Created by Pin Quan Tan on 24/5/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import UIKit

extension ViewController{
    
    func refreshFiles() -> Void {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
             print(dir)
             
             do{
                let fileURLs = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
                print(fileURLs)
                
                var fileStr:String = ""
                
                fileURLs.forEach({URL in
                    fileStr += URL.lastPathComponent + ","

                })
//                fileLabels.text = fileStr

             }catch{
                 
             }
         }
        
    }
    
    func deleteFiles() -> Void {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            print(dir)
            
            do{
                let fileURLs = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
                print(fileURLs)
                fileURLs.forEach({URL in
                    print(URL.absoluteString.suffix(5))

                    do{
                        try FileManager.default.removeItem(at: URL)
                    }
                    catch{}
                })

            }catch{}
        }
        refreshFiles()
    }
    
        /// CSV Export Function
    func createBodyCSV() -> Void {
        let leftShoulderStr = "l_shoulder_x, l_shoulder_y, l_shoulder_z, l_shoulder_r, l_shoulder_p, l_shoupder_yaw, "
        let leftArmStr = "l_arm_x, l_arm_y, l_arm_z, l_arm_r, l_arm_p, l_arm_yaw, "
        let leftElbowStr = "l_elbow_x, l_elbow_y, l_elbow_z, l_elbow_r, l_elbow_p, l_elbow_yaw, "
        let leftWristStr = "l_wrist_x, l_wrist_y, l_wrist_z, l_wrist_r, l_wrist_p, l_wrist_yaw, "

        let rightShoulderStr = "r_shoulder_x, r_shoulder_y, r_shoulder_z, r_shoulder_r, r_shoulder_p, r_shoupder_yaw, "
        let rightArmStr = "r_arm_x, r_arm_y, r_arm_z, r_arm_r, r_arm_p, r_arm_yaw, "
        let rightElbowStr = "r_elbow_x, r_elbow_y, r_elbow_z, r_elbow_r, r_elbow_p, r_elbow_yaw, "
        let rightWristStr = "r_wrist_x, r_wrist_y, r_wrist_z, r_wrist_r, r_wrist_p, r_wrist_yaw, "

        
        let leftThighStr = "l_thigh_x, l_thigh_y, l_thigh_z, l_thigh_r, l_thigh_p, l_thigh_yaw, "
        let leftKneeStr = "l_knee_x, l_knee_y, l_knee_z, l_knee_r, l_knee_p, l_knee_yaw, "
        let leftAnkleStr = "l_ankle_x, l_ankle_y, l_ankle_z, l_ankle_l, r_ankle_p, l_ankle_yaw, "
        
        let rightThighStr = "r_thigh_x, r_thigh_y, r_thigh_z, r_thigh_r, r_thigh_p, r_thigh_yaw, "
        let rightKneeStr = "r_knee_x, r_knee_y, r_knee_z, r_knee_r, r_knee_p, r_knee_yaw, "
        let rightAnkleStr = "r_ankle_x, r_ankle_y, r_ankle_z, r_ankle_r, r_ankle_p, r_ankle_yaw, "

        
    

        let imgThighStr = "img_thigh_x, img_thigh_y, img_thigh_z, img_thigh_r, img_thigh_p, img_thigh_yaw,"
        let imgCalfStr = "img_calf_x, img_calf_y, img_calf_z, img_calf_r, img_calf_p, img_calf_y"

        var bodyCsvString = leftShoulderStr + leftArmStr + leftElbowStr + leftWristStr
        + rightShoulderStr + rightArmStr + rightElbowStr + rightWristStr
        + leftThighStr + leftKneeStr + leftAnkleStr
        + rightThighStr + rightKneeStr + rightAnkleStr
        + imgThighStr + imgCalfStr + "\n"
        
        var numberInt = 0

        
        for (bodyPos,imagePos) in zip(bodyPosArr,imagePosArr) {
            var newLine = bodyPos.description + ", " + imagePos.description
            newLine = newLine.replacingOccurrences(of: "[", with: "")
            newLine = newLine.replacingOccurrences(of: "]", with: "")
            newLine.append("\n")
            bodyCsvString.append(newLine)
        }
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            print(dir)
            
            do{
                let fileURLs = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
                numberInt = fileURLs.count


            }catch{}
            

            let fileName = "Data" + String(numberInt) + ".csv"
            
            let fileURL = dir.appendingPathComponent(fileName)

            //writing
            do {
                try bodyCsvString.write(to: fileURL, atomically: false, encoding: .utf8)
                print("File created:" + fileName)
            }
            catch {/* error handling here */}
            


        }
        bodyPosArr = []
        refreshFiles()
        
    }
    
    func uploadFiles() -> Void {
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
    
    func readFile() -> Void {
        let filePath = Bundle.main.path(forResource: "shoulder_1_1", ofType: "csv");
        let fileUrl = NSURL.fileURL(withPath: filePath!)
        do {
            let file = try String(contentsOf: fileUrl)
            let rows = file.components(separatedBy: .newlines)
            for row in rows {
                let fields = row.replacingOccurrences(of: "\"", with: "").components(separatedBy: ", ")
                
                var dataSample: [Float] = Array(repeating: 0.0, count: numRecordedJoints*6)
                if(fields.count>dataSample.count){
                    for index in 0...dataSample.count-1 {
                        dataSample[index] = Float(fields[index]) ?? 0.0
                    }
                }
                let jointAngleSample:[Float] = [0.0, 1.0, 2.0, 3.0]
                addAccelSampleToDataArray(posSample: dataSample, jointAngleSample: jointAngleSample)
            }
        } catch {
            print(error)
        }
    }
    
}
