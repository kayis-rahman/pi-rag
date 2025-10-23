import Foundation

public class SessionAPI {
    public static func startSession(completion: ((Bool) -> Void)? = nil) {
        completion?(true)
    }

    public static func stopSession(completion: ((Bool) -> Void)? = nil) {
        completion?(true)
    }

    public static func checkActiveSession(completion: @escaping (Bool) -> Void) {
        completion(false)
    }
}
