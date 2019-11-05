//
//  SettingsViewController.swift
//  PurePinyin
//
//  Created by Joakim Fännick on 2019-03-05.
//  Copyright © 2019 Joakim Fännick. All rights reserved.
//

import Foundation
import UIKit
import SQLite
import Zip


class SettingsViewController: UIViewController, URLSessionDownloadDelegate
{
    var whichDatabase = "canto"
    let updateUrls = [
        "pinyin":"http://purepinyin.com/updates/pinyin.zip",
        "canto":"http://purepinyin.com/updates/canto.zip",
        "english":"http://purepinyin.com/updates/english.zip"
    ]
    var downloadTask:URLSessionTask? = nil
    let sessionConfig = URLSessionConfiguration.background(withIdentifier: Bundle.main.bundleIdentifier!)
    
    var urlSession: URLSession {
        sessionConfig.isDiscretionary = true
        return URLSession(configuration: sessionConfig, delegate: self, delegateQueue: .main)
    }
    
    @IBOutlet weak var lblDownloadProgress: UIProgressView!
    @IBOutlet weak var lblDownloadStatus: UILabel!
    @IBOutlet weak var updatePinyinBtn: UIButton!
    @IBOutlet weak var updateCantoBtn: UIButton!
    @IBOutlet weak var updateEnglishBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.lblDownloadStatus.text = "Downloading... [\(Int(progress * 100))%]"
            self.lblDownloadProgress.progress = progress
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            PYDB.removeFile(name: "update.zip")
            PYDB.removeFile(name: "\(whichDatabase).db")
            let zipfile = PYDB.getPathTo(file: "update.zip")
            try FileManager.default.copyItem(at: location, to: zipfile)
            let unzipDirectory = try Zip.quickUnzipFile(zipfile) // Unzip
            let dbpath = unzipDirectory.appendingPathComponent("\(whichDatabase).db")
            DispatchQueue.main.async {
                self.lblDownloadStatus.text = "Update downloaded. Installing..."
            }
        
            let (applied,errmsg) = PYDB.updateFromExternalFile(dbpath, whichDatabase)
            
            DispatchQueue.main.async
            {
                if applied
                {
                    self.lblDownloadStatus.text = "Update applied!"
                }
                else
                {
                    self.lblDownloadStatus.text = "Update failed..."
                    print(errmsg)
                }
                self.enableUpdateButtons()
            }
            //remove update file
            PYDB.removeFile(name: "update.zip")
            PYDB.removeFile(name: dbpath)
            //PYDB.removeFile(name: "update.db")
            
        }
        catch let error
        {
            print(error)
            DispatchQueue.main.async {
                self.lblDownloadStatus.text = error.localizedDescription
            }
        }

    }
    
    func disableUpdateButtons()
    {
        updatePinyinBtn.isEnabled = false
        updateCantoBtn.isEnabled = false
        updateEnglishBtn.isEnabled = false
    }
    func enableUpdateButtons()
    {
        updatePinyinBtn.isEnabled = true
        updateCantoBtn.isEnabled = true
        updateEnglishBtn.isEnabled = true
    }

    @IBAction func updatePinyin(_ sender: Any) {
        downloadDatabase(whichDB: "pinyin")
    }
    @IBAction func updateCanto(_ sender: Any) {
        downloadDatabase(whichDB: "canto")
    }
    @IBAction func updateEnglish(_ sender: Any) {
        downloadDatabase(whichDB: "english")
    }
    
    func downloadDatabase(whichDB: String)
    {
        whichDatabase = whichDB
        DispatchQueue.main.async {
            self.disableUpdateButtons()
            self.lblDownloadStatus.text = "Downloading... [0%]"
            self.lblDownloadProgress.progress = 0.0
        }
        if let url = URL(string: updateUrls[whichDatabase]!)
        {
            let task = urlSession.downloadTask(with: url)
            task.resume()
        }
    }
}
