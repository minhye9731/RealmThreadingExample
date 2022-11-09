//
//  ViewController.swift
//  RealmThreadingExample
//
//  Created by 강민혜 on 11/7/22.
//

import UIKit
import Realm
import RealmSwift

class ViewController: UIViewController {
    
    @IBOutlet weak var mainThreadAdd: UIButton!
    @IBOutlet weak var backgroundThreadAdd: UIButton!
    @IBOutlet weak var backgroundThreadAddWriteAsync: UIButton!
    @IBOutlet weak var passRealmInstance: UIButton!
    @IBOutlet weak var asyncAwaitPractice: UIButton!
    
    @IBOutlet weak var deleteAll: UIButton!
    @IBOutlet weak var printHoi: UIButton!
    
    let localRealm = try! Realm()
    var tasks: Results<Developer>!
    var peopleList: [Developer] = []
    
    // passRealmInstanceTapped 확인 비교용 데이터 생성코드
    let iOSDeveloper = Developer(name: "SeSaciOSProfessional", age: 50)

    override func viewDidLoad() {
        super.viewDidLoad()
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        setButtonFuntion()
        
        // passRealmInstanceTapped 확인 비교용 데이터 생성코드
//        try! localRealm.write {
//            localRealm.add(iOSDeveloper)
//        }
    }
    
    func setButtonFuntion() {
        mainThreadAdd.addTarget(self, action: #selector(mainThreadAddTapped), for: .touchUpInside)
        backgroundThreadAdd.addTarget(self, action: #selector(backgroundThreadAddTapped), for: .touchUpInside)
        backgroundThreadAddWriteAsync.addTarget(self, action: #selector(backgroundThreadAddWriteAsyncTapped), for: .touchUpInside)
        passRealmInstance.addTarget(self, action: #selector(passRealmInstanceTapped), for: .touchUpInside)
        asyncAwaitPractice.addTarget(self, action: #selector(asyncAwaitPracticeTapped), for: .touchUpInside)
        deleteAll.addTarget(self, action: #selector(deleteAllTapped), for: .touchUpInside)
        printHoi.addTarget(self, action: #selector(printHoiTapped), for: .touchUpInside)
    }
    
    @objc func mainThreadAddTapped() {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 5.088394999504089 초
//        for i in 0..<1000 {
//            let people = Developer(name: "SeSAC\(i)", age: i)
//            try! localRealm.write({
//                localRealm.add(people)
//            })
//        }
        
        // 0.04514205455780029초 (배열에 담아서 한 번에 추가하면 시간단축 가능)
        for i in 0..<1000 {
            let developer = Developer(name: "SeSAC\(i)", age: i)
            peopleList.append(developer)
        }
        try! localRealm.write({
            localRealm.add(peopleList)
        })
        
        print("🐥Main Thread Time: \(CFAbsoluteTimeGetCurrent() - startTime)")
    }
    
    @objc func backgroundThreadAddTapped() {
        DispatchQueue.global().async {
            let startTime = CFAbsoluteTimeGetCurrent()
            let otherRealm = try! Realm() // **중요** realm 인스턴스를 추가로 생성해서 접근
            autoreleasepool { // 해당 블록내에서 write 작업을 하면 해당 코드가 메모리 해제 되는 것을 모든 작업을 마쳤을 때로 보장함
                
                // 7.898086071014404초
//                for i in 0..<1000 {
//                    let developer = Developer(name: "SeSAC\(i)", age: i)
//                    try! otherRealm.write({
//                        otherRealm.add(developer)
//                    })
//                }
                
                // 0.04514205455780029초 (배열에 담아서 한 번에 추가하면 시간단축 가능)
                for i in 0..<1000 {
                    let developer = Developer(name: "SeSAC\(i)", age: i)
                    self.peopleList.append(developer)
                }
                try! otherRealm.write({
                    otherRealm.add(self.peopleList)
                })
                
            }
            print("🦄Background Thread Time: \(CFAbsoluteTimeGetCurrent() - startTime)")
        }
    }
    
    @objc func backgroundThreadAddWriteAsyncTapped() {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<1000 {
            let developer = Developer(name: "SeSAC\(i)", age: i)
            self.peopleList.append(developer)
        }
        
        // 0.16823697090148926 초
        localRealm.writeAsync {
            self.localRealm.add(self.peopleList)
        }
        
        print("⭐️Background Thread // WriteAsync // Time: \(CFAbsoluteTimeGetCurrent() - startTime)")
    }
        
    @objc func passRealmInstanceTapped() {// 0.0065839290618896484초 소요
        let startTime = CFAbsoluteTimeGetCurrent()

        // iOSDeveloper의 thread-safe한 reference 생성
        @ThreadSafe var iOSDeveloperRef = iOSDeveloper

        // background thread로 참조 전달
        DispatchQueue(label: "background").async {
            autoreleasepool {
                let otherRealm = try! Realm()
                try! otherRealm.write {
                    guard let person = iOSDeveloperRef else { return }
                    person.age = 20
                }
            }
        }
        print("⭐️@ThreadSafe로 thread간 realm instance 전달 Time: \(CFAbsoluteTimeGetCurrent() - startTime)")
    }
    
    // 공식문서 보고 시키는데로 async/await 했고, 데이터 수정된다.
    // 근데 에러남..memory read failed, thread bad access
    @objc func asyncAwaitPracticeTapped() async {
        await createAndUpdatePerson()
    }
    
    func someLongCallToGetNewName() async -> String {
        return "Lilac"
    }
    
    @MainActor func loadNameInBackground(@ThreadSafe person: Developer?) async {
        let newName = await someLongCallToGetNewName()
        let otherRealm = try! await Realm()
        try! otherRealm.write({
            person?.name = newName
        })
    }
    
    @MainActor func createAndUpdatePerson() async {
        let otherRealm = try! await Realm()
        
        let iOSDeveloper = Developer(name: "Rose", age: 30)
        try! otherRealm.write({
            otherRealm.add(iOSDeveloper)
        })
        await loadNameInBackground(person: iOSDeveloper)
    }
}

extension ViewController {
    
    @objc func deleteAllTapped() {
        try! localRealm.write({
            localRealm.deleteAll()
        })
    }
    
    @objc func printHoiTapped() {
        print("Hey!🕺")
    }
}

