//
//  ViewController.swift
//  PurePinyin
//
//  Created by Joakim Fännick on 2017-08-29.
//  Copyright © 2017 Joakim Fännick. All rights reserved.
//

/*import UIKit
import WebKit
import SQLite


class PYConvertViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    @IBOutlet var mainView: UIView!
    
    @IBOutlet weak var messageLbl: UILabel!
    @IBOutlet weak var mainScroll: UIScrollView!
    @IBOutlet weak var hanziView: UIView!
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var pinyinView: UIView!
    @IBOutlet weak var inputText: UITextView!
    @IBOutlet weak var outputText: UITextView!
    @IBOutlet weak var pasteBtn: UIButton!
    @IBOutlet weak var pinyinBtn: UIButton!
    @IBOutlet weak var rubyBtn: UIButton!
    @IBOutlet weak var copyBtn: UIButton!
    @IBOutlet weak var activity: UIActivityIndicatorView!
    @IBOutlet weak var outputWebView: WKWebView!
    @IBOutlet weak var lblHanziHint: UILabel!
    var db:Connection!

    var currentSize:CGSize = CGSize.zero
    
    var keyboardHeight = CGFloat(0.0)
    
    func initDB()
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
                //try self.db!.run("CREATE TABLE IF NOT EXISTS `convertdata` ( `text` TEXT, `pinyin` TEXT, `ruby` TEXT, PRIMARY KEY(`text`) )")
                
                //try self.db!.run("CREATE TABLE IF NOT EXISTS `permutations` ( `text` TEXT )")
                
            } else {
                print("Database file found at path: \(finalDatabaseURL.path)")
                //open connection
                self.db = try Connection(finalDatabaseURL.path)

            }
        } catch  {
            print("Error:\(error)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initDB()

        currentSize = self.view.bounds.size
        
        inputText.layer.cornerRadius = 5
        inputText.layer.borderColor = UIColor.init(red: 0.855, green: 0.9, blue: 1.0, alpha: 1.0).cgColor
        inputText.layer.borderWidth = 3

        outputText.layer.cornerRadius = 5
        outputText.layer.borderColor = UIColor.init(red: 0.855, green: 0.9, blue: 1.0, alpha: 1.0).cgColor
        outputText.layer.borderWidth = 3
        outputWebView.layer.cornerRadius = 5
        outputWebView.layer.borderColor = UIColor.init(red: 0.855, green: 0.9, blue: 1.0, alpha: 1.0).cgColor
        outputWebView.layer.borderWidth = 3
        
        for btn in [self.pasteBtn,self.pinyinBtn,self.rubyBtn,self.copyBtn] as! [UIButton]
        {
            btn.layer.cornerRadius = 5
            btn.layer.shadowColor = UIColor.black.cgColor
            btn.layer.shadowOffset = CGSize.init(width: 0, height: 1)
            btn.layer.shadowOpacity = 0.5
            btn.layer.shadowRadius = 0.0
            btn.layer.masksToBounds = false
            
        }
        
        self.inputText.delegate = self
        self.outputText.delegate = self

        //catch events launching keyboard
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
        self.keyboardHeight = 0
        updateViewConstraints()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { get { return .all } }
    
    func statusBarHeight() -> CGFloat
    {
        //iphones in landscape mode hides status bar, so we need to account for that
        if UIDevice.current.userInterfaceIdiom == .phone && (UIDevice.current.orientation == UIDeviceOrientation.landscapeRight || UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft)
        {
            return 0
        }
        return 20
    }
    
    func tabBarHeight() -> CGFloat
    {
        if let tbc = self.tabBarController
        {
            return tbc.tabBar.frame.height
        }
        return 0.0
    }

    override func updateViewConstraints() {
        //update layout of all things
        super.updateViewConstraints()
        let bounds = self.currentSize //getTrueBounds()
        
        let middlebuttongap = CGFloat(20.0)
        
        self.mainScroll.frame = CGRect.init(x: 0, y: statusBarHeight(), width: bounds.width, height: bounds.height - statusBarHeight() - tabBarHeight())

        self.hanziView.frame = CGRect.init(x: 0, y: 0, width: self.mainScroll.frame.width, height: CGFloat((self.mainScroll.frame.height/2)-25))
            self.inputText.frame = CGRect.init(x: 5, y: 5, width: self.mainScroll.frame.width - 10, height: self.hanziView.frame.height - 10)
            self.lblHanziHint.frame = CGRect.init(x: 10, y: 6, width: 200, height: 30)
            self.lblHanziHint.isHidden = (!self.inputText.text.isEmpty)
               
        self.buttonView.frame = CGRect.init(x: 0, y: (self.mainScroll.frame.height/2)-25, width: self.mainScroll.frame.width, height: 50)
            self.pasteBtn.frame = CGRect.init(x: (middlebuttongap/2), y: CGFloat(5.0), width: CGFloat(self.buttonView.frame.width/4)-middlebuttongap, height: self.buttonView.frame.height-10)
            self.pinyinBtn.frame = CGRect.init(x:  self.buttonView.frame.width * 0.25 + (middlebuttongap/2), y:5, width: self.buttonView.frame.width/4 - middlebuttongap, height: self.buttonView.frame.height-10)
            self.rubyBtn.frame = CGRect.init(x:  self.buttonView.frame.width * 0.5 + (middlebuttongap/2), y: 5, width: self.buttonView.frame.width/4 - middlebuttongap, height: self.buttonView.frame.height-10)
            self.copyBtn.frame = CGRect.init(x:  self.buttonView.frame.width * 0.75 + (middlebuttongap/2), y: 5, width: self.buttonView.frame.width/4 - middlebuttongap, height: self.buttonView.frame.height-10)
        self.pinyinView.frame = CGRect.init(x: 0, y: (self.mainScroll.frame.height/2)+25, width: self.mainScroll.frame.width, height: (self.mainScroll.frame.height/2)-25)
            self.outputText.frame = CGRect.init(x: 5, y: 5, width: self.mainScroll.frame.width - 10 , height: self.pinyinView.frame.height - 10)
        self.outputWebView.frame = CGRect.init(x: 5, y: 5, width: self.mainScroll.frame.width - 10 , height: self.pinyinView.frame.height - 10)

        self.mainScroll.contentSize = CGSize.init(width: bounds.width, height: bounds.height - statusBarHeight() + self.keyboardHeight)
        
        self.lblHanziHint.isHidden = (!self.inputText.text.isEmpty)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.currentSize = size
        self.updateViewConstraints()
    }


    
//################################# KEYBOARD HANDLING FUNCTIONS ###########################################
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            self.keyboardHeight = keyboardRectangle.height
            self.updateViewConstraints()
        }
    }
    @objc func keyboardWillHide(_ notification: Notification) {
        self.keyboardHeight = 0
        self.updateViewConstraints()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        textView.resignFirstResponder()
        self.lblHanziHint.isHidden = (!self.inputText.text.isEmpty)
    }
    

    func textViewDidBeginEditing(_ textView: UITextView) {
        self.lblHanziHint.isHidden = (!self.inputText.text.isEmpty)
        let textviewBottom = textView.convert(CGPoint.init(x: 0, y: textView.frame.height), to: self.mainScroll)
        let textviewTop = textView.convert(CGPoint.init(x: 0, y: 0), to: self.view)

        let bounds = self.currentSize
        if textviewBottom.y > bounds.height  - self.keyboardHeight
        {
            let myoffset = CGPoint.init(x: 0, y: textviewBottom.y - (bounds.height - self.keyboardHeight - (self.statusBarHeight() + 5 + tabBarHeight())))
             self.mainScroll.setContentOffset(myoffset, animated: true)
        }
        else
        if textviewTop.y < 0
        {
            let myoffset = CGPoint.init(x: 0, y: 0)
            self.mainScroll.setContentOffset(myoffset, animated: true)
        }

    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.lblHanziHint.isHidden = (!self.inputText.text.isEmpty)
    }
    

    
    //################################# BUTTON STYLE FUNCTIONS ###########################################

    
    @IBAction func buttonTouchDown(_ sender: UIButton) {
        sender.backgroundColor = UIColor.lightGray
    }
    
    @IBAction func buttonTouchUp(_ sender: UIButton) {
        sender.backgroundColor = UIColor.white
    }
    //################################# PINYIN FUNCTIONS ###########################################
    
    func convertText(useRuby:Bool = false) {
        
        var chinesestring = self.inputText.text!.replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;")
        self.outputText.text = ""
        self.outputWebView.loadHTMLString("", baseURL: nil)
        if useRuby
        {
            self.outputText.isHidden = true
            self.outputWebView.isHidden = false
        }
        else
        {
            self.outputText.isHidden = false
            self.outputWebView.isHidden = true
            
        }
        if chinesestring == ""
        {
            return
        }
        DispatchQueue.global(qos: .userInteractive).async {
            //Update UI, activity indicator
            DispatchQueue.main.async {
                self.activity.center = CGPoint.init(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY / 2)
                self.activity.isHidden = false
                self.activity.startAnimating()
                self.pinyinBtn.isEnabled = false
                self.rubyBtn.isEnabled = false
                
            }
            
            //the number of words with 5 or more chars are so few that it's easier to hard-code
            /*var list = ["帖撒罗尼迦","帖撒羅尼迦","哈米吉多顿","哈米吉多頓"]
            
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
                var displayChinesestring = """
                     <style>
                     body
                     {
                     font-size:30pt;
                     }
                     rt
                     {
                     font-size:18pt;
                     }
                     </style>
                     """ + chinesestring.replacingOccurrences(of: "\n", with: "<br/>")
                
                chinesestring = chinesestring.replacingOccurrences(of: "&lt;", with: "<").replacingOccurrences(of: "&gt;", with: ">")
 */
                /*let PYTool = PinyinTools()
                chinesestring = PYTool.convert(hanzi: chinesestring, useRuby)*/
            
                let displayChinesestring = """
                     <style>
                     body
                     {
                     font-size:30pt;
                     }
                     rt
                     {
                     font-size:18pt;
                     }
                     </style>
                     """ + chinesestring.replacingOccurrences(of: "\n", with: "<br/>")
                
                //update UI
                DispatchQueue.main.async {
                    self.outputText.text = chinesestring
                    self.outputWebView.loadHTMLString(displayChinesestring, baseURL: nil)
                    self.activity.isHidden = true
                    self.activity.stopAnimating()
                    self.pinyinBtn.isEnabled = true
                    self.rubyBtn.isEnabled = true
                }
                
            /*} catch {
                // handle
                print(error)
            }*/
        }
    }

    
    @IBAction func getPinyin(_ sender: Any) {
        convertText()
    }

    @IBAction func getRuby(_ sender: Any) {
        convertText(useRuby: true)
    }
    
    @IBAction func pasteText(_ sender: Any) {
        self.inputText.text = UIPasteboard.general.string
        self.lblHanziHint.isHidden = (!self.inputText.text.isEmpty)
        
    }
    
    @IBAction func copyText(_ sender: Any) {
        self.messageLbl.center = CGPoint.init(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY / 2)
        self.messageLbl.isHidden = false
        UIPasteboard.general.string = self.outputText.text!
        UIView.animate(withDuration: 1, delay: 1, options: .curveEaseIn, animations: {
            self.messageLbl.alpha = 0
        }) { _ in
            self.messageLbl.isHidden = true
            self.messageLbl.alpha = 1
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("Memory warning")
        // Dispose of any resources that can be recreated.
    }

}
*/
