//
//  Base.swift
//  PurePinyin
//
//  Created by Joakim Fännick on 2018-09-23.
//  Copyright © 2018 Joakim Fännick. All rights reserved.
//

import UIKit
import Foundation
import SQLite

extension UnicodeScalar {
    var isHanzi: Bool {
        return self.value >= 13312 && self.value <= 177972
/*        switch value {
        case 0x2E80...0x2FD5, // Hanzi range 1
        0x3400...0x4DBF, // Hanzi range 2
        0x4E00...0x9FCC: // Hanzi range 3
            return true
        default: return false
        }*/
    }
    
    func hideHanzi() -> UnicodeScalar
    {
        if value >= 13312 && value <= 177972
        {
            return UnicodeScalar(self.value + 164700)!
        }
        return self
    }

    func showHanzi() -> UnicodeScalar
    {
        if value >= 178012 && value <= 342672
        {
            return UnicodeScalar(self.value - 164700)!
        }
        return self
    }
}

extension Character
{
    var isHanzi: Bool {
        return self.unicodeScalars.first!.isHanzi
    }
}

extension String {
    var containsHanzi: Bool { // string contains a chinese character or more
        return unicodeScalars.contains { $0.isHanzi }
    }
    
    var containsOnlyHanzi: Bool {
        return !isEmpty
            && !unicodeScalars.contains(where: {
                !$0.isHanzi
            })
    }
    
    func fixPunctuation() -> String
    {
        var instring = self
        let punctuations = [["。",    ". "],
                            ["，",    ", "],
                            ["、",    ", "],
                            ["；",    "; "],
                            ["：",    ": "],
                            ["！",    "! "],
                            ["？",    "? "],
                            ["（",    " ("],
                            ["）",    ") "],
                            ["【",    " ("],
                            ["】",    ") "],
                            ["《",    "\""],
                            ["》",    "\" "],
                            ["“",    "\""],
                            ["”",    "\""],
                            ["「",    "\""],
                            ["」",    "\""],
                            [" \\.", "\\."],
                            [" ,",   ","],
                            [" \\?",   "\\?"],
                            [" \\!",   "\\!"],
                            [" )",  ")"],
                            [" ;",  ";"],
                            ["  ",  " "]

        ]
        for pair in punctuations
        {
            instring = instring.replacingOccurrences(of: pair[0], with: pair[1], options: .regularExpression)
        }
        return instring
    }
    
    func getChunks(ofMinSize:Int = 500, separatedBy:String = "。") -> [String]
    {
        let sentences = self.components(separatedBy: separatedBy)
        var outlist:[String] = []
        var workstring = ""
        for sentence in sentences
        {
            workstring.append(sentence)
            if !workstring.hasSuffix(separatedBy)
            {
                workstring.append(separatedBy)
            }
            if workstring.count > ofMinSize
            {
                outlist.append(workstring)
                workstring = ""
            }
        }
        if workstring.count > 0
        {
            outlist.append(workstring)
        }
        return outlist
    }
    
    func hideHanzi() -> String
    {
        var out = ""
        for c in self.unicodeScalars
        {
            var v = c.value
            if v >= 13312 && v <= 177972
            {
                v = v + 164700
            }
            out.append(Character(c.hideHanzi()))
        }
        return out
    }
    func showHanzi() -> String
    {
        var out = ""
       
        for c in self.unicodeScalars
        {
            var v = c.value
            if v >= 178012 && v <= 342672
            {
                v = v - 164700
            }
            out.append(Character(c.showHanzi()))
        }
        return out
    }
}

func numberOfCharactersThatFitTextView(view:UITextView) -> Int {
    let fontRef = CTFontCreateWithName(view.font!.fontName as CFString, view.font!.pointSize, nil)
    let attributes = [kCTFontAttributeName : fontRef]
    let attributedString = NSAttributedString(string: view.text!, attributes: attributes as [NSAttributedStringKey : Any])
    let frameSetterRef = CTFramesetterCreateWithAttributedString(attributedString as CFAttributedString)
    
    var characterFitRange: CFRange = CFRange()
    
    CTFramesetterSuggestFrameSizeWithConstraints(frameSetterRef, CFRangeMake(0, 0), nil, CGSize(width: view.bounds.size.width, height: view.bounds.size.height), &characterFitRange)
    return Int(characterFitRange.length)
    
}

extension UIView {
    func currentFirstResponder() -> UIResponder? {
        if self.isFirstResponder {
            return self
        }
        
        for view in self.subviews {
            if let responder = view.currentFirstResponder() {
                return responder
            }
        }
        return nil
    }
}



class PinyinDB {
    var db:Connection? = nil
    var databaseIsLoaded = false
    
    let SuggestionsTable = Table("suggestions")
    let WordlistTable = Table("dictionary")
    let hanziField = Expression<String>("hanzi")
    let romanField = Expression<String>("romanization")
    let matchField = Expression<String>("match")
    let wordField = Expression<String>("pinyin")
    let freqField = Expression<Int64>("freq")
    let suggestionsField = Expression<String>("suggestions")
    
    var dbFilePath = ""

    init() {
        self.initDB()
    }

    func getPathTo(file:String) -> URL
    {
        let fm = FileManager.default
        let sharedContainer = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.CommonStorage")
        let out = sharedContainer!.appendingPathComponent(file)
        return out
    }
    
    func fileExists(name:String) -> Bool
    {
        let fileURL = self.getPathTo(file: name)
        do {
            return try fileURL.checkResourceIsReachable()
        }
        catch
        {
            return false
        }
    }
    func removeFile(name:URL) -> Bool
    {
        do {
            try FileManager.default.removeItem(at: name)
        }
        catch
        {
            return false
        }
        return true
    }

    func removeFile(name:String) -> Bool
    {
        let fullPath = self.getPathTo(file: name)
        return removeFile(name: fullPath)
     }
    
    func renameFile(name1:String, name2:String) -> Bool
    {
        do {
            let fullPath1 = self.getPathTo(file: name1)
            let fullPath2 = self.getPathTo(file: name2)
            try FileManager.default.copyItem(at: fullPath1, to: fullPath2)
        }
        catch
        {
            return false
        }
        return true
    }
    
    func getConnection(dbfile:String) -> Connection?
    {
        if self.db != nil
        {
            return self.db
        }
        do
        {
            let con = try Connection(getPathTo(file: "dictionary.sqlite").path)
            return con
        }
        catch {
            return nil
        }
    }
    
    func getConnection() -> Connection?
    {
        return getConnection(dbfile: "dictionary.sqlite")
    }
    
    func initDB()
    {
      do {
    //    try FileManager.default.removeItem(atPath: getPathTo(file: "dictionary.sqlite").path)
        if !self.fileExists(name: "dictionary.sqlite")
        {
            FileManager.default.createFile(atPath: getPathTo(file: "dictionary.sqlite").path, contents: Data.init(), attributes: nil)
        }
        self.db = self.getConnection(dbfile: "dictionary.sqlite")
/*
 CREATE TABLE "dictionary" (
 "id"    INTEGER NOT NULL,
 "hanzi"    VARCHAR,
 "pinyin"    VARCHAR,
 "canto"    VARCHAR,
 "english"    VARCHAR,
 "freq"    INTEGER,
 PRIMARY KEY("id")
 );*/
            try self.db!.run("""
            CREATE TABLE IF NOT EXISTS suggestions (
                id    INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                words    TEXT NOT NULL,
                suggestions    TEXT NOT NULL
            );
            """)
        }
        catch {
            print(error)
            
        }
        self.databaseIsLoaded = (self.db != nil)
    }

    
    func updateFromExternalFile(_ filename:URL,_ tablename:String = "pinyin") -> (Bool,String)
    {
        do {
            let fullpath = filename.path
            try self.db!.run("ATTACH DATABASE ? AS upd;", fullpath)
            try self.db!.run("DROP TABLE IF EXISTS main.\(tablename);")
            try self.db!.run("CREATE TABLE main.\(tablename) AS SELECT * FROM upd.\(tablename);")
            try self.db!.run("DETACH DATABASE upd;")
        }
        catch
        {
            return (false, error.localizedDescription)
        }
        return (true, "Yay!")
    }
    
   /* func getSuggestions(to: String) -> [String]
    {
        var outputlist:[String] = []
        var suggestionfragment = ""
        var previousword = ""
        var text = to
        do {

            if (text.count > 0) && (text.last != "\n")
            {
                //if we are right of a space, display suggestions
                //If the character before the cursor is a space, it means we should find a suggestion from the list of words that is commonly used after one another
                
                var lastWords = text.lowercased().lastWords(6)
                
                //if the last word is alphanumeric, not a space or punctuation
                if text.last!.isAlpha()// != " "
                {
                    //this is a fragment of a word, we want to get a suggestion based on this
                    suggestionfragment = text.lastWord
                    //drop the last word from the list
                    lastWords = Array(lastWords.dropLast())
                }
                
                //there are words to search suggestions for
                if lastWords.count > 0
                {
                    previousword = lastWords.last!
                    var matches:[String] = []
                    //create a list of match-words, used to search the database for suggestions
                    //match words are simplified to only lowercase letters, umlauts to v's
                    while lastWords.count > 0
                    {
                        matches.append(lastWords.joined(separator: " ").makeMatchWord())
                        lastWords = Array(lastWords.dropFirst())
                    }
                    //look through database for suggestions that match these match phrases, from long to short, so we get the most pertinent suggestions first.
                    for thismatch in matches
                    {
                        for suggestion_string in try PinyinDB.shared.db!.prepare(SuggestionsTable.filter(matchField.glob(thismatch)))
                        {
                            let newword = try suggestion_string.get(suggestionsField)
                            if newword == ""
                            {
                                continue
                            }
                            let newwordslist = newword.components(separatedBy: " ")
                            for newwordpart in newwordslist
                            {
                                if suggestionfragment == "" || newwordpart.makeMatchWord().hasPrefix(suggestionfragment.makeMatchWord())
                                {
                                    let newword = newwordpart.matchCapitalization(with: suggestionfragment)
                                    if !outputlist.contains(newword)
                                    {
                                        outputlist.append(newword)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
        //let rows = try PinyinDB.shared.db!.prepare(SuggestionsTable.select(suggestionsField).filter(matchField.glob(to))
            //Default list of suggestions order(freqField).
            let thismatch = suggestionfragment.makeMatchWord() + "*"
            var added = false
            let rows = try PinyinDB.shared.db.prepare(WordlistTable.select(distinct: wordField).filter(matchField.glob(thismatch)).order(freqField.asc).limit(20))
            
            for suggestion_string in rows
            {
                let newword:String = try suggestion_string.get(wordField).matchCapitalization(with: suggestionfragment)
                if !outputlist.contains(newword)
                {
                    outputlist.append(newword)
                    added = true
                }
            }
            //if there are absolutely no matches for the sniplet, take stronger measures.
            if outputlist.count == 0
            {
                let thismatch = suggestionfragment.makeMatchWord().inserting(separator: "*", every: 1) + "*"
                
                for suggestion_string in try PinyinDB.shared.db!.prepare(WordlistTable.select(distinct: wordField).filter(matchField.glob(thismatch)).order(freqField.asc).limit(20))
                {
                    let newword:String = try suggestion_string.get(wordField).matchCapitalization(with: suggestionfragment)
                    if !outputlist.contains(newword)
                    {
                        outputlist.append(newword)
                        added = true
                        if outputlist.count >= 20
                        {
                            break
                        }
                    }
                }
            }
            if !added && suggestionfragment != ""
            {
                outputlist.append(suggestionfragment)
            }
        }
        catch {
            return []
        }
        return outputlist
    }*/
    
    func tableExits(_ tableName:String = "pinyin") -> Bool
    {
        if let c = self.getConnection()
        {
            let table = Table(tableName)
            do {
                try c.scalar(table.exists)
                return true
            } catch {
                return false
            }
        }
        else
        {
            return false
        }
    }
  
    func newconvert(hanzi:String) -> String
    {
        let startTime = Date()
        var instring = hanzi
        var outstring = ""
        while instring != ""
        {
            if let firstchar = instring.first
            { //pick first character
                if firstchar.isHanzi
                { //if hanzi, operate, otherwise just pass it out
                    do
                    { //look up all words starting with this hanzi, order by longest to shortest.
                        let stm = try self.db!.prepare("select hanzi, pinyin from pinyin where hanzi like \"\(firstchar)%\" order by length(hanzi) desc")
                        var replaced = false
                        for row in stm
                        { //try each word from long to short, see if the goal text fits it
                            let hanzi = row[0] as! String
                            let pinyin = row[1] as! String
                            if String(instring.prefix(hanzi.count)) == hanzi
                            { //if it fits, add the pinyin to the out string, cut it out from the instring and quit the loop
                                outstring += String(pinyin) + " "
                                instring = String(instring.dropFirst(hanzi.count))
                                replaced = true
                                break
                            }
                        }
                        if replaced == false
                        {
                            outstring += String(firstchar)
                            instring = String(instring.dropFirst())
                        }
                    }
                    catch
                    { //database error
                        print(error)
                    }
                }
                else
                { //not hanzi, pass it along
                    outstring += String(firstchar)
                    instring = String(instring.dropFirst())
                }
            }
            else
            { //if something goes wrong, failsafe bail the last string and exit
                outstring += instring
                instring = ""
            }
            //print(outstring)
        }
        let endTime = Date()
        let totalTime = endTime.timeIntervalSince(startTime)
        print("Total time: \(totalTime)")
        return outstring
    }
    
    func convert(hanzi:String, _ useRuby:Bool = false, _ romanization:String = "pinyin") -> String
    {
        //return newconvert(hanzi: hanzi)
        var chinesestring = hanzi.replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;")
        //the number of words with 5 or more chars are so few that it's easier to hard-code
        var list = ["帖撒罗尼迦","帖撒羅尼迦","哈米吉多顿","哈米吉多頓"]
        let startTime = Date()
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
            let query = "select id,hanzi,\(romanization) from \(romanization) where hanzi in \(arraystring) order by length(hanzi) desc"
            let stm = try self.db!.prepare(query)
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
                    replace = "<ruby>\(hz.hideHanzi())<rt>\(py)</rt></ruby> "
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
            if useRuby
            {
                chinesestring = chinesestring.showHanzi()
            }
            chinesestring = chinesestring.fixPunctuation()
            chinesestring = chinesestring.replacingOccurrences(of: "&lt;", with: "<").replacingOccurrences(of: "&gt;", with: ">")
        }
        catch
        {
            print(error)
        }
        let endTime = Date()
        let totalTime = endTime.timeIntervalSince(startTime)
        print("Total time: \(totalTime)")
        return chinesestring
    }
}

let PYDB:PinyinDB = PinyinDB()
