//
//  User+CoreDataProperties.swift
//  CoreDataHelper
//
//  Created by Louis BODART on 29/11/2016.
//  Copyright © 2016 Louis Bodart. All rights reserved.
//

import Foundation
import CoreData

extension User {
    @NSManaged public var id: Int16
    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
}
