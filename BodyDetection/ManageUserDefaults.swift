//
//  ManageUserDefaults.swift
//  BodyDetection
//
//  Created by Pin Quan Tan on 7/6/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import ARKit

func saveRecordingKeys(recordingInfo: RecordingInfo) -> Void {
    if let dataToBeArchived = try? NSKeyedArchiver.archivedData(withRootObject: recordingInfo, requiringSecureCoding: false) {
        print("Update Recording Info")
        UserDefaults.standard.set(dataToBeArchived, forKey: "recording_info")
    }
}

func getRecordingKeys() -> RecordingInfo {
    if let  archivedObject = UserDefaults.standard.data(forKey: "recording_info"){
        do {
            if let recordingInfo = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(archivedObject) as? RecordingInfo {
                print(recordingInfo)
                return recordingInfo
            }
        } catch {
            // do something with the error
        }
    }
    return RecordingInfo(recordingKeys: [], recordingLengths: [])
}

func saveRecording(anchorArr:[ARBodyAnchor]) -> Void {
    
    let recordingInfo = getRecordingKeys()
    
    let key = "recording_" + recordingInfo.recordingKeys.count.description
    
    if let dataToBeArchived = try? NSKeyedArchiver.archivedData(withRootObject: anchorArr, requiringSecureCoding: false) {
        print("Save Recording:" + key)
        UserDefaults.standard.set(dataToBeArchived, forKey: key)
        
        recordingInfo.recordingKeys.append(key)
        recordingInfo.recordingLengths.append(anchorArr.count)
        saveRecordingKeys(recordingInfo: recordingInfo)
        
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

class RecordingInfo : NSObject, NSCoding{
    
    var recordingKeys:[String]
    var recordingLengths:[Int]

    init(recordingKeys:[String], recordingLengths:[Int]) {
        
        self.recordingKeys = recordingKeys
        self.recordingLengths = recordingLengths
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(recordingKeys, forKey: "recordingKeys")
        aCoder.encode(recordingLengths, forKey: "recordingLengths")

    }
   
    convenience required init?(coder aDecoder: NSCoder) {
        
        guard let recordingKeys = aDecoder.decodeObject(forKey: "recordingKeys") as? [String],
        let recordingLengths = aDecoder.decodeObject(forKey: "recordingLengths") as? [Int]
        else {
          return nil
        }
        self.init(recordingKeys: recordingKeys, recordingLengths: recordingLengths)
    }
}

