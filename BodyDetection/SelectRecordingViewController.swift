//
//  SelectRecordingViewController.swift
//  BodyDetection
//
//  Created by Pin Quan Tan on 7/6/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit

class SelectRecordingViewController: UITableViewController {

    var recordingKeys:[String] = []
    var selectedRecording:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = false

        recordingKeys = getRecordingKeys()

        // Do any additional setup after loading the view.
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recordingKeys.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecordingItem", for: indexPath)
        
        if let label = cell.viewWithTag(100) as? UILabel {
            label.text = recordingKeys[indexPath.row]
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRecording = recordingKeys[indexPath.row]
        performSegue(withIdentifier: "ShowRecording", sender: nil)

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Determine what the segue destination is
        if segue.destination is ReplayViewController
        {
            let vc = segue.destination as? ReplayViewController
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
