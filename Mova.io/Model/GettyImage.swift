//
//  GettyImages.swift
//  Mova.io
//
//  Created by Oleg on 10/1/17.
//  Copyright © 2017 Oleg. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftyJSON

extension Results {
    func array<T>(ofType: T.Type) -> [T] {
        return flatMap { $0 as? T }
    }
}

class GettyImage : Object {
    
    dynamic var id = ""
    dynamic var title = ""
    var display_sizes = List<Display_sizes>()
    
    @discardableResult static func setupGettyImage(json: JSON) -> GettyImage {
        var gettyImage = GettyImage()
        let realm = try! Realm()
        
        try! realm.write {
            gettyImage = realm.create(GettyImage.self, value: json.object, update: true)
        }
        
        return gettyImage
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    // Path to Realm
    static func setConfig() {
        let realm = try! Realm()
        if let url = realm.configuration.fileURL {
            print("FileURL of DataBase - \(url)")
        }
    }
    
    func allGettyImage() -> [GettyImage] {
        let realm = try! Realm()
        let list =  realm.objects(GettyImage.self)
        return Array(list)
    }
    
    static func delAllGettyImage() {
        let realm = try! Realm()
        let allGettyImage = realm.objects(GettyImage.self)
        try! realm.write {
            realm.delete(allGettyImage)
        }
    }
}

class Display_sizes : Object {
    dynamic var uri = ""
    
    override static func primaryKey() -> String? {
        return "uri"
    }
}


