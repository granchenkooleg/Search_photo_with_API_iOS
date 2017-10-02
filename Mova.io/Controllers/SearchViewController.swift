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


class SearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    var gettyImageObj: Results<GettyImage>!
    
    var tableView: UITableView!
    var searchTextField: TextField!
    var hud : MBProgressHUD = MBProgressHUD()
    
    
    var imageContainer = [GettyImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageContainer = GettyImage().allGettyImage()
        
        // Call the path RealmDB
        GettyImage.setConfig()
        
        // Resize dynamic cell
        tableView = UITableView(frame: view.frame)
        tableView.delegate = self
        tableView.dataSource = self
        self.tableView.register(UITableViewCell.classForKeyedArchiver(), forCellReuseIdentifier: "SearchTableViewCell")
        view.addSubview(tableView)
        guard let navigation = (UIApplication.shared.delegate as! AppDelegate).window?.rootViewController as? UINavigationController else { return }
        navigation.navigationBar.barTintColor = UIColor.gray
        searchTextField = TextField(frame: CGRect(x: 10, y: 0, width: navigation.navigationBar.frame.width - 20, height: navigation.navigationBar.frame.height - 10))
        searchTextField.delegate = self
        searchTextField.backgroundColor = UIColor.white
        searchTextField.placeholder = "     Search here..."
        navigation.navigationBar.addSubview(searchTextField)
        tableView.estimatedRowHeight = 100.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView?.separatorStyle = .singleLine
        tableView.layoutIfNeeded()
        tableView.reloadData()
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // for delete rows
        let realm = try! Realm()
        gettyImageObj = realm.objects(GettyImage.self)
        
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if let text = textField.text {
            if text.isEmpty {
                imageContainer = GettyImage().allGettyImage()
            } else {
                hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                hud.mode = .indeterminate
                hud.label.text = "Loading"
                guard let text = text.removingPercentEncoding else { return false }
                // Set up the URL request
                let todoEndpoint: String = "https://api.gettyimages.com/v3/search/images?fields=id,title,thumb&sort_order=best&phrase=\(text)"
                
                guard let url = URL(string: todoEndpoint) else {
                    print("Error: cannot create URL")
                    return false
                }
                
                let urlRequest = URLRequest(url: url)
                
                // Set up the session
                let config = URLSessionConfiguration.default
                config.httpAdditionalHeaders = [
                    "Accept": "application/json",
                    "Api-Key": "pesprtpumxqpqzsv6q37kn8s"
                ]
                
                let session = URLSession(configuration: config)
                
                //Make the request
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
                    guard let _ = todo["images"].arrayValue.first.flatMap({ GettyImage.setupGettyImage(json: $0) }) else {
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
                        guard let `self` = self else { return }
                        self.imageContainer = GettyImage().allGettyImage()
                        self.tableView.layoutIfNeeded()
                        self.tableView.reloadData()
                        self.view.endEditing(true)
                        self.searchTextField.text = ""
                        MBProgressHUD.hide(for: (self.view), animated: true)
                    }
                }
                
                task.resume()
            }
        }
        
        return true
    }
    
    // MARK: - Table view data source
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imageContainer.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "SearchTableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        let imageDetails = self.imageContainer[indexPath.row]
        
        
        if let pathImage = imageDetails.display_sizes.first?.uri {
            cell.imageView?.sd_setImage(with: URL(string: (pathImage)), placeholderImage: UIImage(named: "placeholder.png"))
        }
        cell.textLabel?.text = imageDetails.title
        
        return cell
    }
    
    // Delete rows [start
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Удалить"
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            try! self.gettyImageObj.realm!.write {
                
                let imageObj = self.gettyImageObj[indexPath.row]
                self.imageContainer.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                self.gettyImageObj.realm!.delete(imageObj)
            }
            
            self.tableView.reloadData()
        }
    }
    //end]
    
}
