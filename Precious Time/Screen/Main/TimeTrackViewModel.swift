// 
//  TimerViewModel.swift
//  Precious Time
//
//  Created by Rahardyan Bisma on 31/01/23.
//  

import Foundation
import RxSwift
import RxCocoa

protocol TimeTrackViewModelType {
    
    /// transform input from View to Output produced by the ViewModel
    /// - Parameter input: Input event from the View
    /// - Returns: Output to be consumed by the View
    func transform(_ input: TimeTrackViewModel.Input) -> TimeTrackViewModel.Output
}

final class TimeTrackViewModel: TimeTrackViewModelType {
    struct Input {
        let viewDidLoadEvent: Observable<Void>
        let keyboardAppearEvent: Observable<Void>
        let keyboardDisappearEvent: Observable<Void>
        let startTrackTapEvent: Observable<Void>
        let stopTrackTapEvent: Observable<Void>
        let deleteTrackedTimeEvent: Observable<(id: String?, deletedIndexPath: IndexPath)>
        let descriptionTextEvent: Observable<String?>
    }
    
    struct Output {
        // list of time entry
        let timeEntriesDriver: Driver<[TimeEntryCellViewModel]>
        
        // timer text "00:00:00"
        let timerTextDriver: Driver<String>
        
        // time text alpha
        let inputTimerAlphaDriver: Driver<CGFloat>
        
        // tell the view to delete row at indexPath
        let rowDeletedDriver: Driver<IndexPath>
        
        // tell the view to insert new time entry
        let rowInsertedDriver: Driver<TimeEntryCellViewModel>
        
        // tell the view to hide or show the descriptionField
        let descriptionFieldHiddenDriver: Driver<Bool>
        
        // animate timerText to commit tracking position
        let timerTextCommitPositionDriver: Driver<Bool>
        
        // animate timerText to uncommit tracking position
        let timerTextUncommitPositionDriver: Driver<Void>
        
        // hide or show the start button
        let startButtonHiddenDriver: Driver<Bool>
        
        // hide or show the stop button
        let stopButtonHiddenDriver: Driver<Bool>
        
        // description label
        let descriptionLabelDriver: Driver<String>
    }
    
    private let localData: TrackedTimeEntryLocalDataServiceType
    private let timerService: TimerServiceType
    
    private let disposeBag = DisposeBag()
    
    init(localData: TrackedTimeEntryLocalDataServiceType = TrackedTimeEntryLocalDataService(),
         timerService: TimerServiceType = TimerService.shared) {
        self.localData = localData
        self.timerService = timerService
    }
    
    func transform(_ input: Input) -> Output {
        let timeEntriesDriver = input.viewDidLoadEvent
            .withUnretained(self)
            // Get [TrackedTime] array from localData
            .flatMap({ viewModel, _ in
                viewModel.localData.getTrackedTimeEntries()
            })
            .withUnretained(self)
            // transform [TrackedTime] -> [TimeEntryCellViewModel] and sort by newest date
            .map({ viewModel, trackedTimes in
                trackedTimes.map({
                    TimeEntryCellViewModel(trackedTime: $0, timerService: viewModel.timerService)
                    
                }).sorted(by: { ($0.trackedTime.startDate ?? Date()) > ($1.trackedTime.startDate ?? Date()) })
            })
            .asDriver(onErrorJustReturn: [])
        
        // timerText use timerService tick event and transform tick to formatted time
        // e.g. tick 1 -> 00:00:01
        let timerTextDriver = timerService
            .timerTickEvent()
            .map({ $0.stringDuration() })
            .asDriver(onErrorJustReturn: "")
        
        let inputTimerAlphaDriver = Observable.merge(
            // show the timer when keyboard appear (user trying to type the description)
            input.keyboardAppearEvent.map({ _ in CGFloat(1.0) }),
            // hide the timer when keyboard disappear without user tap the start button
            input.keyboardDisappearEvent.withUnretained(self).filter({ !$0.0.timerService.isCommitTracking }).map({ _ in CGFloat(0.0) }),
            // show the timer when the time service is commit tracking the time
            input.viewDidLoadEvent.withUnretained(self).filter({$0.0.timerService.isCommitTracking }).map({ _ in CGFloat(1.0) })
        ).asDriver(onErrorJustReturn: CGFloat(0.0))
        
        // when user tap start button
        // lets ask the timerService to startTimer and also commit time tracking
        let commitToTrackTrigger = input.startTrackTapEvent
            .withLatestFrom(input.descriptionTextEvent)
            .withUnretained(self)
            .do {
                $0.0.timerService.startTimer()
                $0.0.timerService.commitTracking(description: $0.1)
            }
            .map({ _ in () })
            .share()
        
        // when user tap stop button
        // lets ask timer to stopTimer and stop commit time tracking
        let stopTrackTrigger = input.stopTrackTapEvent
            .withUnretained(self)
            .map({ $0.0.timerService.stopTimer() })
            .share()
        
        // after tracking stop then we insert the completed time track to localData
        let rowInsertedDriver = stopTrackTrigger
            .map({ TrackedTime(id: UUID().uuidString, description: $0.description, startDate: $0.startDate, endDate: Date()) })
            .withUnretained(self)
            .do { $0.0.localData.addTrackedTimeEntry(trackedTime: $0.1) }
            .map({ TimeEntryCellViewModel(trackedTime: $0.1, timerService: $0.0.timerService) })
            .asDriver(onErrorDriveWith: Driver.empty())
        
        let descriptionFieldHiddenDriver = Observable.merge(
            // on viewDidLoad the state will depand on timerService commitTracking,
            // when the timer is already commit tracking time, then hide the description field
            input.viewDidLoadEvent.withUnretained(self).map({ $0.0.timerService.isCommitTracking }),
            // when timerService start commitTracking or commitToTrackTrigger triggered
            // we should hide the descriptionField
            Observable.merge(timerService.commitTrackingEvent(), commitToTrackTrigger).map({ _ in true }),
            // on stop track event we should bring back descriptionField to visible
            stopTrackTrigger.map({ _ in false })
        ).distinctUntilChanged().asDriver(onErrorJustReturn: false)
        
        let timerTextCommitPositionDriver = Observable.merge(
            // on viewDidload with timeService commit tracking time, lets animate the timer label to commit position
            input.viewDidLoadEvent.withUnretained(self).filter({ $0.0.timerService.isCommitTracking }).map({ _ in false }),
            // on user interaction and got event from timerService's commitTracking, lets animate the timer label to commit position
            Observable.merge(timerService.commitTrackingEvent(), commitToTrackTrigger).map({ true })
        ).asDriver(onErrorJustReturn: false)
        
        let timerTextUncommitPositionDriver = Observable.merge(
            // on viewDidload with timeService not commit tracking time, lets animate the timer label to uncommit position
            input.viewDidLoadEvent.withUnretained(self).filter({ !$0.0.timerService.isCommitTracking }).map({ _ in () }),
            // on user tap stop tracking, lets animate the timer to uncommit position
            stopTrackTrigger.map({ _ in () })
        ).asDriver(onErrorJustReturn: ())
        
        let startButtonHiddenDriver = Observable.merge(
            // on viewDidload and timerService alreay commit tracking, then we sould hide the start button
            input.viewDidLoadEvent.withUnretained(self).map({ $0.0.timerService.isCommitTracking }),
            // when commitTracking tiggered from cell or any other place, then hide the start button
            Observable.merge(timerService.commitTrackingEvent(), commitToTrackTrigger).map({ _ in true }),
            // on stop button tap, lets show the start button
            stopTrackTrigger.map({ _ in false })
        ).distinctUntilChanged().asDriver(onErrorJustReturn: true)
        
        let stopButtonHiddenDriver = Observable.merge(
            // on viewDidLoad, we will show the stop button if timerService is commit tracking time
            input.viewDidLoadEvent.withUnretained(self).map({ !$0.0.timerService.isCommitTracking }),
            // when receiveing timerService commit tracking event we should show the stop button
            Observable.merge(timerService.commitTrackingEvent(), commitToTrackTrigger).map({ _ in false }),
            // when user tap stop button, we should hide the stop button
            stopTrackTrigger.map({ _ in true })
        ).distinctUntilChanged().asDriver(onErrorJustReturn: true)
        
        let rowDeletedDriver = input.deleteTrackedTimeEvent
            .withUnretained(self)
            .do { viewModel, object in
                viewModel.localData.deleteTrackedTimeEntry(id: object.id)
            }
            .map({ $0.1.deletedIndexPath })
            .asDriver(onErrorDriveWith: .empty())
        
        let descriptionLabelDriver = Observable.merge(
            input.viewDidLoadEvent.withUnretained(self).map({ $0.0.timerService.trackingCommitDescription }),
            Observable.merge(timerService.commitTrackingEvent(), commitToTrackTrigger).withUnretained(self).map({ $0.0.timerService.trackingCommitDescription }),
            stopTrackTrigger.map({ _ in "" })
        ).distinctUntilChanged().asDriver(onErrorJustReturn: "")
        
        // start timer but not commit tracking when receiving event from keyboard appear, viewDidLoad with timerService is commit tracking time
        let timerStartTrigger = Observable.merge(input.keyboardAppearEvent, commitToTrackTrigger, input.viewDidLoadEvent.withUnretained(self).filter({ $0.0.timerService.isCommitTracking }).map({ _ in () }))
        
        // stop timer when keyboard disappear
        let timerStopTrigger = Observable.merge(input.keyboardDisappearEvent)
        
        timerStartTrigger
            .withUnretained(self)
            .subscribe { viewModel, _ in
                viewModel.timerService.startTimer()
            }
            .disposed(by: disposeBag)
        
        // when keyboard disappear but timeService is commit tracking time, no need to stop timer
        timerStopTrigger
            .withUnretained(self)
            .filter({ !$0.0.timerService.isCommitTracking })
            .subscribe { viewModel, _ in
                viewModel.timerService.stopTimer()
            }
            .disposed(by: disposeBag)
        
        
        return Output(timeEntriesDriver: timeEntriesDriver,
                      timerTextDriver: timerTextDriver,
                      inputTimerAlphaDriver: inputTimerAlphaDriver,
                      rowDeletedDriver: rowDeletedDriver,
                      rowInsertedDriver: rowInsertedDriver,
                      descriptionFieldHiddenDriver: descriptionFieldHiddenDriver,
                      timerTextCommitPositionDriver: timerTextCommitPositionDriver,
                      timerTextUncommitPositionDriver: timerTextUncommitPositionDriver,
                      startButtonHiddenDriver: startButtonHiddenDriver,
                      stopButtonHiddenDriver: stopButtonHiddenDriver,
                      descriptionLabelDriver: descriptionLabelDriver)
    }
}
