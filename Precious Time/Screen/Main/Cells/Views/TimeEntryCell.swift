// 
//  TimeEntryCell.swift
//  Precious Time
//
//  Created by Rahardyan Bisma on 30/01/23.
//  

import UIKit
import RxSwift
import RxCocoa

class TimeEntryCell: UITableViewCell {
    static let identifier = "TimeEntryCell"
    static let nib = UINib(nibName: identifier, bundle: nil)

    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var disposeBag: DisposeBag = DisposeBag()
    
    func bindViewModel(viewModel: TimeEntryCellViewModelType) {
        disposeBag = DisposeBag()
        let output = viewModel.transform(TimeEntryCellViewModel.Input(startButtonTapEvent: startButton.rx.tap.asObservable()))
        
        output.descriptionTextDriver
            .drive(descriptionLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.timeDurationTextDriver
            .drive(timeLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.timerStartDriver
            .drive()
            .disposed(by: disposeBag)
    }
}
