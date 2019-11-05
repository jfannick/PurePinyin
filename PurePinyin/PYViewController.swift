//
//  PYViewController.swift
//  PurePinyin
//
//  Created by Joakim Fännick on 2018-09-23.
//  Copyright © 2018 Joakim Fännick. All rights reserved.
//
import UIKit
import WebKit
import Foundation
import SQLite


class PYNewConverterController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    
    let app = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet var txtHanzi: UITextView!
    @IBOutlet var txtPinyin: UITextView!
    @IBOutlet weak var vwScroll: UIScrollView!
    
    @IBOutlet weak var webOutput: WKWebView!
    @IBOutlet weak var btnPinyin: UIButton!
    
    @IBOutlet weak var btnCopy: UIButton!
    @IBOutlet weak var btnRuby: UIButton!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var lblMessage: UILabel!
    
    @IBOutlet weak var tabButton: UITabBarItem!
    
    var db:Connection!
    
    var keyboardHeight = CGFloat(0.0)
    var keyboardTop = CGFloat(0.0)
    
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    var currentSize = CGSize.zero
    
    var conversionTable:Dictionary<String,String> = [:]
    
   /* func initDB()
    {
        // Move database file from bundle to documents folder
        let fileManager = FileManager.default
        let documentsUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard documentsUrl.count != 0 else {
            return // Could not find documents URL
        }
        
        do {
            let finalDatabaseURL = documentsUrl.first!.appendingPathComponent("dictionary.sqlite")
            
            if !( (try? finalDatabaseURL.checkResourceIsReachable()) ?? false) {
                print("DB does not exist in documents folder")
                
                let documentsURL = Bundle.main.resourceURL?.appendingPathComponent("pinyin.sqlite")
                //If we don't have a word suggestion database, copy the file from the main target and prepare
                try fileManager.copyItem(atPath: (documentsURL?.path)!, toPath: finalDatabaseURL.path)
                print("Database file copied to path: \(finalDatabaseURL.path)")
                //open connection
                self.db = try Connection(finalDatabaseURL.path)
                
                try self.db!.run("CREATE TABLE IF NOT EXISTS `suggestions` ( `id` INTEGER NOT NULL, `match` TEXT, `suggestions` TEXT,  PRIMARY KEY(`id`) )")
                
            } else {
                print("Database file found at path: \(finalDatabaseURL.path)")
                //open connection
                self.db = try Connection(finalDatabaseURL.path)
                
            }
            
            /*let query = "select hanzi,pinyin from pinyin"
            let stm = try self.db.prepare(query)
            for row in stm
            {
                let hz = row[0] as! String
                let py = row[1] as! String
                self.conversionTable[hz] = py
            }*/
        } catch  {
            print("Error:\(error)")
        }
    }*/
    
    /*func getPinyinDB() -> PinyinDB?
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.PinyinDatabase
    }*/

    override func viewDidLoad() {
        super.viewDidLoad()

        currentSize = self.view.bounds.size
       
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: NSNotification.Name.UIKeyboardWillShow,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: NSNotification.Name.UIKeyboardWillHide,
            object: nil
        )
        self.webOutput.isHidden = true
        self.txtHanzi.isHidden = false
        self.txtPinyin.isHidden = false
        self.txtPinyin.text = ""
        self.webOutput.loadHTMLString("", baseURL: nil)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            self.keyboardHeight = keyboardRectangle.height
            let tabBarHeight = self.tabBarController!.tabBar.frame.height
            self.scrollViewBottomConstraint.constant = keyboardRectangle.height - tabBarHeight

            if self.txtPinyin.isFirstResponder
            {
                if self.txtPinyin.frame.maxY > self.vwScroll.frame.height - self.keyboardHeight
                {
                    self.vwScroll.contentOffset = CGPoint(x: 0, y: self.keyboardHeight)
                }
            }
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        self.scrollViewBottomConstraint.constant = 0
    }
    
    func startSpinner()
    {
        
         self.spinner.isHidden = false
         //self.spinner.startAnimating()
         self.btnPinyin.isEnabled = false
         self.btnRuby.isEnabled = false
        self.btnCopy.isEnabled = false
        self.btnPinyin.isHighlighted = true
        self.btnRuby.isHighlighted = true
        self.btnCopy.isHighlighted = true
    }
    
    func stopSpinner()
    {
        self.spinner.isHidden = true
        //self.spinner.stopAnimating()
        self.btnPinyin.isEnabled = true
        self.btnRuby.isEnabled = true
        self.btnCopy.isEnabled = true
        self.btnPinyin.isHighlighted = false
        self.btnRuby.isHighlighted = false
        self.btnCopy.isHighlighted = false

    }
    
    @IBAction func makePinyin(_ sender: Any) {
        /*if PYDB == nil
        {
            flashMesssage(text: "Database still loading...")
            return
        }*/
        
        let chinesestring = self.txtHanzi.text!
        self.txtPinyin.text = ""
        self.webOutput.loadHTMLString("", baseURL: nil)
       
        if chinesestring == ""
        {
            return
        }
        self.txtHanzi.resignFirstResponder()
        self.txtPinyin.isHidden = false
        self.webOutput.isHidden = true
        let numcharsinfirstchunk = numberOfCharactersThatFitTextView(view: self.txtHanzi) + 50

        DispatchQueue.global(qos: .userInteractive).async {
            //Update UI, activity indicator
            DispatchQueue.main.async {
                self.startSpinner()
            }
            
            let chunks = chinesestring.getChunks(ofMinSize: numcharsinfirstchunk, separatedBy: "。")
            var outputstring = ""
            var displayfirst = false
            for chunk in chunks
            {
                outputstring += PYDB.convert(hanzi: chunk, false)
                if !displayfirst
                {
                    displayfirst = true
                    DispatchQueue.main.async {
                        self.txtPinyin.text = outputstring
                        
                    }
                }
            }
            //update UI
            DispatchQueue.main.async {
                self.txtPinyin.text = outputstring
                self.stopSpinner()
                
            }
                
        }
    }
    
    @IBAction func makeRuby(_ sender: Any) {
        if PYDB == nil
        {
            flashMesssage(text: "Database still loading...")
            return
        }
        let chinesestring = self.txtHanzi.text!.replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;")
        self.txtPinyin.text = ""
        self.webOutput.loadHTMLString("", baseURL: nil)
        if chinesestring == ""
        {
            return
        }
        self.txtHanzi.resignFirstResponder()
        self.txtPinyin.isHidden = true
        self.webOutput.isHidden = false
        let numcharsinfirstchunk = numberOfCharactersThatFitTextView(view: self.txtHanzi) + 50

        DispatchQueue.global(qos: .userInteractive).async {
            //Update UI, activity indicator
            DispatchQueue.main.async {
                self.startSpinner()
            }
            
            let chunks = chinesestring.getChunks(ofMinSize: numcharsinfirstchunk, separatedBy: "。")
            var outputstring = ""
            var displayfirst = false
            for chunk in chunks
            {
                outputstring += PYDB.convert(hanzi: chunk, true)
                if !displayfirst
                {
                    displayfirst = true
                    DispatchQueue.main.async {
                        let displayChinesestring = "<style> body {font-size: 30pt;} rt {font-size: 18pt;} </style>" + outputstring.replacingOccurrences(of: "\n", with: "<br/>")
                        self.webOutput.loadHTMLString(displayChinesestring, baseURL: nil)
                        
                    }
                }
            }
            //update UI
            DispatchQueue.main.async {
                self.txtPinyin.text = chinesestring
                let displayChinesestring = "<style> body {font-size: 30pt;} rt {font-size: 18pt;} </style>" + outputstring.replacingOccurrences(of: "\n", with: "<br/>")
                self.webOutput.loadHTMLString(displayChinesestring, baseURL: nil)
                self.stopSpinner()
                
            }
        }
    }

   /*
    func convert(hanzi:String, _ useRuby:Bool = false) -> String
    {
        var chinesestring = hanzi.replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;")
        //the number of words with 5 or more chars are so few that it's easier to hard-code
        var list = ["帖撒罗尼迦","帖撒羅尼迦","哈米吉多顿","哈米吉多頓"]
        
        do {
            for ofs in [4,3,2,1]
            {
                if chinesestring.count < ofs
                { continue }
                
                var start = chinesestring.startIndex
                var end = chinesestring.index(start, offsetBy: ofs)
                while end <= chinesestring.endIndex
                {
                    let snip = String(chinesestring[start..<end])
                    list.append(snip)
                    if end == chinesestring.endIndex
                    {
                        break
                    }
                    start = chinesestring.index(start, offsetBy: 1, limitedBy: chinesestring.endIndex)!
                    end = chinesestring.index(start, offsetBy: ofs)
                }
            }
            
            let arraystring = "(\"" + list.joined(separator: "\", \"") + "\")"
            //build query
            let query = "select id,hanzi,pinyin from pinyin where hanzi in \(arraystring) order by length desc"
            let stm = try self.db.prepare(query)
            let faststr = FastString.init(chinesestring)
            var rubyReversal:[[String]] = []
            for row in stm
            {
                let id = String(row[0] as! Int64)
                let hz = row[1] as! String
                let py = row[2] as! String
                var search = hz
                var replace = "\(py) "
                if useRuby
                {
                    search = hz
                    replace = "<ruby>\(id)<rt>\(py)</rt></ruby> "
                    rubyReversal.append([id,hz,py])
                }
                faststr.replace(searchTerm: search, replacement: replace)
            }
            if useRuby
            {
                for r in rubyReversal
                {
                    faststr.replace(searchTerm: "<ruby>\(r[0])<", replacement: "<ruby>\(r[1])<")
                }
            }
            chinesestring = faststr.toString()
            chinesestring = chinesestring.fixPunctuation()
            chinesestring = chinesestring.replacingOccurrences(of: "&lt;", with: "<").replacingOccurrences(of: "&gt;", with: ">")
        }
        catch
        {
            print(error)
        }
        return chinesestring
    }*/

    func flashMesssage(text:String)
    {
        self.lblMessage.text = " \(text) "
        UIView.animate(withDuration: 1, delay: 1, options: .curveEaseIn, animations: {
            self.lblMessage.alpha = 0
        }) { _ in
            self.lblMessage.isHidden = true
            self.lblMessage.alpha = 1
        }
    }
    
    @IBAction func copyText(_ sender: Any) {
        self.lblMessage.isHidden = false
        UIPasteboard.general.string = self.txtPinyin.text!
        flashMesssage(text: "Text copied")
        
    }
    
    @IBAction func pasteText(_ sender: Any) {
        self.txtHanzi.text = UIPasteboard.general.string
        //self.lblHanziHint.isHidden = (!self.inputText.text.isEmpty)
    }
    
/*    func PinyinDBUpdate(_ text: String) {
        flashMesssage(text: text)
    }*/

}
