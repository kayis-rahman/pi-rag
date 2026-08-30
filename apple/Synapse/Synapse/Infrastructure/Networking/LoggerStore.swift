import os

enum LoggerStore {
    static let timer = Logger(subsystem: "com.synapse", category: "Timer")
    static let session = Logger(subsystem: "com.synapse", category: "SessionAPI")
    static let auth = Logger(subsystem: "com.synapse", category: "Auth")
    static let general = Logger(subsystem: "com.synapse", category: "General")
}
