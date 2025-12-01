//
//  AppExtensions.swift
//  TimeBeam
//
//  Created by Kayis Rahman on 03/11/25.
//

import SwiftUI

// MARK: - Int Extension
extension Int {
    var mmss: String {
        let minutes = self / 60
        let seconds = self % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
