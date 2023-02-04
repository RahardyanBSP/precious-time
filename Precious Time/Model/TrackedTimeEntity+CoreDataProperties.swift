// 
//  TrackedTimeEntity+CoreDataProperties.swift
//  
//
//  Created by Rahardyan Bisma on 31/01/23.
//  
//

import Foundation
import CoreData


extension TrackedTimeEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TrackedTimeEntity> {
        return NSFetchRequest<TrackedTimeEntity>(entityName: "TrackedTimeEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var trackingDescription: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?

}
