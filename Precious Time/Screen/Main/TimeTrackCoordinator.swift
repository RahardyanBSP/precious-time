// 
//  TimerCoordinator.swift
//  Precious Time
//
//  Created by Rahardyan Bisma on 31/01/23.
//  

import Foundation
import UIKit
import RxSwift

final class TimeTrackCoordinator: BaseCoordinator<Void> {
    private let host: UIWindow?
    
    private lazy var navigationController = UINavigationController()
    
    init(host: UIWindow?) {
        self.host = host
    }
    
    override func start(onComplete: (() -> Void)? = nil) -> Observable<Void> {
        let viewModel = TimeTrackViewModel()
        let viewController = TimeTrackViewController(viewModel: viewModel)
        
        navigationController.setViewControllers([viewController], animated: false)
        
        host?.rootViewController = navigationController
        host?.makeKeyAndVisible()
        
        return Observable.never()
    }
}
