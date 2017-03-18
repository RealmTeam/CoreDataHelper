//
//  CoreDataHelper.swift
//  CoreDataHelper
//
//  Created by Louis BODART on 10/03/2016.
//  Copyright © 2016 Louis Bodart. All rights reserved.
//

import Foundation
import CoreData

// MARK: - CoreDataHelper main class
public final class CDHelper {
    internal static var _sharedInstance: CDHelper = {
        return CDHelper(dataSchemeName: nil)
    }()
    
    // MARK: Public class variables
    public class var mainContext: NSManagedObjectContext {
        return self._sharedInstance.managedObjectContext
    }
    
    public class var currentContext: NSManagedObjectContext {
        get {
            return CDHelper.mainContext
        }
    }
    
    // MARK: Private instance variables
    fileprivate var _dataSchemeName: String!
    
    private var _customContext: NSManagedObjectContext?
    
    // MARK: Public class methods
    public class func initialize(withCustomContext context: NSManagedObjectContext) {
        self._sharedInstance._customContext = context
    }
    
    fileprivate init(dataSchemeName: String?) {
        self._dataSchemeName = dataSchemeName ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String)?.replacingOccurrences(of: " ", with: "_")
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationWillTerminate(notification:)), name: Notification.Name.UIApplicationWillTerminate, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIApplicationWillTerminate, object: nil)
    }
    
    @objc func applicationWillTerminate(notification: Notification) {
        self.saveContext()
    }
    
    // MARK: Public instance variables
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count - 1] as NSURL
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        assert((self._dataSchemeName != nil), "CDHelper error: CDHelper must be initialized in the AppDelegate.")
        let modelURL = Bundle.main.url(forResource: self._dataSchemeName, withExtension: "momd")!
        let mom: NSManagedObjectModel = NSManagedObjectModel(contentsOf: modelURL)!
        
        let mergedModel: NSManagedObjectModel = NSManagedObjectModel(byMerging: [mom])!
        return mergedModel
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        if let context = self._customContext {
            return context
        }
        
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    internal func saveContext() {
        let context: NSManagedObjectContext = CDHelper.currentContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch let exception {
                print("CDHelper error: Cannot save entity. Reason: \(exception)")
            }
        }
    }
}

