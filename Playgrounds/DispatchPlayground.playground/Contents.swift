//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import JoshLib

PlaygroundPage.current.needsIndefiniteExecution = true

let arrayOne = ["1️⃣","2️⃣","3️⃣","4️⃣","5️⃣","6️⃣","7️⃣","8️⃣","9️⃣","🔟"]
let arrayTwo = Array(1...10)

let taskOne = {
    for i in 0..<10 {
        print(arrayOne[i])
        Thread.sleep(forTimeInterval: 0.1)
    }
}

let taskTwo = {
    for i in 0..<10 {
        print(arrayTwo[i])
        Thread.sleep(forTimeInterval: 0.1)
    }
}


func testConcurrentQueue(then nextTask: @escaping ()->Void) {
    print("*****************************")
    print("Concurrent Queue Example:")
    print("*****************************")

    Dispatch.concurrently(task: taskOne)
    Dispatch.concurrently(task: taskTwo)

    Dispatch.concurrentlySync(task: {
        print("This will probably happen before either task")
    })
  
    
    Dispatch.concurrentBarrier(task: {
        print("This will wait until both tasks complete")
    }, then: nextTask)
}

func testSerialQueue() {
    print("*****************************")
    print("Serial Queue Example:")
    print("*****************************")

    Dispatch.serially(task: taskOne)

    Dispatch.seriallySync(task: {
        print("This will block until task one compeletes")
    })
    
    Dispatch.serially(task: taskTwo)
    
    Dispatch.seriallySync(task: {
        print("Serial queues do not need barriers. This is called last.")
    }, then: {
        print("And this is where you update the main thread!")
    })
}


testConcurrentQueue(then: {
    testSerialQueue()
})
