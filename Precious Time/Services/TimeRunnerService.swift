// 
//  TimeRunnerService.swift
//  Precious Time
//
//  Created by Rahardyan Bisma on 04/02/23.
//  

import Foundation

final class TimeRunnerService: TimeRunnerServiceType {
    var isRunning: Bool {
        return timer != nil
    }
    
    private var timer: Timer?
    
    func invalidate() {
        timer?.invalidate()
        timer = nil
    }
    
    func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats, block: block)
    }
}
