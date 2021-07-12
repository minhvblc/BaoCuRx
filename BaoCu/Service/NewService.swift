//
//  NewService.swift
//  BaoCu
//
//  Created by Nguyễn Minh on 02/07/2021.
//

import Foundation
import Alamofire
import SwiftSoup
import RxSwift
import RxCocoa
typealias parserCompletionHandler = (([Item])->Void)
class NewService : NSObject{
    static var shared = NewService()
   
    private var currentElement = ""
    
    private var item : [Item] = []
    private var currentTitle : String = ""
    private var currentPubDate: String = ""
    private var currentLink: String = ""
    private var currentDescriptionNews : String = ""
    private var currentNumCmt: String = ""
    var newItem : Item?
    var linkHrefImg: String = ""
    var descriptionText: String = ""
    
    var parserCompletionHandler : parserCompletionHandler?
    
    private var foundCharacters = ""
    
    func parseNew(url : String)-> Observable<[Item]>{

        return Observable<[Item]>.create{ observer in
            AF.request(url, method: .get)
                .response(queue: DispatchQueue(label: "getTrending", qos: .userInitiated)){ response in
                guard let data = response.data else {return }
                    let xmlParser = XMLParser(data: data)
                    xmlParser.delegate = self
                    xmlParser.parse()
                    observer.onNext(self.item)
                    observer.onCompleted()
            }
            return Disposables.create()
        }
       
    }
   
}





extension NewService: XMLParserDelegate {

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        print(currentElement)
        switch currentElement {
      
        case "title":
            currentTitle += string
        case "pubDate":
            currentPubDate += string
        case "link":
            currentLink += string
        case "slash:comments":
            currentNumCmt += string
        default:
            break
        }
       
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if currentElement == "item"{
            currentLink = ""
            currentTitle = ""
            currentPubDate = ""
            currentDescriptionNews = ""
            currentNumCmt = ""
            linkHrefImg = ""
            descriptionText = ""
        }
    }

     func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item"{
            let newsItem = Item(title: currentTitle, pubDate: currentPubDate, link: currentLink, descriptionNews: Description(description: descriptionText, urlImg: linkHrefImg), numCmt: currentNumCmt)
//            self.newItem = newsItem
            self.item.append(newsItem)
        }
        
        
    }
    func parserDidEndDocument(_ parser: XMLParser) {
//        parserCompletionHandler?(self.item)
    }
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print(parseError.localizedDescription)
    }
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        let s = String(data: CDATABlock, encoding: .utf8)
        if currentElement == "description"{
            currentDescriptionNews += s!

            do {
               
                let doc: Document = try SwiftSoup.parse(currentDescriptionNews)
               
                let link: Element? = try doc.select("img").first()
                if let link = link{
                    linkHrefImg = try link.attr("src")
                }else{
                    linkHrefImg = (currentLink != "") ? currentLink : ""
                }
                
                descriptionText = try  doc.body()?.text() ?? ""
                
            } catch Exception.Error( _, let message) {
                print(message)
            } catch {
                print("error")
            }
        }
        
    
    }
}
