//
//  CoreDataHelperTests.swift
//  CoreDataHelperTests
//
//  Created by Louis BODART on 07/10/2016.
//  Copyright © 2016 Louis Bodart. All rights reserved.
//

import XCTest
import CoreDataHelper
import CoreData

class CoreDataHelperTests: XCTestCase {
    
    var lastNames: [String] = [
        "Bodart",
        "Doe"
    ]
    
    override func setUp() {
        super.setUp()
        
        self.continueAfterFailure = false
        
        let context: NSManagedObjectContext = self.setUpInMemoryManagedObjectContext()
        CDHelper.initialize(withCustomContext: context)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testA1_New() {
        let newUser: User = User.new()
        newUser.id = 1
        newUser.firstName = "Louis"
        newUser.lastName = self.lastNames[0]
        newUser.save()
        
        User.new([
            "id": 2,
            "firstName": "John",
            "lastName": self.lastNames[1]
            ])
            .save()
    }
    
    func testA2_SavedEntities() {
        XCTAssert(User.count.exec() == 2, "Wrong entities number (should be 2)")
    }
    
    func testB1_Find() {
        let entities = User.findAll.exec()
        XCTAssert(entities.count == 2, "Wrong entities number (should be 2, received \(entities.count))")
    }
    
    func testB2_FindOne() {
        let entity = User.findAll.exec()
        XCTAssert(entity != nil, "No entity retrieved")
    }
    
    func testB3_Filter() {
        let entities = User.findAll.where("firstName").isEqual(to: "Louis").exec()
        XCTAssert(entities.count == 1, "Wrong entities number (should be 1)")
        XCTAssert(entities.first!.firstName == "Louis", "Wrong retrieved entity")
    }
    
    func testB4_Sort() {
        let entities = User.findAll.sort(by: "id").exec()
        XCTAssert(entities.count == 2, "Wrong entities number (should be 2)")
        
        for (idx, entity) in entities.enumerated() {
            XCTAssert(entity.lastName! == self.lastNames[idx], "Results are not sorted as expected")
        }
    }
    
    func testB5_ReversedSort() {
        let entities = User.findAll.sort(by: "-id").exec()
        XCTAssert(entities.count == 2, "Wrong entities number (should be 2)")
        let lastNames: [String] = self.lastNames.reversed()
        
        for (idx, entity) in entities.enumerated() {
            XCTAssert(entity.lastName! == lastNames[idx], "Results are not sorted as expected")
        }
    }
    
    func testB6_MultipleSort() {
        self.lastNames.append("Gallagher")
        
        User.new([
            "id": 3,
            "firstName": "John",
            "lastName": self.lastNames[2]
            ])
            .save()
        
        let entities = User.findAll.sort(by: "id", "lastName").exec()
        XCTAssert(entities.count == 3, "Wrong entities number (should be 3)")
        
        for (idx, entity) in entities.enumerated() {
            XCTAssert(entity.lastName! == self.lastNames[idx], "Results are not sorted as expected")
        }
    }
    
    func testB7_MultipleReversedSort() {
        let entities = User.findAll.sort(by: "id", "-lastName").exec()
        XCTAssert(entities.count == 3, "Wrong entities number (should be 3)")
        let lastNames: [String] = self.lastNames.reversed()
        
        for (idx, entity) in entities.enumerated() {
            print(entity.lastName)
            //XCTAssert(entity.lastName! == lastNames[idx], "Results are not sorted as expected")
        }
    }
}

extension CoreDataHelperTests {
    func setUpInMemoryManagedObjectContext() -> NSManagedObjectContext {
        
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle(for: type(of: self))])!
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        
        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        } catch {
            print("Adding in-memory persistent store failed")
        }
        
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        return managedObjectContext
    }
}
