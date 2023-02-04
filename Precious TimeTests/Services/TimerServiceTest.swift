// 
//  TimerService.swift
//  Precious TimeTests
//
//  Created by Rahardyan Bisma on 03/02/23.
//  

import XCTest
import RxTest
import RxSwift
@testable import Precious_Time

final class TimerServiceTest: XCTestCase {
    private var scheduler: TestScheduler!
    private var mockTimeRunner: TimeRunnerServiceMock!
    private var mockUserDefaults: UserDefaultsMock!
    private var disposeBag: DisposeBag!
    private var serviceSUT: TimerService!

    override func setUpWithError() throws {
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)
        mockTimeRunner = TimeRunnerServiceMock()
        mockUserDefaults = UserDefaultsMock()
        serviceSUT = TimerService(timeRunner: mockTimeRunner, scheduler: scheduler, userDefaults: mockUserDefaults)
    }

    override func tearDownWithError() throws {
        mockTimeRunner.reset()
        mockUserDefaults.reset()
    }
    
    func testInit() throws {
        // GIVEN: variable with type of TimerService
        let timerService: TimerService?
        
        // WHEN: being initialized
        timerService = TimerService.shared
        
        // THEN: it will not nil
        XCTAssertNotNil(timerService)
    }

    func testStartTimer_timerRunnerIsRunning() throws {
        // GIVEN: timerRunner is running
        mockTimeRunner.mockIsRunning = true
        
        // WHEN: starTimer
        serviceSUT.startTimer()
        
        // THEN: it will not ask the timeRunner to schedule timer
        XCTAssertFalse(mockTimeRunner.isScheduledTimerCalled)
    }
    
    func testStartTimer_timerRunnerIsNotRunning() throws {
        // GIVEN: timerRunner is running
        mockTimeRunner.mockIsRunning = false
        let tickObserver = scheduler.createObserver(TimeInterval.self)
        serviceSUT.timerTickEvent()
            .bind(to: tickObserver)
            .disposed(by: disposeBag)
        
        // WHEN: starTimer
        serviceSUT.startTimer()
        
        scheduler.start()
        mockTimeRunner.block?(Timer())
        
        // THEN:
        // - it will ask the timeRunner to schedule timer
        // - deliver tick event
        XCTAssert(mockTimeRunner.isScheduledTimerCalled)
        XCTAssert(mockTimeRunner.inputRepeats)
        XCTAssertEqual(mockTimeRunner.inputTimeInterval, 1.0)
        XCTAssertEqual(tickObserver.events, [.next(0, 0), .next(0, 1.0)])
    }
    
    func testStartTimer_timerRunnerIsNotRunning_withCommitTrackingDate() throws {
        // GIVEN: timerRunner is running and there is commit tracking date
        mockTimeRunner.mockIsRunning = false
        mockUserDefaults.resultCommitTrackDate = Date()
        let tickObserver = scheduler.createObserver(TimeInterval.self)
        serviceSUT.timerTickEvent()
            .bind(to: tickObserver)
            .disposed(by: disposeBag)
        
        // WHEN: starTimer
        serviceSUT.startTimer()
        
        scheduler.start()
        mockTimeRunner.block?(Timer())
        
        // THEN:
        // - it will ask the timeRunner to schedule timer
        // - deliver tick event
        XCTAssert(mockTimeRunner.isScheduledTimerCalled)
        XCTAssert(mockTimeRunner.inputRepeats)
        XCTAssertEqual(mockTimeRunner.inputTimeInterval, 1.0)
    }
    
    func testCommitTracking() throws {
        // WHEN: commitTracking
        let commitDescription = "description"
        serviceSUT.commitTracking(description: commitDescription)
        
        // THEN:
        // it will set commit description
        // it will set commit track date
        XCTAssert(mockUserDefaults.inputKeyValue.contains(where: { $0.key == "commit_description" }))
        XCTAssert(mockUserDefaults.inputKeyValue.contains(where: { ($0.value as? String ?? "") == commitDescription }))
        XCTAssert(mockUserDefaults.inputKeyValue.contains(where: { $0.key == "commit_track_date" }))
    }
    
    func testStopTimer() throws {
        // WHEN: stopTimer
        serviceSUT.stopTimer()
        
        // THEN:
        // it will remove commit description
        // it will emove commit track date
        XCTAssert(mockUserDefaults.isRemoveObjectCalled)
        XCTAssert(mockUserDefaults.removeObjectKeys.contains("commit_description"))
        XCTAssert(mockUserDefaults.removeObjectKeys.contains("commit_track_date"))
    }
}
