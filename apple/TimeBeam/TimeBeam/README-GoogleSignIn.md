Google Sign-In integration notes (TimeBeam iOS)

Add SPM dependency
- In Xcode: File > Add Packages... > Use the official Google Sign-In iOS package (or the SDK URL from Google docs). Example SPM URL: https://github.com/google/GoogleSignIn-iOS

Info.plist entries
- Add a URL type with the reversed client id as the URL scheme. (Google Cloud console -> iOS OAuth client -> reversed client id)
- Optionally add `GOOGLE_CLIENT_ID` as a string key in Info.plist with the iOS client id.
- Add `API_BASE_URL` key for the backend base URL (e.g., http://localhost:8080 or production endpoint).

App lifecycle
- If using SwiftUI App struct (TimeBeamApp.swift) forward open URL events:

    @main
    struct TimeBeamApp: App {
        var body: some Scene {
            WindowGroup {
                ContentView()
                    .onOpenURL { url in
                        _ = AuthManager.shared.handleOpenURL(url)
                    }
            }
        }
    }

- Or implement AppDelegate methods and forward to GIDSignIn if required by the SDK version.

Files added
- Services/AuthManager.swift
- Networking/ApiClient.swift
- Utils/KeychainHelper.swift
- Views/SignInView.swift

Testing
- Ensure the OAuth client ID in Info.plist matches the one created in Google Cloud console.
- Run the app, tap Sign in with Google, complete the flow, verify backend receives POST /api/auth/login with {email} and responds with accessToken, then check Keychain store.

Security note
- This current flow sends only the email to the backend. For production, switch to verifying Google id_token server-side (send id_token to backend and validate).
