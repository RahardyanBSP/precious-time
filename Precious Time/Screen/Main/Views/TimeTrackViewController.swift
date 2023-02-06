// 
//  MainViewController.swift
//  Precious Time
//
//  Created by Rahardyan Bisma on 30/01/23.
//  

import UIKit
import RxSwift
import RxCocoa

class TimeTrackViewController: UIViewController {
    
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var inputContainerView: UIView!
    @IBOutlet weak var inputTimerCenterXConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputTimerTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var inputTimerLabel: UILabel!
    @IBOutlet weak var timeEntryTableView: UITableView!
    @IBOutlet weak var inputContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    private let viewModel: TimeTrackViewModel
    
    private var trackedTimeEntries: [TimeEntryCellViewModel] = []
    
    private let disposeBag = DisposeBag()
    
    private let viewDidLoadEvent = PublishRelay<Void>()
    private let deleteTimeEntryEvent = PublishRelay<(id: String?, deletedIndexPath: IndexPath)>()
    
    init(viewModel: TimeTrackViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "TimeTrackViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Track your time"
        setupTimeEntryTable()
        bindViewModel()
        viewDidLoadEvent.accept(())
    }
    
    private func bindViewModel() {
        let keyboardAppearEvent = NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
            .withUnretained(self)
            .do { timerViewController, notification in
                if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                    timerViewController.handleKeyboardAppear(keyboardHeight: keyboardFrame.cgRectValue.height)
                }
            }
            .share(scope: .whileConnected)
        
        let keyboardDisappearEvent = NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
            .withUnretained(self)
            .do { timerViewController, notification in
                timerViewController.inputContainerHeightConstraint.constant = 162
                UIView.animate(withDuration: 0.5) {
                    timerViewController.view.layoutIfNeeded()
                }
            }
            .share(scope: .whileConnected)
        
        let input = TimeTrackViewModel.Input(
            viewDidLoadEvent: viewDidLoadEvent.asObservable(),
            keyboardAppearEvent: Observable.merge(keyboardAppearEvent.map({ _ in true }), keyboardDisappearEvent.map({ _ in false })),
            startTrackTapEvent: startButton.rx.tap.asObservable().do(afterNext: { [unowned self] in
                self.view.endEditing(true)
                
            }),
            stopTrackTapEvent: stopButton.rx.tap.asObservable().do(afterNext: { [unowned self] in
                self.view.endEditing(true)
                self.descriptionTextField.text = nil
                self.descriptionTextField.sendActions(for: .valueChanged)
            }),
            deleteTrackedTimeEvent: deleteTimeEntryEvent.asObservable(),
            descriptionTextEvent: descriptionTextField.rx.text.asObservable())
        
        let output = viewModel.transform(input)
        
        output.timeEntriesDriver
            .drive(onNext: { [weak self] in
                self?.trackedTimeEntries = $0
                self?.timeEntryTableView.reloadData()
            })
            .disposed(by: disposeBag)
        
        output.timerTextDriver
            .drive(inputTimerLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.inputTimerAlphaDriver
            .drive(onNext: { [weak self] alpha in
                UIView.animate(withDuration: 0.5) {
                    self?.inputTimerLabel.alpha = alpha
                }
            })
            .disposed(by: disposeBag)
        
        output.descriptionFieldHiddenDriver
            .drive(descriptionTextField.rx.isHidden)
            .disposed(by: disposeBag)
        
        output.startButtonHiddenDriver
            .drive(startButton.rx.isHidden)
            .disposed(by: disposeBag)
        
        output.stopButtonHiddenDriver
            .drive(stopButton.rx.isHidden)
            .disposed(by: disposeBag)
        
        output.timerTextCommitPositionDriver
            .drive(onNext: { [weak self] animate in
                self?.inputContainerView.layoutIfNeeded()
                self?.inputTimerLabel?.alpha = 1.0
                self?.inputTimerTopConstraint?.constant = -50
                self?.inputTimerCenterXConstraint?.constant = 50
                
                if animate {
                    UIView.animate(withDuration: 0.5) {
                        self?.moveTimerToCommitPosition()
                    }
                } else {
                    self?.moveTimerToCommitPosition()
                }
            })
            .disposed(by: disposeBag)
        
        output.timerTextUncommitPositionDriver
            .drive(onNext: { [weak self] in
                self?.inputTimerTopConstraint?.constant = 10
                self?.inputTimerCenterXConstraint?.constant = 0
                
                UIView.animate(withDuration: 0.5) {
                    self?.inputContainerView.layoutIfNeeded()
                    self?.descriptionLabel?.isHidden = true
                    self?.inputTimerLabel?.alpha = 0.0
                    self?.inputTimerLabel?.font = .systemFont(ofSize: 18, weight: .regular)
                }
            })
            .disposed(by: disposeBag)
        
        output.rowInsertedDriver
            .drive(onNext: { [weak self] timeEntryCellViewModel in
                guard let self = self else { return }
                self.trackedTimeEntries.insert(timeEntryCellViewModel, at: 0)
                self.timeEntryTableView.performBatchUpdates({
                    self.timeEntryTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                })
            })
            .disposed(by: disposeBag)
        
        output.rowDeletedDriver
            .drive(onNext: { [weak self] indexPath in
                self?.trackedTimeEntries.remove(at: indexPath.row)
                self?.timeEntryTableView.performBatchUpdates({
                    self?.timeEntryTableView.deleteRows(at: [indexPath], with: .automatic)
                })
                
            })
            .disposed(by: disposeBag)
        
        output.descriptionLabelDriver
            .drive(descriptionLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
    private func handleKeyboardAppear(keyboardHeight: CGFloat) {
        if inputContainerHeightConstraint.constant != 162 {
            return
        }
        inputContainerHeightConstraint.constant += keyboardHeight - 42
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func moveTimerToCommitPosition() {
        inputTimerLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        descriptionLabel?.isHidden = false
        inputContainerView?.layoutIfNeeded()
    }
    
    private func setupTimeEntryTable() {
        timeEntryTableView.register(TimeEntryCell.nib, forCellReuseIdentifier: TimeEntryCell.identifier)
        timeEntryTableView.delegate = self
        timeEntryTableView.dataSource = self
        timeEntryTableView.keyboardDismissMode = .interactive
    }
}

extension TimeTrackViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trackedTimeEntries.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 84
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TimeEntryCell.identifier, for: indexPath) as? TimeEntryCell
        cell?.bindViewModel(viewModel: trackedTimeEntries[indexPath.row])
        
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteTimeEntryEvent.accept((id: trackedTimeEntries[indexPath.row].trackedTime.id, deletedIndexPath: indexPath))
        }
    }
}
