import Foundation


fileprivate let _dispatchSpecificKey : DispatchSpecificKey = DispatchSpecificKey<UInt8>()

fileprivate let _mainContext : UInt8 = UInt8.max
fileprivate let _serialContext : UInt8 = 11
fileprivate let _concurrentContext : UInt8 = 22

fileprivate let _mainQueue : DispatchQueue = {
    DispatchQueue.main.setSpecific(key: _dispatchSpecificKey, value: _mainContext)
    return DispatchQueue.main
}()

fileprivate let _serialQueue : DispatchQueue = {
    let label =  (Bundle.main.bundleIdentifier ?? "com.missingBundle") + ".serialQueue"
    let queue =   DispatchQueue(label: label)//, qos: DispatchQoS.userInitiated)
    queue.setSpecific(key: _dispatchSpecificKey, value: _serialContext)
    return queue
}()



fileprivate let _concurrentQueue : DispatchQueue = {
    let label =  (Bundle.main.bundleIdentifier ?? "com.missingBundle") + ".concurrentQueue"
    let queue =   DispatchQueue(label: label, attributes: .concurrent)
    queue.setSpecific(key: _dispatchSpecificKey, value: _concurrentContext)
    return queue
}()

fileprivate var isMainQueue : Bool { return DispatchQueue.getSpecific(key: _dispatchSpecificKey) == _mainContext }
fileprivate var isSerialQueue : Bool { return DispatchQueue.getSpecific(key: _dispatchSpecificKey) == _serialContext }
fileprivate var isConcurrentQueue : Bool { return DispatchQueue.getSpecific(key: _dispatchSpecificKey) == _concurrentContext }

public var serialSuspended : Bool = false {
    willSet {
        if newValue {
            _serialQueue.suspend()
            
        } else {
            _serialQueue.resume()
        }
    }
}

internal var concurrentSuspended : Bool = false {
    willSet {
        if newValue {
            _concurrentQueue.suspend()
            
        } else {
            _concurrentQueue.resume()
        }
    }
}

public func asyncSerialTask(_ task: @escaping ()->(), onComplete completionHandler: (()->())? = nil){
    let _ = _serialQueue

    if isSerialQueue {
        task()
        completionHandler?()
    } else {
        _serialQueue.async(execute: {
            task()
            if let execute = completionHandler {
                asyncMain(execute)
            }
        })
    }
}

public func syncSerialTask(_ task: @escaping ()->()) {
    let _ = _serialQueue

    if isSerialQueue {
        task()
    } else {
        _serialQueue.sync(execute: task)
    }
}


public func asyncTask(_ task: @escaping ()->(), onComplete completionHandler: (()->())? = nil) {
    let _ = _concurrentQueue
    
    if isConcurrentQueue {
        task()
        completionHandler?()
    } else {
        
        _concurrentQueue.async(execute: {
            task()
            if let execute = completionHandler {
                asyncMain(execute)
            }
        })
    }
}

public func syncTask(_ task: @escaping ()->()) {
    let _ = _concurrentQueue
    
    if isConcurrentQueue {
        task()
    } else {
        _concurrentQueue.sync(execute: task)
    }
}

public func barrierTask(_ task: @escaping ()->(), onComplete completionHandler: (()->())? = nil) {
    _concurrentQueue.async(flags: DispatchWorkItemFlags.barrier, execute: task)
}

public func asyncMain(_ task: @escaping ()->()) {
    let _ = _mainQueue

    if isMainQueue {
        task()
    } else {
        _mainQueue.async(execute: task)
    }
}
