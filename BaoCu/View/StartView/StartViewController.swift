//
//  StartViewController.swift
//  BaoCu
//
//  Created by Nguyễn Minh on 02/07/2021.
//

import UIKit

class StartViewController: UIViewController {
    
    
    var items : [Item]?
    var url: String = "https://vnexpress.net/rss/tin-moi-nhat.rss"
    
    
    func setUpData(){
        let vc = MainViewController()
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpData()
        setupNoti()
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    func setupNoti(){
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            
        }
        let contents = UNMutableNotificationContent()
        contents.title = "Đọc tin tức mới nhát"
        contents.body = "Đọc tin tức mới nhát ngay thôi"
        contents.badge = NSNumber(value: 12)
     
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current

        dateComponents.hour = 9
        dateComponents.minute = 30
           
    
        let trigger = UNCalendarNotificationTrigger(
                 dateMatching: dateComponents, repeats: true)
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString,
                    content: contents, trigger: trigger)
        
        center.add(request) { (error) in
           if error != nil {
            print(error?.localizedDescription ?? "error")
           }
           else{
            print("ok")
           }
           
        }
    }

    
}
