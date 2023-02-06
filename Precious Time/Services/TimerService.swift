// 
//  TimerService.swift
//  Precious Time
//
//  Created by Rahardyan Bisma on 31/01/23.
//  

import Foundation
import RxSwift
import RxCocoa

protocol TimerServiceType {
    
    /// tick event for every second
    /// - Returns: timeInterval represents seconds
    func timerTickEvent() -> Observable<TimeInterval>
    
    /// Event when time timerService is start commit tracking time
    /// - Returns: Void stream event
    func commitTrackingEvent() -> Observable<Void>
    
    /// Start timer and deliver event to timerTickEvent()
    func startTimer()
    
    /// Commit tracking event (track the startDate to calculate the tracked time duration when call the stopTimer() function)
    /// - Parameter description: tracking description
    func commitTracking(description: String?)
    
    @discardableResult
    /// stop timer and stop tracking
    /// - Returns: startDate of startTime() function and also the tracking description
    func stopTimer() -> (startDate: Date?, description: String?)
    
    /// indicate whether the timerService is commit tracking or not
    var isCommitTracking: Bool { get }
    
    /// get the tracking description
    var trackingCommitDescription: String { get }
}

final class TimerService: TimerServiceType {
    
    static let shared = TimerService()
    
    var isCommitTracking: Bool {
        return (userDefaults.object(forKey: "commit_description") as? String) != nil
    }
    
    var trackingCommitDescription: String {
        let description = (userDefaults.object(forKey: "commit_description") as? String) ?? ""
        return description
    }
    
    private let stopRelay = PublishRelay<Void>()
    private var tickCount: TimeInterval = 0
    private let scheduler: SchedulerType
    private let userDefaults: UserDefaults
    
    private var timeRunner: TimeRunnerServiceType
    private var isTimerRunning = false
    
    private let timerTickRelay = PublishRelay<TimeInterval>()
    private let commitTrackingRelay = PublishRelay<Void>()
    
    init(timeRunner: TimeRunnerServiceType = TimeRunnerService(),
         scheduler: SchedulerType = ConcurrentDispatchQueueScheduler(qos: .userInteractive),
         userDefaults: UserDefaults = UserDefaults.standard) {
        self.timeRunner = timeRunner
        self.scheduler = scheduler
        self.userDefaults = userDefaults
    }
    
    func commitTrackingEvent() -> Observable<Void> {
        return commitTrackingRelay.asObservable()
    }
    
    func timerTickEvent() -> Observable<TimeInterval> {
        return timerTickRelay.asObservable().share(scope: .whileConnected)
    }
    
    func commitTracking(description: String?) {
        userDefaults.set(description, forKey: "commit_description")
        commitTrackingRelay.accept(())
    }
    
    func startTimer() {
        
        if (userDefaults.object(forKey: "timer_start_date") as? Date) == nil || !isCommitTracking {
            userDefaults.set(Date(), forKey: "timer_start_date")
        }
        
        if timeRunner.isRunning {
            return
        }
        
        getTickCountFromStoredStarDate()
        
        timerTickRelay.accept(tickCount)
        timeRunner.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.getTickCountFromStoredStarDate()
            self?.timerTickRelay.accept(self?.tickCount ?? 0)
        }
        
        isTimerRunning = true
    }
    
    private func getTickCountFromStoredStarDate() {
        if let timerStartDate = userDefaults.object(forKey: "timer_start_date") as? Date {
            let skippedInterval = Date().timeIntervalSince(timerStartDate)
            tickCount = skippedInterval
        }
    }
    
    @discardableResult
    func stopTimer() -> (startDate: Date?, description: String?) {
        let startDate = userDefaults.object(forKey: "timer_start_date") as? Date
        let description = userDefaults.object(forKey: "commit_description") as? String
        userDefaults.removeObject(forKey: "timer_start_date")
        userDefaults.removeObject(forKey: "commit_description")
        isTimerRunning = false
        tickCount = 0
        timerTickRelay.accept(0)
        timeRunner.invalidate()
        
        return (startDate: startDate, description: description)
    }
}

protocol TimeRunnerServiceType {
    func invalidate()
    func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping @Sendable (Timer) -> Void)
    var isRunning: Bool { get }
}
