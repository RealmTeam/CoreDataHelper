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
public protocol CDHelperEntity: class {
    static var entityName: String! { get }
}

// MARK: - CoreDataHelper entity protocol extension
public extension CDHelperEntity {
    
    // MARK: Private static variables
    private static var mainContext: NSManagedObjectContext! {
        let context: NSManagedObjectContext! = CDHelper.mainContext
        
        assert((context != nil), "CDHelper error: mainContext must be set in the AppDelegate.")
        return context
    }
    
    // MARK: Public instance methods
    
    /// Save the entity in the main context.
    public func save() {
        Self._saveContext()
    }
    
    /// Delete the entity from the main context.
    public func destroy() {
        if let object = self as? NSManagedObject {
            Self.mainContext.deleteObject(object)
            self.save()
        }
    }
    
    // MARK: Public class methods
    
    /// Create a new empty entity.
    ///
    /// - returns:
    ///     A freshly created entity.
    public static func new() -> Self {
        let newEntity: Self = NSEntityDescription.insertNewObjectForEntityForName(self.entityName, inManagedObjectContext: Self.mainContext) as! Self
        return newEntity
    }
    
    /// Create an entity using a data dictionary.
    ///
    /// - parameters:
    ///     - Dictionary: A dictionary of data used to fill your entity
    /// - returns:
    ///     A freshly created entity filled with the data.
    public static func new(data: [String: AnyObject?]) -> Self {
        let newEntity: NSManagedObject = self.new() as! NSManagedObject
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
    
    public static func findOne(predicate: String) -> Self? {
        return self._fetchUsingFetchRequest(self._buildFindOneRequest(predicate)).first
    }
    
    public static func find(predicate: String, usingSortDescriptors sortDescriptors: [NSSortDescriptor]! = nil, limit fetchLimit: Int! = nil) -> [Self] {
        return self._fetchUsingFetchRequest(self._buildFindRequest(predicate, usingSortDescriptors: sortDescriptors, limit: fetchLimit))
    }
    
    public static func asynchronouslyFindAll(usingSortDescriptors sortDescriptors: [NSSortDescriptor]! = nil, completion: ([Self]) -> Void) {
        self._asynchronouslyFetchUsingRequest(self._buildFindAllRequest(usingSortDescriptors: sortDescriptors), completion: completion)
    }
    
    public static func asynchronouslyFindOne(predicate: String, completion: (Self?) -> Void) {
        self._asynchronouslyFetchUsingRequest(self._buildFindOneRequest(predicate), completion: completion)
    }
    
    public static func asynchronouslyFind(predicate: String, usingSortDescriptors sortDescriptors: [NSSortDescriptor]! = nil, limit fetchLimit: Int! = nil, completion: ([Self]) -> Void) {
        self._asynchronouslyFetchUsingRequest(self._buildFindRequest(predicate, usingSortDescriptors: sortDescriptors, limit: fetchLimit), completion: completion)
    }
    
    // MARK: Private class methods
    private static func _buildFetchRequestUsingPredicate(predicate: String!, sortDescriptors: [NSSortDescriptor]!, fetchLimit: Int!) -> NSFetchRequest {
        let fetchRequest: NSFetchRequest = NSFetchRequest()
        let entity: NSEntityDescription! = NSEntityDescription.entityForName(self.entityName, inManagedObjectContext: Self.mainContext)
        fetchRequest.entity = entity
        fetchRequest.predicate = (predicate != nil ? NSPredicate(format: predicate) : nil)
        fetchRequest.sortDescriptors = sortDescriptors
        if let fetchLimit = fetchLimit {
            fetchRequest.fetchLimit = fetchLimit
        }
        
        return fetchRequest
    }
    
    private static func _buildFindAllRequest(usingSortDescriptors sortDescriptors: [NSSortDescriptor]! = nil) -> NSFetchRequest {
        return self._buildFetchRequestUsingPredicate(nil, sortDescriptors: sortDescriptors, fetchLimit: nil)
    }
    
    private static func _buildFindOneRequest(predicate: String) -> NSFetchRequest {
        return self._buildFetchRequestUsingPredicate(predicate, sortDescriptors: nil, fetchLimit: nil)
    }
    
    private static func _buildFindRequest(predicate: String, usingSortDescriptors sortDescriptors: [NSSortDescriptor]! = nil, limit fetchLimit: Int! = nil) -> NSFetchRequest {
        return self._buildFetchRequestUsingPredicate(predicate, sortDescriptors: sortDescriptors, fetchLimit: fetchLimit)
    }
    
    private static func _fetchUsingFetchRequest(fetchRequest: NSFetchRequest) -> [Self] {
        guard let results = try? Self.mainContext.executeFetchRequest(fetchRequest) as? [Self], let resultsArray = results.map({$0}) else {
            print("CDHelper error: Cannot fetch results. Empty array has been returned.")
            return []
        }
        
        return resultsArray
    }
    
    private static func _asynchronouslyFetchUsingRequest(fetchRequest: NSFetchRequest, completion: Any) {
        let asyncRequest: NSAsynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (result: NSAsynchronousFetchResult!) -> Void in
            let result: [Self]? = (result.finalResult as? [Self])?.map({$0})
            
            if let completion = completion as? (([Self]) -> Void) {
                completion(result != nil ? result! : [])
            } else if let completion = completion as? ((Self?) -> Void) {
                completion(result?.first)
            } else {
                fatalError("CDHelper error: completion variable has a wrong type. Must be '([Self]) -> Void' or '(Self?) -> Void'.")
            }
        }
        
        do {
            try Self.mainContext.executeRequest(asyncRequest)
        } catch {
            print("CDHelper error: Cannot fetch results. Empty array has been returned.")
        }
    }
    
    private static func _saveContext() {
        if self.mainContext.hasChanges {
            do {
                try self.mainContext.save()
            } catch let exception {
                print("CDHelper error: Cannot save entity. Reason: \(exception)")
            }
        }
    }
}

// MARK: - CoreDataHelper main class
public final class CDHelper {
    
    // MARK: Private class variables
    private class var _sharedInstance: CDHelper {
        
        struct Static {
            static var instance: CDHelper?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = CDHelper()
        }
        
        return Static.instance!
    }
    
    // MARK: Public class variables
    public class var mainContext: NSManagedObjectContext! { return self._sharedInstance._mainContext }
    
    // MARK: Private instance variables
    private var _mainContext: NSManagedObjectContext?
    
    // MARK: Public class methods
    public class func initializeWithMainContext(mainContext: NSManagedObjectContext) {
        self._sharedInstance._mainContext = mainContext
    }
}