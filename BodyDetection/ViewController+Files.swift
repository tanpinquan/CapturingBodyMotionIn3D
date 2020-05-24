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
        var csvString = "shoulder_x, shoulder_y, shoulder_z, elbow_x, elbow_y, elbow_z, wrist_x, wrist_y, wrist_z, thigh_x, thigh_y, thigh_z, knee_x, knee_y, knee_z, ankle_x, ankle_y, ankle_z\n"
        var numberInt = 0
        bodyPosArr.forEach{data in
            var newLine = data.description
            newLine = newLine.replacingOccurrences(of: "[", with: "")
            newLine = newLine.replacingOccurrences(of: "]", with: "")
            newLine.append("\n")
//            let newLine = "\(String(describing: data[0])),\(String(describing: data[1])),\(String(describing: data[2]))\n"
            csvString.append(newLine)
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
                try csvString.write(to: fileURL, atomically: false, encoding: .utf8)
                print("File created:" + fileName)
            }
            catch {/* error handling here */}

        }
        bodyPosArr = []
        
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
