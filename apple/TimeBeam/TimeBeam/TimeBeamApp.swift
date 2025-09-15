//  TimeBeamApp.swift
//  TimeBeam
//
//  Created by AI Assistant on 15/09/25.

import SwiftUI
import UserNotifications
import AppKit

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Use .banner and .sound for macOS 11+ (alert is deprecated)
        if #available(macOS 11.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.sound])
        }
    }
}

// This is the ONLY @main entry point for the app.
@main
struct TimeBeamApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var timer = PomodoroTimer()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timer)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let notificationDelegate = NotificationDelegate()
    static var statusItem: NSStatusItem?
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = notificationDelegate
        // Create status item
        if AppDelegate.statusItem == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            item.button?.title = "⏰ --:--" // Placeholder until timer updates
            AppDelegate.statusItem = item
        }
    }
    static func updateStatusItem(title: String?) {
        DispatchQueue.main.async {
            if let title = title, !title.isEmpty {
                AppDelegate.statusItem?.button?.title = title
            } else {
                AppDelegate.statusItem?.button?.title = "⏰ --:--"
            }
        }
    }
}
