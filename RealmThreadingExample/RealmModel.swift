//
//  RealmModel.swift
//  RealmThreadingExample
//
//  Created by 강민혜 on 11/9/22.
//

import UIKit
import RealmSwift

class Developer: Object {
    @Persisted var name: String
    @Persisted var age: Int
    @Persisted var cats: List<Cat>
    @Persisted(primaryKey: true) var objectId: ObjectId

    convenience init(name: String, age: Int) {
        self.init()
        self.name = name
        self.age = age
    }
}

class Cat: Object {
    @Persisted var name: String
    @Persisted var age: Int
    @Persisted(primaryKey: true) var objectId: ObjectId

    convenience init(name: String, age: Int) {
        self.init()
        self.name = name
        self.age = age
    }
}
