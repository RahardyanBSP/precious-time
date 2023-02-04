// 
//  TimeRunnerServiceMock.swift
//  Precious TimeTests
//
//  Created by Rahardyan Bisma on 03/02/23.
//  

import Foundation
@testable import Precious_Time

final class TimeRunnerServiceMock: TimeRunnerServiceType {
    var isInvalidateCalled = false
    var isScheduledTimerCalled = false
    var inputTimeInterval: TimeInterval = 0
    var inputRepeats = false
    private(set) var block: ((Timer) -> Void)?
    
    var mockIsRunning = false
    
    var isRunning: Bool {
        return mockIsRunning
    }
    
    func invalidate() {
        isInvalidateCalled = true
    }
    
    func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping @Sendable (Timer) -> Void) {
        isScheduledTimerCalled = true
        self.inputTimeInterval = interval
        self.inputRepeats = repeats
        self.block = block
    }
    
    func reset() {
        isInvalidateCalled = false
        isScheduledTimerCalled = false
        inputTimeInterval = 0.0
        inputRepeats = false
        block = nil
    }
}
