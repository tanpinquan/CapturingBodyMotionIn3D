//
//  ManageUserDefaults.swift
//  BodyDetection
//
//  Created by Pin Quan Tan on 7/6/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import ARKit

func saveRecordingKeys(keys:[String]) -> Void {
    if let dataToBeArchived = try? NSKeyedArchiver.archivedData(withRootObject: keys, requiringSecureCoding: false) {
        print("Update Keys")
        UserDefaults.standard.set(dataToBeArchived, forKey: "recording_keys")
    }
}

func getRecordingKeys() -> [String] {
    if let  archivedObject = UserDefaults.standard.data(forKey: "recording_keys"){
        do {
            if let keys = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(archivedObject) as? [String] {
                print(keys)
                return keys
            }
        } catch {
            // do something with the error
        }
    }
    return []
}

func saveRecording(anchorArr:[ARBodyAnchor]) -> Void {
    
    var recordingKeys = getRecordingKeys()
    
    let key = "recording_" + recordingKeys.count.description
    
    if let dataToBeArchived = try? NSKeyedArchiver.archivedData(withRootObject: anchorArr, requiringSecureCoding: false) {
        print("Save Recording:" + key)
        UserDefaults.standard.set(dataToBeArchived, forKey: key)
        
        recordingKeys.append(key)
        saveRecordingKeys(keys: recordingKeys)
        
    }
}

func loadRecording(key:String) -> [ARBodyAnchor] {
    if let  archivedObject = UserDefaults.standard.data(forKey: key){
        do {
            if let recording = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(archivedObject) as? [ARBodyAnchor] {
                return recording
            }
        } catch {
            // do something with the error
        }
    }
    return []
}

