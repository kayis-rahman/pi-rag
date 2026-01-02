
        // Show regular notifications
        completionHandler([.banner, .sound])
    }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        if let type = userInfo["type"] as? String, type == "timer_sync" {
            AppLogger.info("User tapped timer sync notification on macOS", category: .sync)
