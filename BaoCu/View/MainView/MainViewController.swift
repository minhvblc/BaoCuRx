//
//  MainViewController.swift
//  BaoCu
//
//  Created by Nguyễn Minh on 02/07/2021.
//

//import UIKit
//import SideMenu
//import SDWebImage
//import SafariServices
//class MainViewController: UIViewController {
//    var menu : SideMenuNavigationController?
//    var service = NewService()
//    var items : [Item] = []
//    var type = ChannelName.trangChu
//    var url: String = "https://vnexpress.net/rss/tin-moi-nhat.rss"
//
//    @IBOutlet weak var tableView: UITableView!
//    let refreshControl = UIRefreshControl()
//
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        tableView.delegate = self
//        tableView.dataSource = self
//        tableView.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
//        setupSideMenu()
//        initUI()
//
//    }
//    //refresh data
//    @objc func refresh(_ sender: AnyObject?) {
//        self.service.parseNew(url: url, completionHandler: { (items) in
//            self.items = items
//            DispatchQueue.main.async {
//                self.tableView.reloadData()
//                self.refreshControl.endRefreshing()
//                self.setupSideMenu()
//            }
//        })
//    }
//    func setupSideMenu(){
//        let vc = MenuTableViewController()
//        vc.pickDone = { (url, type) in
//            self.url = url
//            self.service.parseNew(url: url, completionHandler: { (items) in
//
//                self.items = items
//                self.type = type
//
//                DispatchQueue.main.async {
//                    self.tableView.reloadData()
//                    self.title = type.rawValue
//                    self.setupSideMenu()
//                }
//
//            })
//        }
//        vc.type = type
//        menu = SideMenuNavigationController(rootViewController: vc)
//        let img = UIImage(systemName: "list.dash")?.withRenderingMode(.alwaysTemplate)
//        let menuBtn = UIBarButtonItem(image: img, style: .plain, target: self, action: #selector(didTapMenu))
//        menuBtn.tintColor = .white
//        self.navigationItem.leftBarButtonItem  = menuBtn
//        menu?.leftSide = true
//        SideMenuManager.default.leftMenuNavigationController = menu
//        SideMenuManager.default.addPanGestureToPresent(toView: self.view)
//        menu?.animationOptions = .curveEaseInOut
//        menu?.presentationStyle = .menuDissolveIn
//
//    }
//
//    func initUI(){
//        self.title = "Trang chủ"
//        tableView.reloadData()
//        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
//        tableView.addSubview(refreshControl)
//        navigationController?.setNavigationBarHidden(false, animated: true)
//        menu?.animationOptions = .curveEaseInOut
//        menu?.presentationStyle = .viewSlideOutMenuIn
//        self.navigationController?.navigationBar.barTintColor = #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)
//    }
//
//    @objc func didTapMenu(sender : UIButton){
//        present(menu!, animated: true, completion: nil)
//    }
//}
//
//extension MainViewController: UITableViewDataSource, UITableViewDelegate{
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return items.count
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! TableViewCell
//        cell.initUI(item: items[indexPath.row])
//        cell.presentShare = {
//            let stringURL = self.items[indexPath.row].link?.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: .newlines)
//
//            guard let url = URL(string: stringURL ?? "") else { return }
//            let items = [url]
//            let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
//            self.present(ac, animated: true, completion: nil)
//
//        }
//        return cell
//    }
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let stringURL = items[indexPath.row].link?.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: .newlines)
//        guard let url = URL(string: stringURL ?? "") else { return }
//        let vc = SFSafariViewController(url: url)
//        present(vc, animated: true, completion: nil)
//    }
//
//
//
//
//}



import UIKit
import SideMenu
import SDWebImage
import SafariServices
import RxCocoa
import RxSwift
class MainViewController: UIViewController {
    let bag = DisposeBag()
    var menu : SideMenuNavigationController?
    var service = MainViewModel.shared
    var items : [Item] = []
    var type = ChannelName.trangChu
    var url: String = "https://vnexpress.net/rss/tin-moi-nhat.rss"
    
    @IBOutlet weak var tableView: UITableView!
    let refreshControl = UIRefreshControl()
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        setUpTableView()
        setupSideMenu()
        initUI()
        tableView.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
        setupRefresh()
    }
    func setupRefresh(){
        refreshControl.rx.controlEvent(.valueChanged).flatMapLatest { _ in
            return self.service.itemObserve.startWith([Item]())
        
        }.observe(on: MainScheduler.instance).subscribe { items in
            print(items)
            self.refreshControl.endRefreshing()
        }.disposed(by: bag)
    }
    func setUpTableView(){
        //set data
        let globalScheduler = ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global())
        service.itemObserve.subscribe(on: globalScheduler)
            // Observe in main thread
            .observe(on: MainScheduler.instance).bind(to: tableView.rx.items(cellIdentifier: "cell", cellType: TableViewCell.self)){(index, data, cell) in
           
            cell.initUI(item: data)
        }.disposed(by: bag)
        
        //set up select item
        tableView.rx.modelSelected(Item.self).map { item in
            let stringURL = item.link?.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: .newlines)
            return URL(string: stringURL ?? "")!
        }.map { url in
            SFSafariViewController(url: url)
        }.subscribe { safariVc in
            
            self.present(safariVc, animated: true, completion: nil)
        } onError: { error in
            let vc = UIAlertController(title: "Error", message: "Can't open this news", preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .cancel) { action in
                vc.dismiss(animated: true, completion: nil)
            }
            vc.addAction(action)
            self.present(vc, animated: true, completion: nil)
        }.disposed(by: bag)

    }
    
 

    func setupSideMenu(){
        let vc = MenuTableViewController()
        vc.pickDone = { (url, type) in
           
        }
        vc.type = type
        menu = SideMenuNavigationController(rootViewController: vc)
        let img = UIImage(systemName: "list.dash")?.withRenderingMode(.alwaysTemplate)
        let menuBtn = UIBarButtonItem(image: img, style: .plain, target: self, action: #selector(didTapMenu))
        menuBtn.tintColor = .white
        self.navigationItem.leftBarButtonItem  = menuBtn
        menu?.leftSide = true
        SideMenuManager.default.leftMenuNavigationController = menu
        SideMenuManager.default.addPanGestureToPresent(toView: self.view)
        menu?.animationOptions = .curveEaseInOut
        menu?.presentationStyle = .menuDissolveIn
      
    }
   
    func initUI(){
        self.title = "Trang chủ"
        tableView.reloadData()
     
        tableView.addSubview(refreshControl)
        navigationController?.setNavigationBarHidden(false, animated: true)
        menu?.animationOptions = .curveEaseInOut
        menu?.presentationStyle = .viewSlideOutMenuIn
        self.navigationController?.navigationBar.barTintColor = #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)
    }
    
    @objc func didTapMenu(sender : UIButton){
        present(menu!, animated: true, completion: nil)
    }
}

    
    

