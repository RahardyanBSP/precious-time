// 
//  TimeIntervalFormatTest.swift
//  Precious TimeTests
//
//  Created by Rahardyan Bisma on 03/02/23.
//  

import XCTest
@testable import Precious_Time

final class TimeIntervalFormatTest: XCTestCase {

    func testStringDuration() throws {
        // GIVEN: time interval of 0
        let timeInterval0: TimeInterval = 0.0
        
        // WHEN: get stringDuration
        let stringDuration0 = timeInterval0.stringDuration()
        
        // THEN: it will give "00:00:00" as a result
        XCTAssertEqual(stringDuration0, "00:00:00")
        
        
        // GIVEN: time interval of 1
        let timeInterval1: TimeInterval = 1.0
        
        // WHEN: get stringDuration
        let stringDuration1 = timeInterval1.stringDuration()
        
        // THEN: it will give "00:00:01" as a result
        XCTAssertEqual(stringDuration1, "00:00:01")
        
        
        // GIVEN: time interval of 60
        let timeInterval60: TimeInterval = 60
        
        // WHEN: get stringDuration
        let stringDuration60 = timeInterval60.stringDuration()
        
        // THEN: it will give "00:01:00" as a result
        XCTAssertEqual(stringDuration60, "00:01:00")
        
        
        // GIVEN: time interval of 61
        let timeInterval61: TimeInterval = 61
        
        // WHEN: get stringDuration
        let stringDuration61 = timeInterval61.stringDuration()
        
        // THEN: it will give "00:00:01" as a result
        XCTAssertEqual(stringDuration61, "00:01:01")
        
        
        // GIVEN: time interval of 3600
        let timeInterval3600: TimeInterval = 3600
        
        // WHEN: get stringDuration
        let stringDuration3600 = timeInterval3600.stringDuration()
        
        // THEN: it will give "01:00:00" as a result
        XCTAssertEqual(stringDuration3600, "01:00:00")
        
        
        // GIVEN: time interval of 3661
        let timeInterval3661: TimeInterval = 3661
        
        // WHEN: get stringDuration
        let stringDuration3661 = timeInterval3661.stringDuration()
        
        // THEN: it will give "01:01:01" as a result
        XCTAssertEqual(stringDuration3661, "01:01:01")
    }

}
