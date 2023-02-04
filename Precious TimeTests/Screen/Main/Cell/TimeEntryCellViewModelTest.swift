// 
//  TimeEntryCellViewModelTest.swift
//  Precious TimeTests
//
//  Created by Rahardyan Bisma on 04/02/23.
//  

import XCTest
import RxTest
import RxSwift
import RxCocoa
@testable import Precious_Time

final class TimeEntryCellViewModelTest: XCTestCase {
    private var mockTimerService: TimerServiceMock!
    private var scheduler: TestScheduler!
    private var disposeBag: DisposeBag!

    override func setUpWithError() throws {
        mockTimerService = TimerServiceMock()
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()
    }

    override func tearDownWithError() throws {
        mockTimerService.reset()
    }

    func testInit() {
        // GIVEN
        // variable with type of TimeEntryCellViewModel
        // a trackedTime object
        var viewModelSUT: TimeEntryCellViewModel?
        let trackedTime = TrackedTime(id: UUID().uuidString, description: "test description", startDate: nil, endDate: nil)
        
        // WHEN: being initialized
        viewModelSUT = TimeEntryCellViewModel(trackedTime: trackedTime, timerService: mockTimerService)
        
        // THEN:
        // it will not nil
        // it will has it's trackedTime object
        XCTAssertNotNil(viewModelSUT)
        XCTAssertEqual(viewModelSUT?.trackedTime.id, trackedTime.id)
    }

    func testOutput_descriptionTextDriver() throws {
        // GIVEN: trackedTime object
        let trackedTime = TrackedTime(id: UUID().uuidString, description: "test description", startDate: nil, endDate: nil)
        let viewModelSUT = TimeEntryCellViewModel(trackedTime: trackedTime, timerService: mockTimerService)
        let output = viewModelSUT.transform(TimeEntryCellViewModel.Input(startButtonTapEvent: .never()))
        let descriptionTextDriver = scheduler.createObserver(String.self)
        
        output.descriptionTextDriver
            .drive(descriptionTextDriver)
            .disposed(by: disposeBag)
        
        // WHEN: scheduler start
        scheduler.start()
        
        // THEN: it will set the description label to "test description"
        XCTAssertEqual(descriptionTextDriver.events, [.next(0, "test description")])
    }
    
    func testOutput_timeDurationTextDriver() throws {
        // GIVEN: trackedTime object
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .second, value: -5, to: endDate)
        let trackedTime = TrackedTime(id: UUID().uuidString, description: "test description", startDate: startDate, endDate: endDate)
        let viewModelSUT = TimeEntryCellViewModel(trackedTime: trackedTime, timerService: mockTimerService)
        let output = viewModelSUT.transform(TimeEntryCellViewModel.Input(startButtonTapEvent: .never()))
        let timeDurationTextDriver = scheduler.createObserver(String.self)
        
        output.timeDurationTextDriver
            .drive(timeDurationTextDriver)
            .disposed(by: disposeBag)
        
        // WHEN: scheduler start
        scheduler.start()
        
        // THEN: it will set the description label to "00:00:05"
        XCTAssertEqual(timeDurationTextDriver.events, [.next(0, "00:00:05")])
    }
    
    func testOutput_timerStartDriver() throws {
        // GIVEN: viewModel has been intialized
        let trackedTime = TrackedTime(id: UUID().uuidString, description: "test description", startDate: nil, endDate: nil)
        let viewModelSUT = TimeEntryCellViewModel(trackedTime: trackedTime, timerService: mockTimerService)
        let output = viewModelSUT.transform(TimeEntryCellViewModel.Input(startButtonTapEvent: scheduler.createColdObservable([.next(1, ())]).asObservable()))
        let timerStartDriver = scheduler.createObserver(Void.self)
        
        output.timerStartDriver
            .drive(timerStartDriver)
            .disposed(by: disposeBag)
        
        // WHEN: scheduler start
        scheduler.start()
        
        // THEN: it will ask the timerService to startTimer and commitTracking
        XCTAssert(mockTimerService.isStartTimerCalled)
        XCTAssert(mockTimerService.isCommitTrackingCalled)
    }
}
