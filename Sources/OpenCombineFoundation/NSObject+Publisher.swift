//
//  File.swift
//  
//
//  Created by baiwhte on 2022/12/9.
//

import Foundation
import OpenCombine

// The following protocol is so that we can reference `Self` in the Publisher
// below. This is based on a trick used in the the standard library's
// implementation of `NSObject.observe(key path)`
public protocol _KeyValueCodingAndObservingPublishing {
}

extension NSObject : _KeyValueCodingAndObservingPublishing {
}

extension _KeyValueCodingAndObservingPublishing where Self : ObjectiveC.NSObject {
    public func publisher<Value>(for keyPath: Swift.KeyPath<Self, Value>,
                                 options: Foundation.NSKeyValueObservingOptions = [.initial, .new]) -> ObjectiveC.NSObject.OCombine.KeyValueObservingPublisher<Self, Value> {
        OCombine.KeyValueObservingPublisher(object: self, keyPath: keyPath, options: options)
//        ObjectiveC.NSObject.KeyValueObservingPublisher(object: self, keyPath: keyPath, options: options)
    }
}

extension NSObject {
    
//    public func publisher<Value>(for keyPath: Swift.KeyPath<Self, Value>,
//                                 options: Foundation.NSKeyValueObservingOptions = [.initial, .new]) -> ObjectiveC.NSObject.OCombine.KeyValueObservingPublisher<Self, Value> {
//        OCombine.KeyValueObservingPublisher(object: self, keyPath: keyPath, options: options)
//    }
    
    public struct OCombine {
        /// A Combine publisher that produces a new element whenever the observed value changes.
        ///
        /// Use this publisher to integrate a property that’s compliant with key-value observing into a Combine publishing chain.
        /// You can create a publisher of this type with the NSObject instance method publisher(for:options:), passing in the key path
        /// and a set of NSKeyValueObservingOptions.
        public struct KeyValueObservingPublisher<Subject, Value> : Swift.Equatable where Subject : ObjectiveC.NSObject {
            
            public let object: Subject
            
            public let keyPath: Swift.KeyPath<Subject, Value>
            
            public let options: Foundation.NSKeyValueObservingOptions
            
            public init(object: Subject, keyPath: Swift.KeyPath<Subject, Value>, options: Foundation.NSKeyValueObservingOptions) {
                self.object = object
                self.keyPath = keyPath
                self.options = options
            }
            
            public static func == (lhs: ObjectiveC.NSObject.OCombine.KeyValueObservingPublisher<Subject, Value>,
                                   rhs: ObjectiveC.NSObject.OCombine.KeyValueObservingPublisher<Subject, Value>) -> Swift.Bool {
                lhs.object == rhs.object && lhs.keyPath == rhs.keyPath
            }
        }
    }
}

extension NSObject.OCombine.KeyValueObservingPublisher {
    public func didChange() -> OpenCombine.Publishers.Map<ObjectiveC.NSObject.OCombine.KeyValueObservingPublisher<Subject, Value>, Swift.Void> {
        map { _ in () }
    }
}

extension Foundation.NSObject.OCombine.KeyValueObservingPublisher: OpenCombine.Publisher {
    public typealias Output = Value
    public typealias Failure = Swift.Never
    public func receive<S>(subscriber: S) where Value == S.Input, S : OpenCombine.Subscriber, S.Failure == ObjectiveC.NSObject.OCombine.KeyValueObservingPublisher<Subject, Value>.Failure {
        subscriber.receive(subscription: KVOSubscription(downstream: subscriber, object: object, keyPath: keyPath, options: options))
    }
}

extension Foundation.NSObject.OCombine.KeyValueObservingPublisher {
    private final class KVOSubscription<Downstream: OpenCombine.Subscriber>: OpenCombine.Subscription
    where Downstream.Input == Output, Downstream.Failure == Failure {
        
        private let lock = UnfairLock.allocate()
        private let downstream: Downstream
        private var downstreamDemand = Subscribers.Demand.none
        
        private var observation: NSKeyValueObservation?
        private var value: Value?
        
        init(downstream: Downstream, object: Subject, keyPath: Swift.KeyPath<Subject, Value>, options: Foundation.NSKeyValueObservingOptions) {
            self.downstream = downstream
            
            self.observation = object.observe(keyPath, options: options) { [weak self] object, change in
                guard let self = self else { return }
                
                if !change.isPrior {
                    if options.contains(.initial) {
                        self.didChange(change.oldValue)
                    }
                } else {
                    self.didChange(change.oldValue)
                }
                
                self.didChange(change.newValue)
            }
        }
        
        deinit {
            observation = nil
            lock.deallocate()
        }
        
        private func didChange(_ value: Value?) {
            Swift.print("didChange: \(value)")
            guard let value = value else { return }

            lock.lock()
            if downstreamDemand > 0 {
                downstreamDemand -= 1
                self.value = value
                lock.unlock()
                let sDemand = downstream.receive(value)
                if sDemand > 0 {
                    lock.lock()
                    downstreamDemand += sDemand
                    lock.unlock()
                }
            } else {
                lock.unlock()
            }
        }
        
        
        func request(_ demand: OpenCombine.Subscribers.Demand) {
            demand.assertNonZero()
            
            lock.lock()
            downstreamDemand += demand
            if downstreamDemand > 0, let value {
                downstreamDemand -= 1
                lock.unlock()
                let sDemand = downstream.receive(value)
                if sDemand > 0 {
                    lock.lock()
                    downstreamDemand += sDemand
                    lock.unlock()
                }
            } else {
                lock.unlock()
            }
        }
        
        func cancel() {
            lock.lock()
            downstreamDemand = .none
            let o = self.observation
            self.observation = nil
            self.value = nil
            lock.unlock()
            
            if let o {
                o.invalidate()
            }
        }
    }
}
