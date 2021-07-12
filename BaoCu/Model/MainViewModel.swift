//
//  MainViewModel.swift
//  BaoCu
//
//  Created by Nguyễn Minh on 10/07/2021.
//

import Foundation
import RxCocoa
import RxSwift
struct MainViewModel{
    private var url: String = "https://vnexpress.net/rss/tin-moi-nhat.rss"
    static var shared = MainViewModel()
     var itemObserve : Observable<[Item]> {
        return NewService.shared.parseNew(url: self.url).startWith()
        
    }
    
}
