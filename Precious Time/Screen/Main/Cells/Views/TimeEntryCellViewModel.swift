// 
//  TimeEntryCellViewModel.swift
//  Precious Time
//
//  Created by Rahardyan Bisma on 02/02/23.
//  

import Foundation
import RxSwift
import RxCocoa

protocol TimeEntryCellViewModelType {
    
    /// transform input from View to Output produced by the ViewModel
    /// - Parameter input: Input event from the View
    /// - Returns: Output to be consumed by the View
    func transform(_ input: TimeEntryCellViewModel.Input) -> TimeEntryCellViewModel.Output
}

final class TimeEntryCellViewModel: TimeEntryCellViewModelType {
    struct Input {
        let startButtonTapEvent: Observable<Void>
    }
    
    struct Output {
        let descriptionTextDriver: Driver<String>
        let timeDurationTextDriver: Driver<String>
        let timerStartDriver: Driver<Void>
    }
    
    let trackedTime: TrackedTime
    private let timerService: TimerServiceType
    
    init(trackedTime: TrackedTime, timerService: TimerServiceType) {
        self.trackedTime = trackedTime
        self.timerService = timerService
    }
    
    func transform(_ input: Input) -> Output {
        // the description retrieved from TrackedTime.description
        let descriptionTextDriver = BehaviorRelay<String>(value: trackedTime.description ?? "").asDriver()
        
        // the duration retrieved from interval between TrackedTime.endDate and TrackedTime.startDate and format to "00:00:00" using TimeInterval Extension's stringDuration()
        let timeDurationTextDriver = BehaviorRelay<String>(value: trackedTime.endDate?.timeIntervalSince(trackedTime.startDate ?? Date()).stringDuration() ?? "00:00:00").asDriver()
        
        // start tracking new entry by using the same description
        let timerStartDriver = input.startButtonTapEvent
            .do { [weak self] _ in
                self?.timerService.startTimer()
                self?.timerService.commitTracking(description: self?.trackedTime.description)
            }
            .asDriver(onErrorJustReturn: ())
        
        return Output(descriptionTextDriver: descriptionTextDriver,
                      timeDurationTextDriver: timeDurationTextDriver,
                      timerStartDriver: timerStartDriver)
    }
}
