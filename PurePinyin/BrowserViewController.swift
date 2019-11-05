//
//  BrowserViewController.swift
//  PurePinyin
//
//  Created by Joakim Fännick on 2019-03-03.
//  Copyright © 2019 Joakim Fännick. All rights reserved.
//

import UIKit
import WebKit
import Foundation
import SQLite


class BrowserViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
 
    
    
    @IBOutlet weak var urlTextView: UITextField!
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        urlTextView.delegate = self

    }
    
 /*   func getPinyinDB() -> PinyinDB?
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.PinyinDatabase
    }*/
    
    @IBAction func enteredUrl(_ sender: Any) {
        let url = urlTextView.text!
        openUrl(urlstr: url)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == urlTextView
        {
            let url = urlTextView.text!
            openUrl(urlstr: url)
            resignFirstResponder()
        }
        return true
    }
    
    func openUrl(urlstr:String)
    {
        print(urlstr)
        
        guard let myURL = URL(string: urlstr) else {
            print("Error: \(urlstr) doesn't seem to be a valid URL")
            return
        }
        
        do {
            let myHTMLString = try String(contentsOf: myURL, encoding: .utf8)
            print("HTML : \(myHTMLString)")
            webView.loadHTMLString(myHTMLString, baseURL: myURL)
        } catch let error {
            print("Error: \(error)")
        }
    }
    
/*    func PinyinDBUpdate(_ text: String) {
        print(text)
    }*/
}
