//
//  CDHelperRequest.swift
//  Pods
//
//  Created by Louis BODART on 08/10/2016.
//
//

import Foundation
import CoreData

public class CDHelperRequest<T: NSFetchRequestResult, R: Any> {
    internal let fetchRequest: NSFetchRequest<NSFetchRequestResult>
    
    internal var limit: Int {
        get { return self.fetchRequest.fetchLimit }
        set { self.fetchRequest.fetchLimit = newValue }
    }
    
    internal var resultType: NSFetchRequestResultType {
        get { return self.fetchRequest.resultType }
        set { self.fetchRequest.resultType = newValue }
    }
    
    init(withEntityName entityName: String) {
        self.fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
    }
    
    convenience init() {
        self.init(withEntityName: "\(T.self)")
    }
    
    public func add(predicate: String) -> Self {
        self.fetchRequest.predicate = NSPredicate(format: predicate)
        return self
    }
    
    public func sort(usingSortDescriptor descriptor: NSSortDescriptor) -> Self {
        var sortDescriptors = self.fetchRequest.sortDescriptors ?? []
        sortDescriptors.append(descriptor)
        self.fetchRequest.sortDescriptors = sortDescriptors
        return self
    }
    
    public func sort(by descriptors: String...) -> Self {
        for descriptor in descriptors {
            if descriptor.isEmpty {
                continue
            }
            
            let ascending: Bool = descriptor.characters.first! != "-"
            let formattedDescriptor: String = descriptor.substring(from: descriptor.index(descriptor.startIndex, offsetBy: ascending ? 0 : 1))
            self.sort(usingSortDescriptor: NSSortDescriptor(key: formattedDescriptor, ascending: ascending))
        }
        
        return self
    }
    
    public func `where`(_ attribute: String) -> CDHelperPredicate<T, R> {
        return CDHelperPredicate.where(request: self, attribute: attribute)
    }
    
    public func and(_ attribute: String) -> CDHelperPredicate<T, R> {
        return CDHelperPredicate.and(request: self, attribute: attribute)
    }
    
    public func or(_ attribute: String) -> CDHelperPredicate<T, R> {
        return CDHelperPredicate.or(request: self, attribute: attribute)
    }
    
    fileprivate final func executeSync() -> [NSFetchRequestResult] {
        guard let results = try? CDHelper.currentContext.execute(self.fetchRequest) else {
            print("CDHelper error: Cannot fetch results. Empty array has been returned.")
            return []
        }
        
        return (results as? NSAsynchronousFetchResult<NSFetchRequestResult>)?.finalResult ?? []
    }
    
    fileprivate final func executeAsync(withCompetion completion: Any) {
        let asyncRequest: NSAsynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: self.fetchRequest) { (result: NSAsynchronousFetchResult!) -> Void in
            
            if let completion = completion as? (([T]) -> Void) {
                completion((result.finalResult ?? []) as? [T] ?? [])
            } else if let completion = completion as? ((T?) -> Void) {
                completion(((result.finalResult ?? []) as? [T] ?? []).first)
            } else if let completion = completion as? ((Int) -> Void) {
                print(result)
                completion(1)
            } else {
                fatalError("CDHelper error: completion variable has a wrong type. Must be '([\(T.self)]) -> Void' or '(\(T.self)?) -> Void'.")
            }
        }
        
        do {
            try CDHelper.currentContext.execute(asyncRequest as NSPersistentStoreRequest)
        } catch {
            print("CDHelper error: Cannot fetch results. Empty array has been returned.")
        }
    }
}

// Functions only available for findAsDictionary
extension CDHelperRequest where R: Collection, R.Iterator.Element: Collection {
    public func group(by attribute: String) -> Self {
        guard let entityName = self.fetchRequest.entityName else {
            return self
        }
        
        let entity: NSEntityDescription? = NSEntityDescription.entity(forEntityName: entityName, in: CDHelper.currentContext)
        guard let desc = entity?.attributesByName[attribute] ?? entity?.relationshipsByName[attribute] else {
            print("error group by")
            return self
        }
        
        self.fetchRequest.propertiesToFetch = (self.fetchRequest.propertiesToFetch ?? []) + [desc]
        self.fetchRequest.propertiesToGroupBy = (self.fetchRequest.propertiesToGroupBy ?? []) + [desc]
        return self
    }
    
    public func include(_ alias: String, function: String, args: String...) -> Self {
        let desc = NSExpressionDescription()
        desc.name = alias
        desc.expression = NSExpression(forFunction: "\(function):", arguments: args.map({ NSExpression(forKeyPath: $0) }))
        desc.expressionResultType = .floatAttributeType
        self.fetchRequest.propertiesToFetch = (self.fetchRequest.propertiesToFetch ?? []) + [desc]
        return self
    }
    
    public func include(_ attribute: String) -> Self {
        guard let entityName = self.fetchRequest.entityName else {
            return self
        }
        
        let entity: NSEntityDescription? = NSEntityDescription.entity(forEntityName: entityName, in: CDHelper.currentContext)
        guard let desc = entity?.attributesByName[attribute] ?? entity?.relationshipsByName[attribute] else {
            print("error include")
            return self
        }
        
        self.fetchRequest.propertiesToFetch = (self.fetchRequest.propertiesToFetch ?? []) + [desc]
        return self
    }
}

extension CDHelperRequest where R: Collection, R.Iterator.Element == T {
    public func limit(_ limit: Int) -> Self {
        self.fetchRequest.fetchLimit = limit
        return self
    }
}

extension CDHelperRequest where R: Collection/*, R.Iterator.Element: Collection*/ {
    public func exec() -> R {
        return self.executeSync() as! R
    }
}

extension CDHelperRequest where R: CDHelperEntity {
    public func exec() -> R? {
        return (self.executeSync() as? [R] ?? []).first
    }
}

extension CDHelperRequest where R: SignedInteger {
    public func exec() -> R {
        return (self.executeSync() as Any as? [R])?.first ?? 0
    }
}
