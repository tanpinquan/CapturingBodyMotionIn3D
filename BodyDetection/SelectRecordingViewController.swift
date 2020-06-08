//
//  SelectRecordingViewController.swift
//  BodyDetection
//
//  Created by Pin Quan Tan on 7/6/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit

class SelectRecordingViewController: UITableViewController {

    var recordingInfo:RecordingInfo = RecordingInfo(recordingKeys: [], recordingLengths: [], recordingTypes: [])
    var selectedRecording:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = false

        recordingInfo = getRecordingKeys()

        // Do any additional setup after loading the view.
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recordingInfo.recordingKeys.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecordingItem", for: indexPath)
        
        if let label = cell.viewWithTag(100) as? UILabel {
            label.text = recordingInfo.recordingKeys[indexPath.row]
                + " (" + recordingInfo.recordingLengths[indexPath.row].description + " " + recordingInfo.recordingTypes[indexPath.row] + " samples)"
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRecording = recordingInfo.recordingKeys[indexPath.row]
        if(recordingInfo.recordingTypes[indexPath.row] == "body"){
            performSegue(withIdentifier: "ReplayBodyRecording", sender: nil)
        }else if(recordingInfo.recordingTypes[indexPath.row] == "leg"){
            performSegue(withIdentifier: "ReplayLegRecording", sender: nil)
        }

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Determine what the segue destination is
        if segue.destination is ReplayBodyViewController{
            let vc = segue.destination as? ReplayBodyViewController
            vc?.recordingKey = selectedRecording
        } else if segue.destination is ReplayLegViewController{
            let vc = segue.destination as? ReplayLegViewController
            vc?.recordingKey = selectedRecording
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
