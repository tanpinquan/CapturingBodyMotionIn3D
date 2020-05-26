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
    
}
