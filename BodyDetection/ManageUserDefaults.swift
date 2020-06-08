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
    return RecordingInfo(recordingKeys: [], recordingLengths: [], recordingTypes: [])
}

func saveBodyRecording(anchorArr:[ARBodyAnchor]) -> Void {
    
    let recordingInfo = getRecordingKeys()
    
    let key = "recording_" + recordingInfo.recordingKeys.count.description
    
    if let dataToBeArchived = try? NSKeyedArchiver.archivedData(withRootObject: anchorArr, requiringSecureCoding: false) {
        print("Save Recording:" + key)
        UserDefaults.standard.set(dataToBeArchived, forKey: key)
        
        recordingInfo.recordingKeys.append(key)
        recordingInfo.recordingLengths.append(anchorArr.count)
        recordingInfo.recordingTypes.append("body")
        saveRecordingKeys(recordingInfo: recordingInfo)
        
    }
}

func loadBodyRecording(key:String) -> [ARBodyAnchor] {
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


func saveLegRecording(thighAnchors:[ARImageAnchor], calfAnchors:[ARImageAnchor]) -> Void {
    let legRecording = LegRecording(thighAnchors: thighAnchors, calfAnchors: calfAnchors)
    let recordingInfo = getRecordingKeys()
    
    let key = "recording_" + recordingInfo.recordingKeys.count.description
    
    if let dataToBeArchived = try? NSKeyedArchiver.archivedData(withRootObject: legRecording, requiringSecureCoding: false) {
        print("Save Recording:" + key)
        UserDefaults.standard.set(dataToBeArchived, forKey: key)
        
        recordingInfo.recordingKeys.append(key)
        recordingInfo.recordingLengths.append(thighAnchors.count)
        recordingInfo.recordingTypes.append("leg")
        saveRecordingKeys(recordingInfo: recordingInfo)
        
    }
}

func loadLegRecording(key:String) -> LegRecording {
    if let  archivedObject = UserDefaults.standard.data(forKey: key){
        do {
            if let recording = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(archivedObject) as? LegRecording {
                return recording
            }
        } catch {
            // do something with the error
        }
    }
    return LegRecording(thighAnchors: [], calfAnchors: [])
}



class RecordingInfo : NSObject, NSCoding{
    
    var recordingKeys:[String]
    var recordingLengths:[Int]
    var recordingTypes:[String]

    init(recordingKeys:[String], recordingLengths:[Int], recordingTypes:[String]) {
        
        self.recordingKeys = recordingKeys
        self.recordingLengths = recordingLengths
        self.recordingTypes = recordingTypes
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(recordingKeys, forKey: "recordingKeys")
        aCoder.encode(recordingLengths, forKey: "recordingLengths")
        aCoder.encode(recordingTypes, forKey: "recordingTypes")

    }
   
    convenience required init?(coder aDecoder: NSCoder) {
        
        guard let recordingKeys = aDecoder.decodeObject(forKey: "recordingKeys") as? [String],
        let recordingLengths = aDecoder.decodeObject(forKey: "recordingLengths") as? [Int],
        let recordingTypes = aDecoder.decodeObject(forKey: "recordingTypes") as? [String]

        else {
          return nil
        }
        self.init(recordingKeys: recordingKeys, recordingLengths: recordingLengths, recordingTypes:recordingTypes)
    }
}

class LegRecording : NSObject, NSCoding{
    
    var thighAnchors:[ARImageAnchor]
    var calfAnchors:[ARImageAnchor]

    init(thighAnchors:[ARImageAnchor], calfAnchors:[ARImageAnchor]) {
        
        self.thighAnchors = thighAnchors
        self.calfAnchors = calfAnchors
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(thighAnchors, forKey: "thighAnchors")
        aCoder.encode(calfAnchors, forKey: "calfAnchors")

    }
   
    convenience required init?(coder aDecoder: NSCoder) {
        
        guard let thighAnchors = aDecoder.decodeObject(forKey: "thighAnchors") as? [ARImageAnchor],
        let calfAnchors = aDecoder.decodeObject(forKey: "calfAnchors") as? [ARImageAnchor]

        else {
          return nil
        }
        self.init(thighAnchors: thighAnchors, calfAnchors: calfAnchors)
    }
}

