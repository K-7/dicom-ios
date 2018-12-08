//
//  ViewController.swift
//  TestDcmtkSwift
//
//  Created by G Srinivasa on 14/10/18.
//  Copyright © 2018 G Srinivasa. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.copyFolders()
        // Do any additional setup after loading the view, typically from a nib.
//        DicomUtil.test()
        DicomUtil.cecho()
        DicomUtil.cfind()
        
//        
//        self.cleanDocumentDirectoryDCM()
//        // Launch a tread that will receive the moved data
//        DispatchQueue.global(qos: .background).async {
//            do {
//                DicomUtil.setupMoveScp() //use semaphore
//            }
//        }
//        sleep(1)
//        DicomUtil.cmove()
////        sleep(2) // seems like it is not required
//        self.showDicomWebView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func showDicomWebView(fileName:String="0002.DCM") {
        let webView = webViewer(dicomFileUrl:fileName)
        addChildViewController(webView)
        webView.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        self.view.addSubview(webView.view)
    }
    
    func cleanDocumentDirectoryDCM(){
        let fileManager = FileManager.default
        let documentsUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard documentsUrl.count != 0 else {
            return // Could not find documents URL
        }
        let dcmFolder = documentsUrl.first!.appendingPathComponent("DicomViewer/dcm")
        do {
            try fileManager.removeItem(at: dcmFolder)
            try fileManager.createDirectory(at: dcmFolder, withIntermediateDirectories: true)
        } catch let error as NSError {
            print(error.localizedDescription);
        }
    }
    
    func copyFolders() {
        let fileManager = FileManager.default
        let documentsUrl = fileManager.urls(for: .documentDirectory,
                                            in: .userDomainMask)
        guard documentsUrl.count != 0 else {
            return // Could not find documents URL
        }
        let finalDatabaseURL = documentsUrl.first!.appendingPathComponent("DicomViewer")
        
        if !( (try? finalDatabaseURL.checkResourceIsReachable()) ?? false) {
            print("DB does not exist in documents folder")
            let documentsURL = Bundle.main.resourceURL?.appendingPathComponent("DicomViewer")
            
            do {
                if !FileManager.default.fileExists(atPath:(finalDatabaseURL.path))
                {
                    try FileManager.default.createDirectory(atPath: (finalDatabaseURL.path), withIntermediateDirectories: false, attributes: nil)
                }
                copyFiles(pathFromBundle: (documentsURL?.path)!, pathDestDocs: finalDatabaseURL.path)
            } catch let error as NSError {
                print("Couldn't copy file to final location! Error:\(error.description)")
            }
        } else {
            print("Database file found at path: \(finalDatabaseURL.path)")
        }
    }
    
    func copyFiles(pathFromBundle : String, pathDestDocs: String) {
        let fileManagerIs = FileManager.default
        do {
            let filelist = try fileManagerIs.contentsOfDirectory(atPath: pathFromBundle)
            try? fileManagerIs.copyItem(atPath: pathFromBundle, toPath: pathDestDocs)
            
            for filename in filelist {
                try? fileManagerIs.copyItem(atPath: "\(pathFromBundle)/\(filename)", toPath: "\(pathDestDocs)/\(filename)")
            }
        } catch {
            print("\nError\n")
        }
    }

}

