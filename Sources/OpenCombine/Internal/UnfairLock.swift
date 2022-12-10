//
//  File.swift
//  
//
//  Created by baiwhte on 2022/11/24.
//

import Darwin.os

internal protocol Locking {
    func lock()
    
    func unlock()
}

extension Locking {
    public func withLock<U>(_ closure: () throws -> U) rethrows -> U {
        lock()
        defer { unlock() }
        return  try closure()
    }
    
    func withLock<U>(_ body: @autoclosure () throws -> U) rethrows -> U {
        self.lock(); defer { self.unlock() }
        return try body()
    }
    
    func around<U>(_ closure: () throws -> U?) rethrows -> U? {
        self.lock(); defer { self.unlock() }
        
        return  try closure()
    }
}

internal final class UnfairLock: Locking {
    
    private let unfairLock: UnsafeMutablePointer<os_unfair_lock>
    
    internal init() {
        unfairLock = .allocate(capacity: 1)
        
        unfairLock.initialize(to: os_unfair_lock())
    }
    
    deinit {
        unfairLock.deinitialize(count: 1)
        unfairLock.deallocate()
    }
    
    /// Assert that the current thread owns the lock.
    internal func assertOwner() {
        os_unfair_lock_assert_owner(unfairLock)
    }
    
    /// Assert that the current thread does not own the lock.
    ///
    /// If the lock is unlocked or owned by a different thread, this function returns.
    /// If the lock is currently owned by the current thread, this function asserts and terminates the process.
    internal func assertNotOwner() {
        os_unfair_lock_assert_not_owner(unfairLock)
    }
    
    internal func lock() {
        os_unfair_lock_lock(unfairLock)
    }
    
    internal func unlock() {
        os_unfair_lock_unlock(unfairLock)
    }
}

internal final class UnfairRecursiveLock: Locking {
   
   private var mutex = pthread_mutex_t()
    
    init(_ recursive: Bool = true) {
        var attr: pthread_mutexattr_t = pthread_mutexattr_t()
        pthread_mutexattr_init(&attr)
        if recursive {
            pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)
        } else {
            pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_DEFAULT)
        }
        pthread_mutex_init(&mutex, &attr)
    }
    
    deinit {
        pthread_mutex_destroy(&mutex)
    }
    
    func lock() {
        pthread_mutex_lock(&mutex)
    }
    
    func unlock() {
        pthread_mutex_unlock(&mutex)
    }
    
}
