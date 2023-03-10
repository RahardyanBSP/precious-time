// 
//  UserDefaultsMock.swift
//  Precious TimeTests
//
//  Created by Rahardyan Bisma on 03/02/23.
//  

import Foundation

final class UserDefaultsMock: UserDefaults {
    var resultTimerStartDate: Date?
    var resultCommitDescription: String?
    var resultAny: Any?
    
    var isSetCalled = false
    var isRemoveObjectCalled = false
    var inputKeyValue: [String: Any?] = [:]
    var removeObjectKeys: [String] = []
    
    override func object(forKey defaultName: String) -> Any? {
        if defaultName == "timer_start_date" {
            return resultTimerStartDate
        } else if defaultName == "commit_description" {
            return resultCommitDescription
        }
        
        return resultAny
    }
    
    override func removeObject(forKey defaultName: String) {
        isRemoveObjectCalled = true
        removeObjectKeys.append(defaultName)
    }
    
    override func set(_ value: Any?, forKey defaultName: String) {
        isSetCalled = true
        inputKeyValue[defaultName] = value
    }
    
    func reset() {
        resultTimerStartDate = nil
        resultCommitDescription = nil
        resultAny = nil
        
        isSetCalled = false
        inputKeyValue = [:]
        removeObjectKeys = []
    }
}
