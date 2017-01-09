import Foundation
import os
import os.log

func LogVerbose(_ message: Any, _ path: String = #file, _ function: String = #function, line: Int = #line) {
    Log.sharedInstance.log(LogType.verbose, message: message, path: path, function: function, line: line)
}

func LogDebug(_ message: Any, _ path: String = #file, _ function: String = #function, line: Int = #line) {
    Log.sharedInstance.log(LogType.debug, message: message, path: path, function: function, line: line)
}

func LogInfo(_ message: Any, _ path: String = #file, _ function: String = #function, line: Int = #line) {
    Log.sharedInstance.log(LogType.info, message: message, path: path, function: function, line: line)
}

func LogWarn(_ message: Any, _ path: String = #file, _ function: String = #function, line: Int = #line) {
    Log.sharedInstance.log(LogType.warning, message: message, path: path, function: function, line: line)
}

func LogError(_ message: Any, _ path: String = #file, _ function: String = #function, line: Int = #line) {
    Log.sharedInstance.log(LogType.error, message: message, path: path, function: function, line: line)
}



enum LogType {
    case verbose, debug, info, warning, error
    
    @available(iOS 10.0, *)
    var asOSLogType : OSLogType {
        switch self {
        case .verbose:
            return OSLogType.default
        case .debug:
            return OSLogType.debug
        case .info:
            return OSLogType.info
        case .warning:
            return OSLogType.error
        case .error:
            return OSLogType.fault
        }
    }
    
    var logPrefix : String {
        switch self {
        case .verbose:
            return "[VERBOSE]"
        case .debug:
            return "[DEBUG]"
        case .info:
            return "[INFO]"
        case .warning:
            return "[WARN]"
        case .error:
            return "[ERROR]"
        }
        
    }
}

struct Log {
    
    var dateFormat = "yyyy-MM-dd HH:mm:ss.SSS" {
        didSet {
            _dateFormatter.dateFormat = dateFormat
        }
    }
    
    let _dateFormatter : DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return df
    }()
    
    var dateString : String {
        return _dateFormatter.string(from: Date())
    }
    
    @available(iOS 10.0, *)
    fileprivate static let _os_log : OSLog = OSLog(subsystem: "co.momentlens.MomentCaseConnector", category: "CaseConnectorTestApp")
    
    fileprivate init() {
    }
    
    static let sharedInstance : Log = {
        return Log()
    }()
    
    static func threadName() -> String {
        if Thread.isMainThread {
            return "main"
        } else {
            if let threadName = Thread.current.name , !threadName.isEmpty {
                return threadName
            } else if let queueName = DispatchQueue.currentLabel { //sketchy. see link below
                return queueName
            } else {
                return String(format: "%p", Thread.current)
            }
        }
    }
    
    func log(_ logType: LogType,  message: @autoclosure () -> Any, path: String = #file, function: String = #function, line: Int = #line) {
        let dateStr = dateString
        let file = path.components(separatedBy: "/").last?.components(separatedBy: ".").first ?? "$UnknownFile"
        let resolvedMessage = "[\(dateStr)] |\(Log.threadName())| \(file).\(function) (\(line)) \(logType.logPrefix): \(message())"
        
        DispatchQueue.main.async (execute: {
            if #available(iOS 10.0, *) {
                os_log("%s", log:Log._os_log, type: logType.asOSLogType, resolvedMessage)
            } else {
                print(resolvedMessage)
            }
        })
    }
}

//Stolen from: https://lists.swift.org/pipermail/swift-users/Week-of-Mon-20160613/002280.html
extension DispatchQueue {
    class var currentLabel: String? {
        return String(validatingUTF8: __dispatch_queue_get_label(nil))
    }
}
