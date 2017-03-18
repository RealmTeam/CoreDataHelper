//
//  CDHelperEntity.swift
//  CoreDataHelper
//
//  Created by Louis BODART on 18/03/2017.
//  Copyright © 2017 Louis Bodart. All rights reserved.
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
    
    static var entityName: String {
        return "\(Self.self)"
    }
    
    static var request: CDHelperRequest<Self, [Self]> {
        return CDHelperRequest<Self, [Self]>()
    }
    
    static var findOne: CDHelperRequest<Self, Self> {
        let req = CDHelperRequest<Self, Self>()
        req.limit = 1
        return req
    }
    
    static var findAll: CDHelperRequest<Self, [Self]> {
        return CDHelperRequest<Self, [Self]>()
    }
    
    static var findAsDictionary: CDHelperRequest<Self, [[String: Any]]> {
        let req = CDHelperRequest<Self, [[String: Any]]>()
        req.resultType = .dictionaryResultType
        return req
    }
    
    static var count: CDHelperRequest<Self, Int> {
        let req = CDHelperRequest<Self, Int>()
        req.resultType = .countResultType
        return req
    }
    
    // MARK: Public instance methods
    
    /// Save the entity in the main context.
    public func save() {
        CDHelper._sharedInstance.saveContext()
    }
    
    /// Delete the entity from the main context.
    public func destroy() {
        CDHelper.currentContext.delete(self)
        self.save()
    }
    
    // MARK: Public class methods
    
    /// Create a new empty entity.
    ///
    /// - returns:
    ///     A freshly created entity.
    public static func new() -> Self {
        let newEntity: Self = NSEntityDescription.insertNewObject(forEntityName: self.entityName, into: CDHelper.currentContext) as! Self
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
}
