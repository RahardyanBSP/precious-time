// 
//  BaseCoordinator.swift
//  Precious Time
//
//  Created by Rahardyan Bisma on 31/01/23.
//  

import Foundation
import RxSwift

class BaseCoordinator<ResultType>: NSObject {
    typealias CoorinatorResult = ResultType
    
    let disposeBag = DisposeBag()
    
    private let identifier = UUID()
    
    private weak var parentCoordinator: BaseCoordinator?
    var childCoordinators = [UUID: Any]()
    
    private func store<T>(coordinator: BaseCoordinator<T>) {
        childCoordinators[coordinator.identifier] = coordinator
    }
    
    private func free<T>(coordinator: BaseCoordinator<T>) {
        childCoordinators[coordinator.identifier] = nil
    }
    
    func coordinate<T>(to coordinator: BaseCoordinator<T>) -> Observable<T> {
        childCoordinators.removeAll()
        store(coordinator: coordinator)
        return coordinator.start()
            .do(onCompleted: { [weak self] in
                self?.free(coordinator: coordinator)
            })
    }
    
    func start(onComplete: (() -> Void)? = nil) -> Observable<ResultType> {
        fatalError("override start method")
    }
}


