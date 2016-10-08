//
//  CoreDataHelper.swift
//  CoreDataHelper
//
//  Created by Louis BODART on 10/03/2016.
//  Copyright © 2016 Louis Bodart. All rights reserved.
//

import Foundation
import CoreData

// MARK: - CoreDataHelper entity protocol
@objc public protocol CDHelperEntity: NSFetchRequestResult {
    @objc optional static var entityName: String { get }
}

// MARK: - CoreDataHelper entity protocol extension
public extension CDHelperEntity where Self: NSManagedObject {
    
    // MARK: Private static variables
    fileprivate static var mainContext: NSManagedObjectContext! {
        let context: NSManagedObjectContext! = CDHelper.mainContext
        
        assert((context != nil), "CDHelper error: mainContext must be set in the AppDelegate.")
        return context
    }
    
    fileprivate static var entityName: String {
        return "\(Self.self)"
    }
    
    // MARK: Public instance methods
    
    /// Save the entity in the main context.
    public func save() {
        CDHelper._sharedInstance.saveContext()
    }
    
    /// Delete the entity from the main context.
    public func destroy() {
        if let object = self as? NSManagedObject {
            Self.mainContext.delete(object)
            self.save()
        }
    }
    
    // MARK: Public class methods
    
    /// Create a new empty entity.
    ///
    /// - returns:
    ///     A freshly created entity.
    public static func new() -> Self {
        let newEntity: Self = NSEntityDescription.insertNewObject(forEntityName: self.entityName, into: Self.mainContext) as! Self
        return newEntity
    }
    
    /// Create an entity using a data dictionary.
    ///
    /// - parameters:
    ///     - Dictionary: A dictionary of data used to fill your entity
    /// - returns:
    ///     A freshly created entity filled with the data.
    public static func new(_ data: [String: Any?]) -> Self {
        let newEntity: NSManagedObject = self.new()
        let availableKeys = newEntity.entity.attributesByName.keys
        
        for (key, value) in data {
            if !availableKeys.contains(key) {
                continue
            }
            
            newEntity.setValue(value, forKey: key)
        }
        
        return newEntity as! Self
    }
    
    public static func findAll(usingSortDescriptors sortDescriptors: [NSSortDescriptor]! = nil) -> [Self] {
        return self._fetchUsingFetchRequest(self._buildFindAllRequest(usingSortDescriptors: sortDescriptors))
    }
    
    public static func findOne(_ predicate: String) -> Self? {
        return self._fetchUsingFetchRequest(self._buildFindOneRequest(predicate)).first
    }
    
    public static func find(_ predicate: String, usingSortDescriptors sortDescriptors: [NSSortDescriptor]! = nil, limit fetchLimit: Int! = nil) -> [Self] {
        return self._fetchUsingFetchRequest(self._buildFindRequest(predicate, usingSortDescriptors: sortDescriptors, limit: fetchLimit))
    }
    
    public static func asynchronouslyFindAll(usingSortDescriptors sortDescriptors: [NSSortDescriptor]! = nil, completion: ([Self]) -> Void) {
        self._asynchronouslyFetchUsingRequest(self._buildFindAllRequest(usingSortDescriptors: sortDescriptors), completion: completion)
    }
    
    public static func asynchronouslyFindOne(_ predicate: String, completion: (Self?) -> Void) {
        self._asynchronouslyFetchUsingRequest(self._buildFindOneRequest(predicate), completion: completion)
    }
    
    public static func asynchronouslyFind(_ predicate: String, usingSortDescriptors sortDescriptors: [NSSortDescriptor]! = nil, limit fetchLimit: Int! = nil, completion: ([Self]) -> Void) {
        self._asynchronouslyFetchUsingRequest(self._buildFindRequest(predicate, usingSortDescriptors: sortDescriptors, limit: fetchLimit), completion: completion)
    }
    
    // MARK: Private class methods
    fileprivate static func _buildFetchRequestUsingPredicate(_ predicate: String!, sortDescriptors: [NSSortDescriptor]!, fetchLimit: Int!) -> NSFetchRequest<Self> {
        let fetchRequest: NSFetchRequest = NSFetchRequest<Self>()
        let entity: NSEntityDescription! = NSEntityDescription.entity(forEntityName: self.entityName, in: Self.mainContext)
        fetchRequest.entity = entity
        fetchRequest.predicate = (predicate != nil ? NSPredicate(format: predicate) : nil)
        fetchRequest.sortDescriptors = sortDescriptors
        if let fetchLimit = fetchLimit {
            fetchRequest.fetchLimit = fetchLimit
        }
        
        return fetchRequest
    }
    
    fileprivate static func _buildFindAllRequest(usingSortDescriptors sortDescriptors: [NSSortDescriptor]! = nil) -> NSFetchRequest<Self> {
        return self._buildFetchRequestUsingPredicate(nil, sortDescriptors: sortDescriptors, fetchLimit: nil)
    }
    
    fileprivate static func _buildFindOneRequest(_ predicate: String) -> NSFetchRequest<Self> {
        return self._buildFetchRequestUsingPredicate(predicate, sortDescriptors: nil, fetchLimit: nil)
    }
    
    fileprivate static func _buildFindRequest(_ predicate: String, usingSortDescriptors sortDescriptors: [NSSortDescriptor]! = nil, limit fetchLimit: Int! = nil) -> NSFetchRequest<Self> {
        return self._buildFetchRequestUsingPredicate(predicate, sortDescriptors: sortDescriptors, fetchLimit: fetchLimit)
    }
    
    fileprivate static func _fetchUsingFetchRequest(_ fetchRequest: NSFetchRequest<Self>) -> [Self] {
        guard let results = try? Self.mainContext.fetch(fetchRequest) else {
            print("CDHelper error: Cannot fetch results. Empty array has been returned.")
            return []
        }
        
        return results
    }
    
    fileprivate static func _asynchronouslyFetchUsingRequest(_ fetchRequest: NSFetchRequest<Self>, completion: Any) {
        let asyncRequest: NSAsynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (result: NSAsynchronousFetchResult!) -> Void in
            
            let result: [Self] = result.finalResult ?? []
            
            if let completion = completion as? (([Self]) -> Void) {
                completion(result)
            } else if let completion = completion as? ((Self?) -> Void) {
                completion(result.first ?? nil)
            } else {
                fatalError("CDHelper error: completion variable has a wrong type. Must be '([Self]) -> Void' or '(Self?) -> Void'.")
            }
        }
        
        do {
            try Self.mainContext.execute(asyncRequest as NSPersistentStoreRequest)
        } catch {
            print("CDHelper error: Cannot fetch results. Empty array has been returned.")
        }
    }
}

// MARK: - CoreDataHelper main class
public final class CDHelper {
    
    fileprivate static var _sharedInstance: CDHelper = CDHelper()
    
    // MARK: Public class variables
    public class var mainContext: NSManagedObjectContext! { return self._sharedInstance.managedObjectContext }
    
    // MARK: Private instance variables
    fileprivate var _dataSchemeName: String!
    
    // MARK: Public class methods
    public class func initializeWith(dataSchemeName dataSchemeName: String) {
        self._sharedInstance._dataSchemeName = dataSchemeName
    }
    
    fileprivate init() {
        if self._dataSchemeName == nil {
            guard let dataSchemeName = (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String)?.replacingOccurrences(of: " ", with: "_") else {
                fatalError("CDHelper error")
            }
            
            self._dataSchemeName = dataSchemeName
        }
        
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
        return NSManagedObjectModel(contentsOf: modelURL)!
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
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    fileprivate func saveContext() {
        if self.managedObjectContext.hasChanges {
            do {
                try self.managedObjectContext.save()
            } catch let exception {
                print("CDHelper error: Cannot save entity. Reason: \(exception)")
            }
        }
    }
}
