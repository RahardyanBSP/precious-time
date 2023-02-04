// 
//  Date+Format.swift
//  Precious Time
//
//  Created by Rahardyan Bisma on 03/02/23.
//  

import Foundation

extension TimeInterval {
    
    /// Convert interval to timer format hh:mm:ss
    /// - Returns: String "00:00:00"
    func stringDuration() -> String {
        let interval = Int(self)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
