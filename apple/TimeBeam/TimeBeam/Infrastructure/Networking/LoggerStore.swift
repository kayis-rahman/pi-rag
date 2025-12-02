import os

enum LoggerStore {
    static let timer = Logger(subsystem: "com.timebeam", category: "Timer")
    static let session = Logger(subsystem: "com.timebeam", category: "SessionAPI")
    static let auth = Logger(subsystem: "com.timebeam", category: "Auth")
    static let general = Logger(subsystem: "com.timebeam", category: "General")
}
