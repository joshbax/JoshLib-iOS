import Foundation

fileprivate let _dispatchSpecificKey : DispatchSpecificKey = DispatchSpecificKey<UInt8>()

fileprivate struct _DispatchContext {
    fileprivate static let _mainContext : UInt8 = UInt8.max
    fileprivate static let _serialContext : UInt8 = 11
    fileprivate static let _concurrentContext : UInt8 = 22
}

fileprivate let _mainQueue : DispatchQueue = {
    DispatchQueue.main.setSpecific(key: _dispatchSpecificKey, value: _DispatchContext._mainContext)
    return DispatchQueue.main
}()

fileprivate let _serialQueue : DispatchQueue = {
    let label =  (Bundle.main.bundleIdentifier ?? "com.missingBundle") + ".serialQueue"
    let queue =   DispatchQueue(label: label)
    queue.setSpecific(key: _dispatchSpecificKey, value: _DispatchContext._serialContext)
    return queue
}()

fileprivate let _concurrentQueue : DispatchQueue = {
    let label =  (Bundle.main.bundleIdentifier ?? "com.missingBundle") + ".concurrentQueue"
    let queue =   DispatchQueue(label: label, attributes: .concurrent)
    queue.setSpecific(key: _dispatchSpecificKey, value: _DispatchContext._concurrentContext)
    return queue
}()


public class Dispatch {
    
    public typealias Task = ()->()
    
    public enum TaskType {
        case async, sync, barrierAsync
    }
    
    public enum Queue {
        case serial, concurrent, main
        
        fileprivate var dispatchQueue : DispatchQueue {
            switch self {
            case .serial:
                return _serialQueue
            case .concurrent:
                return _concurrentQueue
            case .main:
                return _mainQueue
            }
        }
        
        fileprivate var isCurrentQueue : Bool {
            let queueSpecific = DispatchQueue.getSpecific(key: _dispatchSpecificKey)
            
            switch self {
            case .serial:
                return queueSpecific == _DispatchContext._serialContext
            case .concurrent:
                return queueSpecific == _DispatchContext._concurrentContext
            case .main:
                return queueSpecific == _DispatchContext._mainContext
                
            }
        }
    
    }
  
    public static func execute(as taskType: Dispatch.TaskType, on queue: Dispatch.Queue, withDelay asyncDelay: TimeInterval = 0, task: @escaping Dispatch.Task, then completionHandler: (Dispatch.Task)? = nil ) {
        
        let taskBlock = {
            task()
            if let completionHandler = completionHandler  {
                Dispatch.main(task: completionHandler)
            }
        }
        
        let isTaskDelayed = (taskType == .async && asyncDelay > 0)
        let isBarrier = taskType == .barrierAsync
        let areWeOnTaskQueue = Dispatch.isCurrentQueue(equalTo: queue)
        
        let canExecuteImmediately = areWeOnTaskQueue && !isTaskDelayed && !isBarrier
        
        if canExecuteImmediately {
            
            taskBlock()
            
        } else {
            
            switch  taskType {
            case .sync:
                queue.dispatchQueue.sync(execute: taskBlock)
            case .async:
                
                if asyncDelay > 0 {
                    queue.dispatchQueue.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(Int(asyncDelay * 1000)), execute: taskBlock)
                } else {
                    queue.dispatchQueue.async(execute: taskBlock)
                }
                
            case .barrierAsync:
                queue.dispatchQueue.async(flags: DispatchWorkItemFlags.barrier, execute: taskBlock)

            }
        }
    }
    
    public static func async(on queue: Dispatch.Queue = Dispatch.Queue.serial, withDelay asyncDelay: TimeInterval = 0, task: @escaping Dispatch.Task, then completionHandler: (Dispatch.Task)? = nil ) {
        Dispatch.execute(as: Dispatch.TaskType.async, on: queue, withDelay: asyncDelay, task: task, then: completionHandler)
    }
    
    public static func sync(on queue: Dispatch.Queue = Dispatch.Queue.serial, task: @escaping Dispatch.Task, then completionHandler: (Dispatch.Task)? = nil ) {
        Dispatch.execute(as: Dispatch.TaskType.sync, on: queue, task: task, then: completionHandler)
    }

    
    
    private static func runCompletionHandler(_ completionHandler: (Dispatch.Task)? = nil) {
        guard let completionHandler = completionHandler else { return }
        Dispatch.main(task: completionHandler)
    }
    
    public static func serially(task: @escaping Dispatch.Task, then completionHandler: (Dispatch.Task)? = nil) {
        Dispatch.async(on: Dispatch.Queue.serial, task: task, then: completionHandler)
    }
    
    public static func seriallySync(task: @escaping Dispatch.Task, then completionHandler: (Dispatch.Task)? = nil) {
        Dispatch.sync(on: Dispatch.Queue.serial, task: task, then: completionHandler)
    }
    
    public static func concurrently(task: @escaping Dispatch.Task, then completionHandler: (Dispatch.Task)? = nil) {
        Dispatch.async(on: Dispatch.Queue.concurrent, task: task, then: completionHandler)
    }
    
    public static func concurrentlySync(task: @escaping Dispatch.Task, then completionHandler: (Dispatch.Task)? = nil) {
        Dispatch.sync(on: Dispatch.Queue.concurrent, task: task, then: completionHandler)
    }
    
    public func concurrentBarrier(_ task: @escaping ()->(), onComplete completionHandler: (()->())? = nil) {
        Dispatch.execute(as: Dispatch.TaskType.barrierAsync, on: Dispatch.Queue.concurrent, task: task, then: completionHandler)
    }
    
    public static func main(task: @escaping Dispatch.Task) {
        Dispatch.async(on: Dispatch.Queue.main, task: task)
    }
    
    public static func isCurrentQueue(equalTo queue: Dispatch.Queue) -> Bool {
        return queue.isCurrentQueue
    }

    
    public static func setSuspended(_ suspended: Bool, on queue: Dispatch.Queue) {
        guard queue != .main else { fatalError() }
        
        if suspended {
            queue.dispatchQueue.suspend()
        } else {
            queue.dispatchQueue.resume()
        }
    }
    

}

