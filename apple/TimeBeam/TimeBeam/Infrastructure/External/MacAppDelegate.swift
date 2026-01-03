#if os(macOS)
import Cocoa
import SwiftUI
import UserNotifications

class MacAppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    static var shared: MacAppDelegate?
    private let notificationDelegate = NotificationDelegate()
    private static var statusItem: NSStatusItem?

    override init() {
        super.init()
        MacAppDelegate.shared = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self

        // Request notification permissions for macOS
        requestNotificationPermissions()

        if MacAppDelegate.statusItem == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            item.button?.title = ""
            item.button?.image = NSImage(systemSymbolName: "timer.circle.fill", accessibilityDescription: nil)
            MacAppDelegate.statusItem = item

            // Create menu
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.shared.terminate(_:)), keyEquivalent: ""))
            item.menu = menu
        }
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("Notification permission granted: \(granted)")
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
#endif
