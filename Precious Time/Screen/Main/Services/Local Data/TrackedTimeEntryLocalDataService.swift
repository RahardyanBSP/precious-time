// 
//  TrackedTimeEntryLocalDataService.swift
//  Precious Time
//
//  Created by Rahardyan Bisma on 31/01/23.
//  

import Foundation
import RxSwift

protocol TrackedTimeEntryLocalDataServiceType {
    
    /// Add tracked time to local data
    /// - Parameter trackedTime: TrackedTime object
    func addTrackedTimeEntry(trackedTime: TrackedTime)
    
    /// delete tracked time from local data
    /// - Parameter id: TrackedTime object id
    func deleteTrackedTimeEntry(id: String?)
    
    /// get all tracked time entries from local data
    /// - Returns: array of TrackedTime
    func getTrackedTimeEntries() -> Observable<[TrackedTime]>
}

final class TrackedTimeEntryLocalDataService: TrackedTimeEntryLocalDataServiceType {
    
    func addTrackedTimeEntry(trackedTime: TrackedTime) {
        DispatchQueue.global().async {
            let trackedTimeEntity = TrackedTimeEntity(context: CoreDataManager.shared.privateContext)
            trackedTimeEntity.id = trackedTime.id
            trackedTimeEntity.startDate = trackedTime.startDate
            trackedTimeEntity.endDate = trackedTime.endDate
            trackedTimeEntity.trackingDescription = trackedTime.description
        }
        
    }
    
    func deleteTrackedTimeEntry(id: String?) {
        DispatchQueue.global().async {
            guard let id = id else {
                return
            }
            
            let request = TrackedTimeEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "id = %@", id
            )
            
            let entity = try? CoreDataManager.shared.privateContext.fetch(request).first
            
            if let objectToBeDeleted = entity {
                CoreDataManager.shared.privateContext.delete(objectToBeDeleted)
            }
        }
    }
    
    func getTrackedTimeEntries() -> Observable<[TrackedTime]> {
        return Observable.create { observer in
            let request = TrackedTimeEntity.fetchRequest()
            
            let entityResults = try? CoreDataManager.shared.privateContext.fetch(request)
            
            let trackedTimes = (entityResults ?? []).map({ TrackedTime(id: $0.id, description: $0.trackingDescription, startDate: $0.startDate, endDate: $0.endDate) })
            
            observer.onNext(trackedTimes)
            
            return Disposables.create()
        }
        
    }
    
}
