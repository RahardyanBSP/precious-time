// 
//  TimeTrackViewModelTest.swift
//  Precious TimeTests
//
//  Created by Rahardyan Bisma on 03/02/23.
//  

import XCTest
import RxTest
import RxSwift
import RxCocoa
@testable import Precious_Time

final class TimeTrackViewModelTest: XCTestCase {
    private var disposeBag: DisposeBag!
    private var scheduler: TestScheduler!
    private var mockLocalData: TrackedTimeEntryLocalDataServiceMock!
    private var mockTimerService: TimerServiceMock!
    private var viewModelSUT: TimeTrackViewModel!

    override func setUpWithError() throws {
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)
        mockLocalData = TrackedTimeEntryLocalDataServiceMock()
        mockTimerService = TimerServiceMock()
        viewModelSUT = TimeTrackViewModel(localData: mockLocalData, timerService: mockTimerService)
    }

    override func tearDownWithError() throws {
        mockLocalData.reset()
        mockTimerService.reset()
    }
    
    func testInit() throws {
        // GIVEN: variable with type of TimeTrackViewModel
        var viewModelSUT: TimeTrackViewModel?
        
        // WHEN: being initialized
        viewModelSUT = TimeTrackViewModel()
        
        // THEN: it will not nil
        XCTAssertNotNil(viewModelSUT)
    }
    
    func testOutput_timeEntriesDriver_emptyLocalData() throws {
        // GIVEN:
        // no data in local
        mockLocalData.resultGetTrackedTimeEntries = Observable.just([])
        
        let timeEntriesDriver = scheduler.createObserver([TimeEntryCellViewModel].self)
        let output = viewModelSUT.transform(TimeTrackViewModel.Input(viewDidLoadEvent: scheduler.createColdObservable([.next(1, ())]).asObservable(),
                                                                     keyboardAppearEvent: .never(),
                                                                     keyboardDisappearEvent: .never(),
                                                                     startTrackTapEvent: .never(),
                                                                     stopTrackTapEvent: .never(),
                                                                     deleteTrackedTimeEvent: .never(),
                                                                     descriptionTextEvent: .never()))
        output.timeEntriesDriver
            .drive(timeEntriesDriver)
            .disposed(by: disposeBag)
        
        // WHEN: viewDidloadEvent triggered
        scheduler.start()
        
        // THEN: it will deliver an empty array on timeEntriesDriver
        XCTAssert(timeEntriesDriver.events[0].time == 1)
        XCTAssert(timeEntriesDriver.events[0].value.element?.isEmpty ?? false)
    }
    
    func testOutput_timeEntriesDriver_withLocalData() throws {
        // GIVEN:
        // withData
        let baseStartDate = Date()
        let afterBaseStartDate = Calendar.current.date(bySetting: .day, value: 1, of: baseStartDate)
        
        let trackedTime1 = TrackedTime(id: UUID().uuidString, description: "test description1", startDate: baseStartDate, endDate: nil)
        let trackedTime2 = TrackedTime(id: UUID().uuidString, description: "test description2", startDate: afterBaseStartDate, endDate: nil)
        mockLocalData.resultGetTrackedTimeEntries = Observable.just([
            trackedTime1,
            trackedTime2
        ])
        
        let timeEntriesDriver = scheduler.createObserver([TimeEntryCellViewModel].self)
        let output = viewModelSUT.transform(TimeTrackViewModel.Input(viewDidLoadEvent: scheduler.createColdObservable([.next(1, ())]).asObservable(),
                                                                     keyboardAppearEvent: .never(),
                                                                     keyboardDisappearEvent: .never(),
                                                                     startTrackTapEvent: .never(),
                                                                     stopTrackTapEvent: .never(),
                                                                     deleteTrackedTimeEvent: .never(),
                                                                     descriptionTextEvent: .never()))
        output.timeEntriesDriver
            .drive(timeEntriesDriver)
            .disposed(by: disposeBag)
        
        // WHEN: viewDidloadEvent triggered
        scheduler.start()
        
        // THEN: it will deliver an array of TimeEntryCellViewModel sorted by date
        XCTAssert(timeEntriesDriver.events[0].time == 1)
        XCTAssertFalse(timeEntriesDriver.events[0].value.element?.isEmpty ?? false)
        XCTAssertEqual(timeEntriesDriver.events[0].value.element?[0].trackedTime.description, trackedTime2.description)
        XCTAssertEqual(timeEntriesDriver.events[0].value.element?[1].trackedTime.description, trackedTime1.description)
    }
    
    func testOutput_timerTextDriver() throws {
        // GIVEN: timerService ticks 5 times
        mockTimerService.resultTimerTickEvent = scheduler.createColdObservable([.next(1, 1), .next(2, 2), .next(3, 3), .next(4, 4), .next(5, 5)]).asObservable()
        let output = viewModelSUT.transform(TimeTrackViewModel.Input(viewDidLoadEvent: .never(), keyboardAppearEvent: .never(), keyboardDisappearEvent: .never(), startTrackTapEvent: .never(), stopTrackTapEvent: .never(), deleteTrackedTimeEvent: .never(), descriptionTextEvent: .never()))
        let timerTextDriver = scheduler.createObserver(String.self)
        output.timerTextDriver
            .drive(timerTextDriver)
            .disposed(by: disposeBag)
        
        // WHEN: time tick start
        scheduler.start()
        
        // THEN: it will show 00:00:01-5
        XCTAssertEqual(timerTextDriver.events, [.next(1, "00:00:01"), .next(2, "00:00:02"), .next(3, "00:00:03"), .next(4, "00:00:04"), .next(5, "00:00:05")])
    }
    
    func testOutput_inputTimerAlphaDriver_NotCommitTrackingTime() throws {
        // GIVEN: timerService is not commit tracking time
        mockTimerService.resultIsCommitTracking = false
        let output = viewModelSUT.transform(TimeTrackViewModel.Input(viewDidLoadEvent: scheduler.createColdObservable([.next(1, ())]).asObservable(), keyboardAppearEvent: scheduler.createColdObservable([.next(2, ())]).asObservable(), keyboardDisappearEvent: scheduler.createColdObservable([.next(3, ())]).asObservable(), startTrackTapEvent: .never(), stopTrackTapEvent: .never(), deleteTrackedTimeEvent: .never(), descriptionTextEvent: .never()))
        let inputTimerAlhpaDriver = scheduler.createObserver(CGFloat.self)
        output.inputTimerAlphaDriver
            .drive(inputTimerAlhpaDriver)
            .disposed(by: disposeBag)
        
        // WHEN: scheduler start
        scheduler.start()
        
        // THEN:
        // it will ignore the event at 1 from viewDidLoad
        // it will set the alpha to 1.0 at 2
        // it will set the alpha to 0.0 at 3
        XCTAssertEqual(inputTimerAlhpaDriver.events, [.next(2, 1.0), .next(3, 0.0)])
    }

    func testOutput_inputTimerAlphaDriver_CommitTrackingTime() throws {
        // GIVEN: timerService is commit tracking time
        mockTimerService.resultIsCommitTracking = true
        let output = viewModelSUT.transform(TimeTrackViewModel.Input(viewDidLoadEvent: scheduler.createColdObservable([.next(1, ())]).asObservable(), keyboardAppearEvent: scheduler.createColdObservable([.next(2, ())]).asObservable(), keyboardDisappearEvent: scheduler.createColdObservable([.next(3, ())]).asObservable(), startTrackTapEvent: .never(), stopTrackTapEvent: .never(), deleteTrackedTimeEvent: .never(), descriptionTextEvent: .never()))
        let inputTimerAlhpaDriver = scheduler.createObserver(CGFloat.self)
        output.inputTimerAlphaDriver
            .drive(inputTimerAlhpaDriver)
            .disposed(by: disposeBag)
        
        // WHEN: scheduler start
        scheduler.start()
        
        // THEN:
        // it will set the alpha to 1.0 at 1
        // it will set the alpha to 1.0 at 2
        // it will ignore the event at 3 (keyboardDisappear)
        XCTAssertEqual(inputTimerAlhpaDriver.events, [.next(1, 1.0), .next(2, 1.0)])
    }
    
    func testOutput_rowDeletedDriver() throws {
        // GIVEN: there is time entry to be deleted
        let timeEntryToBeDeleted = TrackedTime(id: UUID().uuidString, description: "delete me", startDate: Date(), endDate: Date())
        let output = viewModelSUT.transform(TimeTrackViewModel.Input(viewDidLoadEvent: .never(),
                                                                     keyboardAppearEvent: .never(),
                                                                     keyboardDisappearEvent: .never(),
                                                                     startTrackTapEvent: .never(),
                                                                     stopTrackTapEvent: .never(),
                                                                     deleteTrackedTimeEvent: scheduler.createColdObservable([.next(1, (id: timeEntryToBeDeleted.id, deletedIndexPath: IndexPath(row: 0, section: 0)))]).asObservable(),
                                                                     descriptionTextEvent: .never()))
        let rowDeletedDriver = scheduler.createObserver(IndexPath.self)
        output.rowDeletedDriver
            .drive(rowDeletedDriver)
            .disposed(by: disposeBag)
        
        // WHEN: delete event triggered
        scheduler.start()
        
        // THEN:
        // it will ask localData to delete
        // it will ask the view to delete at IndexPath(row: 0, section: 0)
        XCTAssert(mockLocalData.isDeleteTrackedTimeEntryCalled)
        XCTAssertEqual(mockLocalData.inputDeletedTrackedTimeEntryId, timeEntryToBeDeleted.id)
        XCTAssertEqual(rowDeletedDriver.events.last?.value.element?.row, 0)
    }
    
    func testOutput_rowInsertedDriver() throws {
        // GIVEN:
        // Timer is commit tracking and save the description
        mockTimerService.resultIsCommitTracking = true
        mockTimerService.resultStopTimer = (startDate: Date(), description: "test description")
        let output = viewModelSUT.transform(TimeTrackViewModel.Input(viewDidLoadEvent: .never(),
                                                                     keyboardAppearEvent: .never(),
                                                                     keyboardDisappearEvent: .never(),
                                                                     startTrackTapEvent: .never(),
                                                                     stopTrackTapEvent: scheduler.createColdObservable([.next(1, ())]).asObservable(),
                                                                     deleteTrackedTimeEvent: .never(),
                                                                     descriptionTextEvent: .never()))
        let rowInsertedDriver = scheduler.createObserver(TimeEntryCellViewModel.self)
        output.rowInsertedDriver
            .drive(rowInsertedDriver)
            .disposed(by: disposeBag)
        
        // WHEN: stopTrackTapEvent triggered
        scheduler.start()
        
        // THEN:
        // it will ask timerService to stopTimer
        // it will ask localData to add new time entry
        // it will ask the view to insert the new time entry
        XCTAssert(mockTimerService.isStopTimerCalled)
        XCTAssert(mockLocalData.isAddTrackedTimeEntryCalled)
        XCTAssertEqual(mockLocalData.inputAddTrackedTimeEntry?.description, "test description")
        XCTAssertEqual(rowInsertedDriver.events.last?.value.element?.trackedTime.description, "test description")
    }
    
    func testOutput_descriptionFieldHiddenDriver_NotCommitTracking() throws {
        // GIVEN: timerService not commit tracking time
        mockTimerService.resultIsCommitTracking = false
        let output = viewModelSUT.transform(TimeTrackViewModel.Input(viewDidLoadEvent: scheduler.createColdObservable([.next(1, ())]).asObservable(), keyboardAppearEvent: .never(), keyboardDisappearEvent: .never(), startTrackTapEvent: scheduler.createColdObservable([.next(3, ())]).asObservable(), stopTrackTapEvent: scheduler.createColdObservable([.next(2, ())]).asObservable(), deleteTrackedTimeEvent: .never(), descriptionTextEvent: Observable.just("")))
        let descriptionFieldHiddenDriver = scheduler.createObserver(Bool.self)
        output.descriptionFieldHiddenDriver
            .drive(descriptionFieldHiddenDriver)
            .disposed(by: disposeBag)
        
        // WHEN: scheduler start
        scheduler.start()
        
        // THEN:
        // it will show the field at interval 1
        // it will ignore interval 2 because disticnUntilChange applied
        // it will hide the field at interval 3
        XCTAssertEqual(descriptionFieldHiddenDriver.events, [.next(1, false), .next(3, true)])
    }
    
    func testOutput_descriptionFieldHiddenDriver_CommitTracking() throws {
        // GIVEN: timerService commit tracking time
        mockTimerService.resultIsCommitTracking = true
        let output = viewModelSUT.transform(TimeTrackViewModel.Input(viewDidLoadEvent: scheduler.createColdObservable([.next(1, ())]).asObservable(), keyboardAppearEvent: .never(), keyboardDisappearEvent: .never(), startTrackTapEvent: scheduler.createColdObservable([.next(3, ())]).asObservable(), stopTrackTapEvent: scheduler.createColdObservable([.next(2, ())]).asObservable(), deleteTrackedTimeEvent: .never(), descriptionTextEvent: Observable.just("")))
        let descriptionFieldHiddenDriver = scheduler.createObserver(Bool.self)
        output.descriptionFieldHiddenDriver
            .drive(descriptionFieldHiddenDriver)
            .disposed(by: disposeBag)
        
        // WHEN: scheduler start
        scheduler.start()
        
        // THEN:
        // it will hide the field at interval 1 (viewDidLoad)
        // it will show the field at interval 2 (stop track)
        // it will hide the field at interval 3 (start track)
        XCTAssertEqual(descriptionFieldHiddenDriver.events, [.next(1, true), .next(2, false), .next(3, true)])
    }
    
    func testOutput_timerTextCommitPositionDriver_NotCommitTracking() throws {
        // GIVEN: timerService is not commit tracking
        mockTimerService.resultIsCommitTracking = false
        let output = viewModelSUT.transform(TimeTrackViewModel.Input(viewDidLoadEvent: scheduler.createColdObservable([.next(1, ())]).asObservable(), keyboardAppearEvent: .never(), keyboardDisappearEvent: .never(), startTrackTapEvent: scheduler.createColdObservable([.next(2, ())]).asObservable(), stopTrackTapEvent: .never(), deleteTrackedTimeEvent: .never(), descriptionTextEvent: Observable.just("")))
        let timerTextCommitPositionDriver = scheduler.createObserver(Bool.self)
        output.timerTextCommitPositionDriver
            .drive(timerTextCommitPositionDriver)
            .disposed(by: disposeBag)
        
        // WHEN: scheduelr start
        scheduler.start()
        
        // THEN:
        // it will ask the view to move timerText to commit position at interval 2
        XCTAssertEqual(timerTextCommitPositionDriver.events, [.next(2, true)])
    }
    
    func testOutput_timerTextCommitPositionDriver_CommitTracking() throws {
        // GIVEN: timerService is commit tracking
        mockTimerService.resultIsCommitTracking = true
        let output = viewModelSUT.transform(TimeTrackViewModel.Input(viewDidLoadEvent: scheduler.createColdObservable([.next(1, ())]).asObservable(), keyboardAppearEvent: .never(), keyboardDisappearEvent: .never(), startTrackTapEvent: scheduler.createColdObservable([.next(2, ())]).asObservable(), stopTrackTapEvent: .never(), deleteTrackedTimeEvent: .never(), descriptionTextEvent: Observable.just("")))
        let timerTextCommitPositionDriver = scheduler.createObserver(Bool.self)
        output.timerTextCommitPositionDriver
            .drive(timerTextCommitPositionDriver)
            .disposed(by: disposeBag)
        
        // WHEN: scheduelr start
        scheduler.start()
        
        // THEN:
        // it will ask the view to move timer to commit position without animation at interval 1
        // it will ask the view to move timerText to commit position at interval 2
        XCTAssertEqual(timerTextCommitPositionDriver.events, [.next(1, false), .next(2, true)])
    }
    
    func testOutput_timerTextUncommitPositionDriver_NotCommitTracking() throws {
        // GIVEN: timerService is not commit tracking
        mockTimerService.resultIsCommitTracking = false
        let output = viewModelSUT.transform(TimeTrackViewModel.Input(viewDidLoadEvent: scheduler.createColdObservable([.next(1, ())]).asObservable(), keyboardAppearEvent: .never(), keyboardDisappearEvent: .never(), startTrackTapEvent: .never(), stopTrackTapEvent: scheduler.createColdObservable([.next(2, ())]).asObservable(), deleteTrackedTimeEvent: .never(), descriptionTextEvent: Observable.just("")))
        let timerTextUncommitPositionDriver = scheduler.createObserver(Void.self)
        output.timerTextUncommitPositionDriver
            .drive(timerTextUncommitPositionDriver)
            .disposed(by: disposeBag)
        
        // WHEN: scheduelr start
        scheduler.start()
        
        // THEN:
        // it will ask the view to move timer text to uncommit position at interval 1 (viewDidLoad)and 2 (when stop buttton tap event triggered)
        XCTAssertEqual(timerTextUncommitPositionDriver.events.first?.time, 1)
        XCTAssertEqual(timerTextUncommitPositionDriver.events.last?.time, 2)
    }
    func testOutput_timerTextUncommitPositionDriver_CommitTracking() throws {
        // GIVEN: timerService is commit tracking
        mockTimerService.resultIsCommitTracking = true
        let output = viewModelSUT.transform(TimeTrackViewModel.Input(viewDidLoadEvent: scheduler.createColdObservable([.next(1, ())]).asObservable(), keyboardAppearEvent: .never(), keyboardDisappearEvent: .never(), startTrackTapEvent: .never(), stopTrackTapEvent: scheduler.createColdObservable([.next(2, ())]).asObservable(), deleteTrackedTimeEvent: .never(), descriptionTextEvent: Observable.just("")))
        let timerTextUncommitPositionDriver = scheduler.createObserver(Void.self)
        output.timerTextUncommitPositionDriver
            .drive(timerTextUncommitPositionDriver)
            .disposed(by: disposeBag)
        
        // WHEN: scheduelr start
        scheduler.start()
        
        // THEN:
        // it will ask the view to move timer text to uncommit position at interval 2 (when stop buttton tap event triggered)
        XCTAssertEqual(timerTextUncommitPositionDriver.events.first?.time, 2)
    }
    
    func testOutput_startButtonHiddenDriver_NotCommitTracking() throws {
        // GIVEN: timerService is not commit tracking
        mockTimerService.resultIsCommitTracking = false
        let output = viewModelSUT.transform(TimeTrackViewModel.Input(viewDidLoadEvent: scheduler.createColdObservable([.next(1, ())]).asObservable(), keyboardAppearEvent: .never(), keyboardDisappearEvent: .never(), startTrackTapEvent: scheduler.createColdObservable([.next(2, ())]).asObservable(), stopTrackTapEvent: scheduler.createColdObservable([.next(3, ())]).asObservable(), deleteTrackedTimeEvent: .never(), descriptionTextEvent: Observable.just("")))
        let startButtonHiddenDriver = scheduler.createObserver(Bool.self)
        output.startButtonHiddenDriver
            .drive(startButtonHiddenDriver)
            .disposed(by: disposeBag)
        
        // WHEN: scheduelr start
        scheduler.start()
        
        // THEN:
        // it will ask the view to show the button at interval 1(viewDidLoad), hide the button at interval 2(start button tap), show the button at interval 3(stop button tap)
        XCTAssertEqual(startButtonHiddenDriver.events, [.next(1, false), .next(2, true), .next(3, false)])
    }
    
    func testOutput_startButtonHiddenDriver_CommitTracking() throws {
        // GIVEN: timerService is commit tracking
        mockTimerService.resultIsCommitTracking = true
        let output = viewModelSUT.transform(TimeTrackViewModel.Input(viewDidLoadEvent: scheduler.createColdObservable([.next(1, ())]).asObservable(), keyboardAppearEvent: .never(), keyboardDisappearEvent: .never(), startTrackTapEvent: scheduler.createColdObservable([.next(2, ())]).asObservable(), stopTrackTapEvent: scheduler.createColdObservable([.next(3, ())]).asObservable(), deleteTrackedTimeEvent: .never(), descriptionTextEvent: Observable.just("")))
        let startButtonHiddenDriver = scheduler.createObserver(Bool.self)
        output.startButtonHiddenDriver
            .drive(startButtonHiddenDriver)
            .disposed(by: disposeBag)
        
        // WHEN: scheduelr start
        scheduler.start()
        
        // THEN:
        // it will ask the view to show the button at interval 1(viewDidLoad), ignore event at interval 2(start button tap) because distincUntilChanged applied, show the button at interval 3(stop button tap)
        XCTAssertEqual(startButtonHiddenDriver.events, [.next(1, true), .next(3, false)])
    }
    
    func testOutput_stopButtonHiddenDriver_NotCommitTracking() throws {
        // GIVEN: timerService is not commit tracking
        mockTimerService.resultIsCommitTracking = false
        let output = viewModelSUT.transform(TimeTrackViewModel.Input(viewDidLoadEvent: scheduler.createColdObservable([.next(1, ())]).asObservable(), keyboardAppearEvent: .never(), keyboardDisappearEvent: .never(), startTrackTapEvent: scheduler.createColdObservable([.next(2, ())]).asObservable(), stopTrackTapEvent: scheduler.createColdObservable([.next(3, ())]).asObservable(), deleteTrackedTimeEvent: .never(), descriptionTextEvent: Observable.just("")))
        let stopButtonHiddenDriver = scheduler.createObserver(Bool.self)
        output.stopButtonHiddenDriver
            .drive(stopButtonHiddenDriver)
            .disposed(by: disposeBag)
        
        // WHEN: scheduelr start
        scheduler.start()
        
        // THEN:
        // it will ask the view to show the button at interval 1(viewDidLoad), hide the button at interval 2(start button tap), show the button at interval 3(stop button tap)
        XCTAssertEqual(stopButtonHiddenDriver.events, [.next(1, true), .next(2, false), .next(3, true)])
    }
    
    func testOutput_stopButtonHiddenDriver_CommitTracking() throws {
        // GIVEN: timerService is commit tracking
        mockTimerService.resultIsCommitTracking = true
        let output = viewModelSUT.transform(TimeTrackViewModel.Input(viewDidLoadEvent: scheduler.createColdObservable([.next(1, ())]).asObservable(), keyboardAppearEvent: .never(), keyboardDisappearEvent: .never(), startTrackTapEvent: scheduler.createColdObservable([.next(2, ())]).asObservable(), stopTrackTapEvent: scheduler.createColdObservable([.next(3, ())]).asObservable(), deleteTrackedTimeEvent: .never(), descriptionTextEvent: Observable.just("")))
        let stopButtonHiddenDriver = scheduler.createObserver(Bool.self)
        output.stopButtonHiddenDriver
            .drive(stopButtonHiddenDriver)
            .disposed(by: disposeBag)
        
        // WHEN: scheduelr start
        scheduler.start()
        
        // THEN:
        // it will ask the view to show the button at interval 1(viewDidLoad), ignore event at interval 2(start button tap) because distincUntilChanged applied, show the button at interval 3(stop button tap)
        XCTAssertEqual(stopButtonHiddenDriver.events, [.next(1, false), .next(3, true)])
    }
    
    func testOutput_descriptionLabelDriver() throws {
        // GIVEN: there is tracking commit description in timerService
        mockTimerService.resultTrackingCommitDescription = "test description"
        let output = viewModelSUT.transform(TimeTrackViewModel.Input(viewDidLoadEvent: scheduler.createColdObservable([.next(1, ())]).asObservable(), keyboardAppearEvent: .never(), keyboardDisappearEvent: .never(), startTrackTapEvent: scheduler.createColdObservable([.next(2, ())]).asObservable(), stopTrackTapEvent: scheduler.createColdObservable([.next(3, ())]).asObservable(), deleteTrackedTimeEvent: .never(), descriptionTextEvent: .never()))
        let descriptionLabelDriver = scheduler.createObserver(String.self)
        
        output.descriptionLabelDriver
            .drive(descriptionLabelDriver)
            .disposed(by: disposeBag)
        
        // WHEN: scheduler start
        scheduler.start()
        
        // THEN: it will ask the view to set descriptionLabel text to "test description" at interval 1 (viewDidLoad), ignore interval 2 (start button tap), set text to "" at interval 3
        XCTAssertEqual(descriptionLabelDriver.events, [.next(1, "test description"), .next(3, "")])
    }
}
