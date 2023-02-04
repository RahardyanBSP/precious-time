// 
//  TimeTrackCoordinatorTest.swift
//  Precious TimeTests
//
//  Created by Rahardyan Bisma on 03/02/23.
//  

import XCTest
import RxSwift
@testable import Precious_Time

final class TimeTrackCoordinatorTest: XCTestCase {
    var mockWindow: UIWindow!
    var disposeBag: DisposeBag!

    override func setUpWithError() throws {
        mockWindow = UIWindow(frame: UIScreen.main.bounds)
        disposeBag = DisposeBag()
    }
    
    func testInit() throws {
        // GIVEN: variable with type of TimeTrackCoordinator
        var coordinatorSUT: TimeTrackCoordinator?
        
        // WHEN: being initialized
        coordinatorSUT = TimeTrackCoordinator(host: mockWindow)
        
        // THEN: it will not nil
        XCTAssertNotNil(coordinatorSUT)
    }
    
    func testStart() throws {
        // GIVEN: TimeTrackCoordinator has been initialized
        let coordinatorSUT = TimeTrackCoordinator(host: mockWindow)
        
        // WHEN: being started
        coordinatorSUT.start()
            .subscribe()
            .disposed(by: disposeBag)
        
        // THEN: it will assign navigationController with TimeTrackViewController as its viewController to window.rootViewController
        
        let navigationController = mockWindow.rootViewController as! UINavigationController
        let timeTrackViewController = navigationController.viewControllers.first
        
        XCTAssert(timeTrackViewController is TimeTrackViewController)
    }

}
