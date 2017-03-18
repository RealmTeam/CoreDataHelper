//
//  CDHelperPredicate.swift
//  CoreDataHelper
//
//  Created by Louis BODART on 18/03/2017.
//  Copyright © 2017 Louis Bodart. All rights reserved.
//

import Foundation
import CoreData

public class CDHelperPredicate<T: NSFetchRequestResult, R: Any> {
    private let request: CDHelperRequest<T, R>
    private let attribute: String
    private let separator: String
    
    public class func `where`(request: CDHelperRequest<T, R>, attribute: String) -> CDHelperPredicate<T, R> {
        return CDHelperPredicate(request: request, attribute: attribute)
    }
    
    public class func and(request: CDHelperRequest<T, R>, attribute: String) -> CDHelperPredicate<T, R> {
        return CDHelperPredicate(request: request, attribute: attribute, separator: "AND")
    }
    
    public class func or(request: CDHelperRequest<T, R>, attribute: String) -> CDHelperPredicate<T, R> {
        return CDHelperPredicate(request: request, attribute: attribute, separator: "OR")
    }
    
    private init(request: CDHelperRequest<T, R>, attribute: String, separator: String = "") {
        self.request = request
        self.attribute = attribute
        self.separator = separator
    }
    
    private func feedPredicate(with newPredicateString: String) -> CDHelperRequest<T, R> {
        let oldPredicateString: String = self.request.fetchRequest.predicate?.predicateFormat ?? ""
        let newPredicate: NSPredicate = NSPredicate(format: "\(oldPredicateString) \(self.separator) \(newPredicateString)")
        self.request.fetchRequest.predicate = newPredicate
        return self.request
    }
    
    private func buildPredicateString(withSeparator separator: String, value: Any) -> String {
        return "\(self.attribute) \(separator) \(value is String ? "\"\(value)\"" : value)"
    }
    
    public func isEqual(to value: Any) -> CDHelperRequest<T, R> {
        return self.feedPredicate(with: self.buildPredicateString(withSeparator: "=", value: value))
    }
    
    public func isNotEqual(to value: Any) -> CDHelperRequest<T, R> {
        return self.feedPredicate(with: self.buildPredicateString(withSeparator: "!=", value: value))
    }
    
    public func isGreater(than value: Any) -> CDHelperRequest<T, R> {
        return self.feedPredicate(with: self.buildPredicateString(withSeparator: ">", value: value))
    }
    
    public func isGreaterthanOrEqual(to value: Any) -> CDHelperRequest<T, R> {
        return self.feedPredicate(with: self.buildPredicateString(withSeparator: ">=", value: value))
    }
    
    public func isLower(than value: Any) -> CDHelperRequest<T, R> {
        return self.feedPredicate(with: self.buildPredicateString(withSeparator: "<", value: value))
    }
    
    public func isLowerthanOrEqual(to value: Any) -> CDHelperRequest<T, R> {
        return self.feedPredicate(with: self.buildPredicateString(withSeparator: "<=", value: value))
    }
    
    public func begins(with value: String) -> CDHelperRequest<T, R> {
        return self.feedPredicate(with: self.buildPredicateString(withSeparator: "BEGINSWITH", value: value))
    }
    
    public func ends(with value: String) -> CDHelperRequest<T, R> {
        return self.feedPredicate(with: self.buildPredicateString(withSeparator: "ENDSWITH", value: value))
    }
    
    public func contains(_ value: String) -> CDHelperRequest<T, R> {
        return self.feedPredicate(with: self.buildPredicateString(withSeparator: "CONTAINS", value: value))
    }
}
