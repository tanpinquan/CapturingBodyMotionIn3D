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
    
    @IBAction func uploadButtonPressed(_ sender: UIBarButtonItem) {
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
    
    
    @IBAction func deleteButtonPressed(_ sender: UIBarButtonItem) {
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
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        
        UserDefaults.standard.synchronize()
        
        recordingInfo = getRecordingKeys()
        
        tableView.reloadData()

    }
    

}
