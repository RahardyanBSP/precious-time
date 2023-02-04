// 
//  TimerServiceMock.swift
//  Precious TimeTests
//
//  Created by Rahardyan Bisma on 03/02/23.
//  

import Foundation
import RxSwift
@testable import Precious_Time

final class TimerServiceMock: TimerServiceType {
    var resultTimerTickEvent: Observable<TimeInterval> = .empty()
    var resultCommitTrackingEvent: Observable<Void> = .empty()
    var isStartTimerCalled = false
    var isCommitTrackingCalled = false
    var isStopTimerCalled = false
    var resultStopTimer: (startDate: Date?, description: String?) = (startDate: nil, description: nil)
    
    var resultIsCommitTracking = false
    var resultTrackingCommitDescription = ""
    
    /// tick event for every second
    /// - Returns: timeInterval represents seconds
    func timerTickEvent() -> Observable<TimeInterval> {
        return resultTimerTickEvent
    }
    
    /// Event when time timerService is start commit tracking time
    /// - Returns: Void stream event
    func commitTrackingEvent() -> Observable<Void> {
        return resultCommitTrackingEvent
    }
    
    /// Start timer and deliver event to timerTickEvent()
    func startTimer() {
        isStartTimerCalled = true
    }
    
    /// Commit tracking event (track the startDate to calculate the tracked time duration when call the stopTimer() function)
    /// - Parameter description: tracking description
    func commitTracking(description: String?) {
        isCommitTrackingCalled = true
        resultIsCommitTracking = true
    }
    
    @discardableResult
    /// stop timer and stop tracking
    /// - Returns: startDate of startTime() function and also the tracking description
    func stopTimer() -> (startDate: Date?, description: String?) {
        isStopTimerCalled = true
        return resultStopTimer
    }
    
    /// indicate whether the timerService is commit tracking or not
    var isCommitTracking: Bool {
        return resultIsCommitTracking
    }
    
    /// get the tracking description
    var trackingCommitDescription: String {
        return resultTrackingCommitDescription
    }
    
    func reset() {
        resultTimerTickEvent = .empty()
        resultCommitTrackingEvent = .empty()
        isStartTimerCalled = false
        isCommitTrackingCalled = false
        isStopTimerCalled = false
        resultStopTimer = (startDate: nil, description: nil)
        
        resultIsCommitTracking = false
        resultTrackingCommitDescription = ""
    }
}
