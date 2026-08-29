import Foundation

/// Future voice capture boundary. English dictation and the Raspberry Pi
/// Malayalam bridge can conform without coupling the domain to audio tooling.
protocol VoiceCaptureProviding: Sendable {
    func capture() async throws -> VoiceCaptureResult
}

struct VoiceCaptureResult: Sendable {
    let text: String
    let localeIdentifier: String
    let capturedAt: Date

    init(text: String, localeIdentifier: String, capturedAt: Date = Date()) {
        self.text = text
        self.localeIdentifier = localeIdentifier
        self.capturedAt = capturedAt
    }
}

struct DeferredVoiceCaptureProvider: VoiceCaptureProviding {
    enum Error: Swift.Error {
        case notImplemented
    }

    func capture() async throws -> VoiceCaptureResult {
        throw Error.notImplemented
    }
}
