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
                fileLabels.text = fileStr

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
    func createCSV() -> Void {
        let leftUpperBodyStr = "l_shoulder_x, l_shoulder_y, l_shoulder_z, l_elbow_x, l_elbow_y, l_elbow_z, l_wrist_x, l_wrist_y, l_wrist_z, "
        let rightUpperBodyStr = "r_shoulder_x, r_shoulder_y, r_shoulder_z, r_elbow_x, r_elbow_y, r_elbow_z, r_wrist_x, r_wrist_y, r_wrist_z, "
        
        let leftlowerBodyStr = "l_thigh_x, l_thigh_y, l_thigh_z, l_knee_x, l_knee_y, l_knee_z, l_ankle_x, l_ankle_y, l_ankle_z, "
        let rightlowerBodyStr = "r_thigh_x, r_thigh_y, r_thigh_z, r_knee_x, r_knee_y, r_knee_z, r_ankle_x, r_ankle_y, r_ankle_z, "

        let imageStr0 = "img0_x, img0_y, img0_z, "
        let imageStr1 = "img1_x, img1_y, img1_z\n"

        var bodyCsvString = leftUpperBodyStr + rightUpperBodyStr + leftlowerBodyStr + rightlowerBodyStr + imageStr0 + imageStr1
        var numberInt = 0
//        bodyPosArr.forEach{data in
//            var newLine = data.description
//            newLine = newLine.replacingOccurrences(of: "[", with: "")
//            newLine = newLine.replacingOccurrences(of: "]", with: "")
//            newLine.append("\n")
////            let newLine = "\(String(describing: data[0])),\(String(describing: data[1])),\(String(describing: data[2]))\n"
//            bodyCsvString.append(newLine)
//        }
        
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
            

            let fileName = pickerData[2][selectedExercise] + "Data" + String(numberInt) + ".csv"
            
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
    
}
