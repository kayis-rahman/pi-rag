    private let notificationDelegate = NotificationDelegate()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        // Request notification permissions
        requestNotificationPermissions()

        return true
    }

    private func requestNotificationPermissions() {
        AppLogger.info("Requesting notification permissions on iOS", category: .general)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            AppLogger.info("iOS notification permission granted: \(granted)", category: .general)
            if granted {
                DispatchQueue.main.async {
                    AppLogger.info("Registering for remote notifications on iOS", category: .general)
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                AppLogger.warning("iOS notification permission denied - bidirectional sync will not work", category: .general)
            }
            if let error = error {
                AppLogger.error("Failed to request notification permissions on iOS: \(error.localizedDescription)", category: .general)
            }
        }
    }

    // MARK: - APNs Token Registration
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        AppLogger.info("Successfully registered for remote notifications on iOS, APNs token: \(tokenString.prefix(10))...", category: .general)

        // Store APNs token in Keychain for later registration
        do {
            try KeychainStore.saveString(tokenString, for: .apnsToken)
            AppLogger.info("APNs token stored in Keychain on iOS", category: .general)
        } catch {
            AppLogger.error("Failed to store APNs token in Keychain on iOS: \(error.localizedDescription)", category: .general)
        }

        // Try to register APNs token with backend if we have authentication
        _Concurrency.Task {
            AppLogger.info("Starting APN token update with backend on iOS", category: .general)
            await updateApnsTokenWithBackend(tokenString)
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        AppLogger.error("Failed to register for remote notifications on iOS: \(error.localizedDescription)", category: .general)
    }

    private func updateApnsTokenWithBackend(_ apnsToken: String) async {
        AppLogger.info("Attempting to update APN token with backend on iOS", category: .general)

        // Debug: Check access token availability
        guard let accessToken = try? KeychainStore.loadString(.accessToken) else {
            AppLogger.warning("No access token available for APNs token update on iOS", category: .general)
            return
        }

        guard let config = Configuration.fromInfoPlist() else {
            AppLogger.warning("No API config available for APNs token update on iOS", category: .general)
            return
        }

        let deviceId = await TimerSyncManager.shared.deviceId
        AppLogger.info("Got deviceId: \(deviceId), updating APN token on iOS", category: .general)
        let apiClient = ApiClient(baseURL: config.baseURL)

        // Retry logic for APN token registration
        let maxRetries = 3
        for attempt in 1...maxRetries {
            do {
                try await apiClient.updateApnsToken(deviceId: deviceId, apnsToken: apnsToken, accessToken: accessToken)
                AppLogger.info("APNs token updated with backend for iOS device: \(deviceId)", category: .general)
                return // Success, exit retry loop
            } catch {
                if attempt == maxRetries {
                    AppLogger.error("Failed to update APNs token with backend on iOS after \(maxRetries) attempts: \(error.localizedDescription)", category: .general)
                } else {
                    AppLogger.warning("APN token update attempt \(attempt) failed on iOS, retrying: \(error.localizedDescription)", category: .general)
                    // Wait before retry
                    _ = try? await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000) // 1, 2, 3 seconds
                }
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Handle data-only (silent) notifications
        let userInfo = notification.request.content.userInfo

        if let type = userInfo["type"] as? String, type == "timer_sync" {
            AppLogger.info("Received timer sync APN message on iOS", category: .sync)

            // Parse action from notification and apply event-based sync
            if let actionDict = userInfo["action"] as? [String: Any],
               let actionType = actionDict["action"] as? String,
               let sourceDeviceId = actionDict["deviceId"] as? String,
               let timestampString = actionDict["timestamp"] as? String,
               let timestamp = Double(timestampString) {

                AppLogger.info("Processing timer action from notification on iOS: \(actionType), device: \(sourceDeviceId)", category: .sync)

                // Apply the incoming action (event-based sync)
                _Concurrency.Task {
                    await TimerSyncManager.shared.syncTimerState()
                }

            // Don't show notification for silent sync messages
            completionHandler([])
            return
        }

        // Show regular notifications
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        if let type = userInfo["type"] as? String, type == "timer_sync" {
            AppLogger.info("User tapped timer sync notification on iOS", category: .sync)

            // Trigger full timer sync when user taps notification (to ensure latest state)
            _Concurrency.Task {
                await TimerSyncManager.shared.syncTimerState()
            }
        }

        completionHandler()
}
}
    }

#endif
