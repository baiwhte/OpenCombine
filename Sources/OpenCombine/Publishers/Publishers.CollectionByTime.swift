//
//  Publishers.CollectByTime.swift
//  
//
//  Created by baiwhte on 2022/12/7.
//

extension Publisher {
    /**
     Collects elements by a given time-grouping strategy, and emits a single array of the collection.
     
     Use collect(_:options:) to emit arrays of elements on a schedule specified by a Scheduler and Stride that you provide. At the end of each scheduled interval, the publisher sends an array that contains the items it collected. If the upstream publisher finishes before filling the buffer, the publisher sends an array that contains items it received. This may be fewer than the number of elements specified in the requested Stride.
     
     If the upstream publisher fails with an error, this publisher forwards the error to the downstream receiver instead of sending its output.
     
     The example above collects timestamps generated on a one-second Timer in groups (Stride) of five.
     
     let sub = Timer.publish(every: 1, on: .main, in: .default)
                        .autoconnect()
                        .collect(.byTime(RunLoop.main, .seconds(5)))
                        .sink { print("\($0)", terminator: "\n\n") }
     
     // Prints: "[2020-01-24 00:54:46 +0000, 2020-01-24 00:54:47 +0000,
     //          2020-01-24 00:54:48 +0000, 2020-01-24 00:54:49 +0000,
     //          2020-01-24 00:54:50 +0000]"
     
     
     - Note: When this publisher receives a request for .max(n) elements, it requests .max(count * n) from the upstream publisher.
     
     - Parameters:
     - strategy: The timing group strategy used by the operator to collect and publish elements.
     - options: Scheduler options to use for the strategy.
     - Returns: A publisher that collects elements by a given strategy, and emits a single array of the collection.
     */
    public func collect<S>(
        _ strategy: Publishers.TimeGroupingStrategy<S>,
        options: S.SchedulerOptions? = nil
    ) -> Publishers.CollectByTime<Self, S> where S : Scheduler {
        .init(upstream: self, strategy: strategy, options: options)
    }
}

extension Publishers {
    public enum TimeGroupingStrategy<Context> where Context : Scheduler {
        /// A grouping that collects and periodically publishes items.
        case byTime(Context, Context.SchedulerTimeType.Stride)
        
        /// A grouping that collects and publishes items periodically or when a buffer reaches a maximum size.
        case byTimeOrCount(Context, Context.SchedulerTimeType.Stride, Int)
    }
    
    /// A publisher that buffers and periodically publishes its items.
    public struct CollectByTime<Upstream, Context> where Upstream : Publisher, Context : Scheduler {
        
        /// The kind of values published by this publisher.
        ///
        /// This publisher publishes arrays of its upstream publisher’s output type.
        public typealias Output = [Upstream.Output]
        
        /// The kind of errors this publisher might publish.
        ///
        /// This publisher uses its upstream publisher’s failure type.
        public typealias Failure = Upstream.Failure
        
        /// The publisher that this publisher receives elements from.
        public let upstream: Upstream
        
        /// The strategy with which to collect and publish elements.
        public let strategy: Publishers.TimeGroupingStrategy<Context>
        
        /// Scheduler options to use for the strategy.
        public let options: Context.SchedulerOptions?
        
        /// Creates a publisher that buffers and periodically publishes its items.
        /// - Parameters:
        ///   - upstream: The publisher that this publisher receives elements from.
        ///   - strategy: The strategy with which to collect and publish elements.
        ///   - options: Scheduler options to use for the strategy.
        public init(
            upstream: Upstream,
            strategy: Publishers.TimeGroupingStrategy<Context>,
            options: Context.SchedulerOptions?
        ) {
            self.upstream = upstream
            self.strategy = strategy
            self.options  = options
        }
    }
}

extension Publishers.CollectByTime: Publisher {
    
    /// This function is called to attach the specified `Subscriber` to this `Publisher` by `subscribe(_:)`
    ///
    /// - SeeAlso: `subscribe(_:)`
    /// - Parameters:
    ///     - subscriber: The subscriber to attach to this `Publisher`.
    ///                   once attached it can begin to receive values.
    public func receive<S>(subscriber: S) where S : Subscriber, Upstream.Failure == S.Failure, S.Input == [Upstream.Output] {
        upstream.receive(subscriber: Inner(downstream: subscriber, strategy: strategy, options: options))
    }
}

extension Publishers.CollectByTime {
    fileprivate final class Inner<Downstream: Subscriber>
    : Subscription,
      Subscriber,
      CustomStringConvertible,
      CustomReflectable,
      CustomPlaygroundDisplayConvertible
    where Downstream.Input == [Upstream.Output],
          Downstream.Failure == Upstream.Failure
    {
        typealias Input = Upstream.Output
        typealias Failure = Upstream.Failure
        
        private let lock = UnfairLock.allocate()
        private var status = SubscriptionStatus.awaitingSubscription
        private let downstream: Downstream
        
        private let context: Context
        private let interval: Context.SchedulerTimeType.Stride
        private let count: Int
        
        private var downstreamDemand = Subscribers.Demand.none
        private var cancellable: Cancellable?
        
        /// Scheduler options to use for the strategy.
        private let options: Context.SchedulerOptions?
        
        private var buffer: [Input] = []
        
        init(
            downstream: Downstream,
            strategy: Publishers.TimeGroupingStrategy<Context>,
            options: Context.SchedulerOptions?
        ) {
            self.downstream = downstream
            switch strategy {
                case .byTime(let context, let stride):
                    self.context = context
                    self.interval = stride
                    self.count = 0
                case .byTimeOrCount(let context, let stride, let count):
                    self.context = context
                    self.interval = stride
                    self.count = count
            }
            self.options  = options
        }
        
        deinit {
            lock.deallocate()
        }
        
        //MARK: Subscriber
        func receive(subscription: Subscription) {
            lock.lock()
            guard case .awaitingSubscription = status else {
                lock.unlock()
                subscription.cancel()
                return
            }

            status = .subscribed(subscription)
            lock.unlock()
            downstream.receive(subscription: self)
            
            self.cancellable?.cancel()
            let after = context.now.advanced(by: self.interval)
            self.cancellable = context.schedule(after: after, interval: interval) {
                self.scheduleTask()
            }
        }
        
        func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            lock.lock()
            guard case .subscribed = status else {
                lock.unlock()
                return .none
            }

            buffer.append(input)
            let count = buffer.count
            lock.unlock()
            
            if self.count > 0, self.count == count {
                scheduleTask()
            }

            return count > 0 ? .none : .max(1)
        }
        
        func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            lock.lock()
            guard case .subscribed(let subscription) = status else {
                lock.unlock()
                return 
            }
            
            status = .terminal
            cancellable?.cancel()
            cancellable = nil
            let buffer = self.buffer
            self.buffer.removeAll(keepingCapacity: false)
            lock.unlock()
            
            subscription.cancel()
            
            context.schedule(options: options) {
                if case .finished = completion, buffer.count > 0 {
                    _ = self.downstream.receive(buffer)
                }
                
                self.downstream.receive(completion: completion)
            }
        }
        
        //MARK: Subscription
        func request(_ demand: Subscribers.Demand) {
            demand.assertNonZero()
            
            lock.lock()
            guard case .subscribed(let subscription) = status else {
                lock.unlock()
                return
            }
            
            var sDemand = Subscribers.Demand.none
            if count > 0 {
                sDemand = demand * count
                downstreamDemand = .unlimited
            } else {
                downstreamDemand += demand
                sDemand = .max(1)
            }
            lock.unlock()
            subscription.request(sDemand)
        }
        
        //MARK: Cancellable
        func cancel() {
            lock.lock()
            guard case .subscribed(let subscription) = status else {
                lock.unlock()
                return
            }
            
            status = .terminal
            cancellable?.cancel()
            cancellable = nil
            buffer = []
            lock.unlock()
            
            subscription.cancel()
        }
        
        private func scheduleTask() {
    
            lock.lock()
            guard case .subscribed = status else {
                lock.unlock()
                return
            }

            if count == 0, downstreamDemand == 0 {
                lock.unlock()
                return
            }
            
            let buffer = self.buffer
            self.buffer.removeAll(keepingCapacity: true)
            lock.unlock()
            
            guard !buffer.isEmpty else { return }

            let sDemand = downstream.receive(buffer)
            if count == 0 {
                lock.lock()
                downstreamDemand -= 1
                downstreamDemand += sDemand
                lock.unlock()
            }
        }
        
        var description: String { return "CollectByTime" }
        
        var customMirror: Mirror {
            lock.lock()
            defer { lock.unlock() }
            let children: [Mirror.Child] = [
                ("downstream", downstream),
//                ("upstreamSubscription", subscription as Any),
                ("buffer", buffer),
                ("count", count)
            ]
            return Mirror(self, children: children)
        }
        
        var playgroundDescription: Any { return description }
    }
}
