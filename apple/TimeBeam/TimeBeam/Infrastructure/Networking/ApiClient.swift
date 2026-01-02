import Foundation
import CryptoKit
import SwiftUI

/**
 * API Client for TimeBeam backend communication
 * Production-ready with proper error handling and response parsing
 */
public struct ApiClient {
    let baseURL: URL
    private let urlSession: URLSession
    private var accessToken: String?

    /// Callback for authentication failures
    var onAuthenticationFailure: (() -> Void)?
import SwiftUI

    /**
