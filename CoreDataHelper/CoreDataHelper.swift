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
public protocol CDHelperEntity: class, NSFetchRequestResult {
    static var entityName: String! { get }
}

// MARK: - CoreDataHelper entity protocol extension
public extension CDHelperEntity {
    
    // MARK: Private static variables
    fileprivate static var mainContext: NSManagedObjectContext! {
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
    
    fileprivate static func _saveContext() {
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
    
    fileprivate static var _sharedInstance: CDHelper = CDHelper()
    
    // MARK: Public class variables
    public class var mainContext: NSManagedObjectContext! { return self._sharedInstance._mainContext }
    
    // MARK: Private instance variables
    fileprivate var _mainContext: NSManagedObjectContext?
    
    // MARK: Public class methods
    public class func initializeWithMainContext(_ mainContext: NSManagedObjectContext) {
        self._sharedInstance._mainContext = mainContext
    }
}
