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
            MacAppDelegate.statusItem = item
        }

        // Set up Apple Event Manager for URL handling (legacy support)
        let appleEventManager = NSAppleEventManager.shared()
        appleEventManager.setEventHandler(self, andSelector: #selector(handleURLEvent(_:replyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))

        // Ensure URL scheme registration
        registerURLScheme()
    }

    // Legacy Apple Event URL handler for kAEGetURL (fallback for older macOS versions / setups)
    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
        // Extract URL string from the Apple Event
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString) else {
            AppLogger.warning("[Auth] handleURLEvent: Unable to extract URL from Apple Event", category: .general)
            return
        }

        // Ensure we only handle supported OAuth callback URLs
        guard isSupportedOAuthURL(url) else {
            AppLogger.warning("[Auth] handleURLEvent: Unsupported URL scheme: \(url.absoluteString)", category: .general)
            return
        }

        // Forward to the modern OAuth handler used by the app
        handleOAuthCallback(url)
    }

    private func registerURLScheme() {
        // This helps ensure the URL scheme is properly registered
        let _ = Bundle.main.bundleIdentifier ?? "com.sparkage.time-beam"

    }

    private func isSupportedOAuthURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme else { return false }
        // Primary app scheme
        if scheme == "com.sparkage.time-beam" { return true }
        // Also allow Google-minted scheme from Info.plist (GOOGLE_REDIRECT_URI)
        if let redirect = Bundle.main.infoDictionary?["GOOGLE_REDIRECT_URI"] as? String,
           let redirectURL = URL(string: redirect),
           let redirectScheme = redirectURL.scheme,
           scheme == redirectScheme {
            return true
        }
        return false
    }

    // Handle OAuth callback URLs (modern delegate method)
    func application(_ application: NSApplication, open urls: [URL]) -> Bool {
        for url in urls {
            if isSupportedOAuthURL(url) {
                handleOAuthCallback(url)
                return true
            }
        }
        return false
    }

    // Ensure app becomes active when handling URL
    func applicationDidBecomeActive(_ notification: Notification) {
        // This ensures the app is properly activated
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func handleOAuthCallback(_ url: URL) {
        print("[Auth] handleOAuthCallback: OAuth callback received: \(url.absoluteString)")

        // Ensure app becomes active and window comes to front
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.mainWindow {
            window.makeKeyAndOrderFront(nil)
        }

        // Extract authorization code from URL
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems,
              let codeItem = queryItems.first(where: { $0.name == "code" }),
              let code = codeItem.value else {
            print("[Auth] handleOAuthCallback: No authorization code found")
            return
        }

        print("[Auth] handleOAuthCallback: Authorization code received: \(code.prefix(20))...")

        // Pass the authorization code to AuthManager for token exchange
        Task {
            do {
                try await AuthManager.shared.handleOAuthCallback(url)
            } catch {
                print("[Auth] OAuth callback failed: \(error)")
                // Error handled silently - logged above
            }
        }

        // Authentication completed successfully
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    AppLogger.info("Registering for remote notifications on macOS", category: .general)
                    NSApplication.shared.registerForRemoteNotifications()
                }
            } else {
                AppLogger.warning("macOS notification permission denied - bidirectional sync will not work", category: .general)
            }
            if let error = error {
                AppLogger.error("Failed to request notification permissions on macOS: \(error.localizedDescription)", category: .general)
            }
        }
    }

    // MARK: - APNs Token Registration (macOS)
    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        AppLogger.info("Successfully registered for remote notifications on macOS, APNs token: \(tokenString.prefix(10))...", category: .general)

        // Store APNs token in Keychain for later registration
        do {
            try KeychainStore.saveString(tokenString, for: .apnsToken)
            AppLogger.info("APNs token stored in Keychain on macOS", category: .general)
        } catch {
            AppLogger.error("Failed to store APNs token in Keychain on macOS: \(error.localizedDescription)", category: .general)
        }

        // Try to register APNs token with backend if we have authentication
        _Concurrency.Task {
            AppLogger.info("Starting APN token update with backend on macOS", category: .general)
            await updateApnsTokenWithBackend(tokenString)
        }
    }

    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        AppLogger.error("Failed to register for remote notifications on macOS: \(error.localizedDescription)", category: .general)
    }

    private func updateApnsTokenWithBackend(_ apnsToken: String) async {
        AppLogger.info("Attempting to update APN token with backend on macOS", category: .general)

        // Debug: Check access token availability
        guard let accessToken = try? KeychainStore.loadString(.accessToken) else {
            AppLogger.warning("No access token available for APNs token update on macOS", category: .general)
            return
        }



        guard let config = Configuration.fromInfoPlist() else {
            AppLogger.warning("No API config available for APNs token update on macOS", category: .general)
            return
        }

        let deviceId = await TimerSyncManager.shared.deviceId
        AppLogger.info("Got deviceId: \(deviceId), updating APN token on macOS", category: .general)
        let apiClient = ApiClient(baseURL: config.baseURL)

        // Retry logic for APN token registration
        let maxRetries = 3
        for attempt in 1...maxRetries {
            do {

                try await apiClient.updateApnsToken(deviceId: deviceId, apnsToken: apnsToken, accessToken: accessToken)
                AppLogger.info("APNs token updated with backend for macOS device: \(deviceId)", category: .general)
                return // Success, exit retry loop
            } catch {
                if attempt == maxRetries {
                    AppLogger.error("Failed to update APNs token with backend on macOS after \(maxRetries) attempts: \(error.localizedDescription)", category: .general)
                } else {
                    AppLogger.warning("APN token update attempt \(attempt) failed on macOS, retrying: \(error.localizedDescription)", category: .general)
                    // Wait before retry
                    _ = try? await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000) // 1, 2, 3 seconds
                }
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate (macOS)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Handle data-only (silent) notifications on macOS
        let userInfo = notification.request.content.userInfo

        if let type = userInfo["type"] as? String, type == "timer_sync" {
            AppLogger.info("Received timer sync APN message on macOS", category: .sync)

            // Parse action from notification and apply event-based sync
            if let actionDict = userInfo["action"] as? [String: Any],
               let actionType = actionDict["action"] as? String,
               let sourceDeviceId = actionDict["deviceId"] as? String,
               let timestampString = actionDict["timestamp"] as? String,
               let timestamp = Double(timestampString) {

                AppLogger.info("Processing timer action from notification: \(actionType), device: \(sourceDeviceId)", category: .sync)

                // Apply the incoming action (event-based sync)
                _Concurrency.Task {