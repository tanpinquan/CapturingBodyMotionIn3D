//
//  MotionCaptureData.swift
//  BodyDetection
//
//  Created by Pin Quan Tan on 7/6/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import ARKit

class MotionCaptureData : NSObject, NSCoding{
    
    let anchorArray:[ARBodyAnchor]
    
    init(anchorArray:[ARBodyAnchor]) {
        
        self.anchorArray = anchorArray
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(anchorArray, forKey: "anchorArray")
    }
   
    convenience required init?(coder aDecoder: NSCoder) {
        
        guard let anchorArray = aDecoder.decodeObject(forKey: "anchorArray") as? [ARBodyAnchor]
        else {
          return nil
        }
        self.init(anchorArray: anchorArray)
    }
}

