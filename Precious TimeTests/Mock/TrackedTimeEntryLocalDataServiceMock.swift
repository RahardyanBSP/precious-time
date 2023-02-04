// 
//  TrackedTimeEntryLocalDataServiceMock.swift
//  Precious TimeTests
//
//  Created by Rahardyan Bisma on 03/02/23.
//  

import Foundation
import RxSwift
@testable import Precious_Time

final class TrackedTimeEntryLocalDataServiceMock: TrackedTimeEntryLocalDataServiceType {
    
    var isAddTrackedTimeEntryCalled = false
    var isDeleteTrackedTimeEntryCalled = false
    var isGetTrackedTimeEntriesCalled = false
    var inputDeletedTrackedTimeEntryId = ""
    var inputAddTrackedTimeEntry: TrackedTime? = nil
    var resultGetTrackedTimeEntries: Observable<[TrackedTime]> = .empty()
    
    /// Add tracked time to local data
    /// - Parameter trackedTime: TrackedTime object
    func addTrackedTimeEntry(trackedTime: TrackedTime) {
        inputAddTrackedTimeEntry = trackedTime
        isAddTrackedTimeEntryCalled = true
    }
    
    /// delete tracked time from local data
    /// - Parameter id: TrackedTime object id
    func deleteTrackedTimeEntry(id: String?) {
        inputDeletedTrackedTimeEntryId = id ?? ""
        isDeleteTrackedTimeEntryCalled = true
    }
    
    /// get all tracked time entries from local data
    /// - Returns: array of TrackedTime
    func getTrackedTimeEntries() -> Observable<[TrackedTime]> {
        return resultGetTrackedTimeEntries
    }
    
    func reset() {
        isAddTrackedTimeEntryCalled = false
        isDeleteTrackedTimeEntryCalled = false
        isGetTrackedTimeEntriesCalled = false
        resultGetTrackedTimeEntries = .empty()
        inputDeletedTrackedTimeEntryId = ""
        inputAddTrackedTimeEntry = nil
    }
}
