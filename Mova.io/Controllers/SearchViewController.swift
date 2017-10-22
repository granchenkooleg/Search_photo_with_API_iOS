//
//  SearchTableViewController.swift
//  Mova.io
//
//  Created by Oleg on 10/1/17.
//  Copyright © 2017 Oleg. All rights reserved.
//

import UIKit
import SDWebImage
import SwiftyJSON
import RealmSwift
import MBProgressHUD


class SearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    var imageContainer = [GettyImage]()
    
    var gettyImageObj: Results<GettyImage> = {
        let realm = try! Realm()
        return realm.objects(GettyImage.self)}()
    
    var gettyImageDisplay_sizes: Results<Display_sizes> = {
        let realm = try! Realm()
        return realm.objects(Display_sizes.self)}()
    
    var tableView: UITableView!
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var hud : MBProgressHUD = MBProgressHUD()
    
    var token: NotificationToken?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Call the path RealmDB
        GettyImage.setConfig()
        
        // Create tableViewFrame
        self.tableView = UITableView(frame: (self.view.frame))
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.tableView.register(UITableViewCell.classForKeyedArchiver(), forCellReuseIdentifier: "SearchTableViewCell")
        self.view.addSubview(tableView)
        
        guard let navigation = (UIApplication.shared.delegate as! AppDelegate).window?.rootViewController as? UINavigationController else { return }
        navigation.navigationBar.barTintColor = UIColor.gray
        
        // Setup the Search Controller
        self.searchController.searchBar.delegate = self
        self.searchController.searchBar.showsBookmarkButton = true
        self.searchController.dimsBackgroundDuringPresentation = false
        self.definesPresentationContext = true
        tableView.tableHeaderView = self.searchController.searchBar
        
        
        // Resize dynamic cell
        tableView.estimatedRowHeight = 100.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.separatorStyle = .singleLine
        
        // MARK: -Notifications
        token = gettyImageObj.addNotificationBlock {[weak self] (changes: RealmCollectionChange) in
            guard let tableView = self?.tableView else { return }
            
            switch changes {
            case .initial:
                tableView.reloadData()
                break
            case .update(let results, let deletions, let insertions, let modifications):
                
                tableView.beginUpdates()
                
                //re-order repos when new pushes happen
                tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) },
                                     with: .automatic)
                tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) },
                                     with: .automatic)
                
                //flash cells when repo gets new call
                for row in modifications {
                    let indexPath = IndexPath(row: row, section: 0)
                    let repo = results[indexPath.row]
                    if let cell = tableView.cellForRow(at: indexPath) {
                        cell.textLabel?.text = repo.title
                        if let imageURL = URL(string: (repo.display_sizes.first?.uri)!) {
                            DispatchQueue.global().async {
                                let data = try? Data(contentsOf: imageURL)
                                if let data = data {
                                    let image = UIImage(data: data)
                                    DispatchQueue.main.async {
                                        cell.imageView?.image = image?.circleMask
                                        // For appear the image without touch
                                        cell.layoutSubviews()
                                    }
                                }
                            }
                        }
                    }
                        
                    else {
                        print("cell not found for \(indexPath)")
                    }
                }
                
                tableView.endUpdates()
                break
            case .error(let error):
                print(error)
                break
            }
        }
    }
    
    
    //MARK: UISearchBarDelegateMethod
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)  {
        if let text = searchBar.text {
            if text.isEmpty {
//                imageContainer = GettyImage().allGettyImage()
            } else {
                hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                hud.mode = .indeterminate
                hud.label.text = "Loading"
                // Returns a new string made from the String by replacing all percent encoded sequences with the matching UTF-8 characters.
                guard let text = text.removingPercentEncoding else { return  }
                // Set up the URL request
                let todoEndpoint: String = "https://api.gettyimages.com/v3/search/images?fields=id,title,thumb&sort_order=best&phrase=\(text)"
                
                guard let url = URL(string: todoEndpoint) else {
                    print("Error: cannot create URL")
                    return
                }
                
                let urlRequest = URLRequest(url: url)
                
                // Set up the session
                let config = URLSessionConfiguration.default
                config.httpAdditionalHeaders = [
                    "Accept": "application/json",
                    "Api-Key": "pesprtpumxqpqzsv6q37kn8s"
                ]
                
                let session = URLSession(configuration: config)
                
                // Make the request
                let task = session.dataTask(with: urlRequest) { [weak self]
                    (data, response, error) in
                    // Check for any errors
                    guard error == nil else {
                        print("error calling GET on phrase: \(text)")
                        print(error as Any)
                        return
                    }
                    // Make sure we got data
                    guard let responseData = data else {
                        print("Error: did not receive data")
                        return
                    }
                    // Parse the result as JSON, since that's what the API provide
                    let todo = JSON(responseData)
                    // Set data in DB Realm
                    guard let _ = todo["images"].arrayValue.first.flatMap({ GettyImage.setupGettyImage(json: $0)
                    }) else {
                        // Warning if there is no photo
                        DispatchQueue.main.async {
                            let alert = UIAlertController(title: "Такой фотографии нет", message: "Попробуйте другое название", preferredStyle: UIAlertControllerStyle.alert)
                            alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
                            self?.present(alert, animated: true, completion: nil)
                            MBProgressHUD.hide(for: (self?.view)!, animated: true)
                        }
                        return
                    }
                    
                    DispatchQueue.main.async {
                        MBProgressHUD.hide(for: (self?.view)!, animated: true)
                    }
                }
                
                task.resume()
            }
        }
        return
    }
    
    
    // MARK: - Table view data source
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gettyImageObj.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchTableViewCell", for: indexPath)
        let imageDetails: GettyImage
        imageDetails = gettyImageObj[indexPath.row]
        
        /*
         // May do so
         if let pathImage = imageDetails.display_sizes.first?.uri {
         cell.imageView?.sd_setImage(with: URL(string: pathImage), placeholderImage: UIImage(named: "placeholder.png"))
         }
         */
        
        if let imageURL = URL(string: (imageDetails.display_sizes.first?.uri)!) {
            DispatchQueue.global().async {
                let data = try? Data(contentsOf: imageURL)
                if let data = data {
                    let image = UIImage(data: data)
                    DispatchQueue.main.async {
                        cell.imageView?.image = image/*.circleMask*/
                        // For appear the image without touch(resumption of arhitecture subviews)
                        cell.layoutSubviews()
                    }
                }
            }
        }
        cell.textLabel!.text = imageDetails.title
        return cell
    }
    
    // MARK: -Delete rows [start
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Удалить"
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            
            let imageObj_1 = self.gettyImageObj[indexPath.row]
            let imageObj_2 = self.gettyImageDisplay_sizes[indexPath.row]
            
            try! self.gettyImageObj.realm!.write ({
                //                self.imageContainer.remove(at: indexPath.row)
                self.gettyImageObj.realm!.delete(imageObj_1)
                self.gettyImageDisplay_sizes.realm?.delete(imageObj_2)
            })
        }
    }
    //end]
}




