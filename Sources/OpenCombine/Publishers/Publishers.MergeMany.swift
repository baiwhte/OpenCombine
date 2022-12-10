//
//  File.swift
//  
//
//  Created by baiwhte on 2022/12/8.
//

extension Publisher {
    public func merge(with other: Self) -> Publishers.MergeMany<Self> {
        .init(self, other)
    }
}

extension Publishers.MergeMany {
    public func merge(with other: Upstream) -> Publishers.MergeMany<Upstream> {
        .init(Array(self.publishers) + [other])
    }
}

extension Publishers {
    /// A publisher created by applying the merge function to an arbitrary number of upstream publishers.
    public struct MergeMany<Upstream> where Upstream : Publisher {
        
        /// The kind of values published by this publisher.
        ///
        /// This publisher uses its upstream publishers’ common output type.
        public typealias Output = Upstream.Output
        
        /// The kind of errors this publisher might publish.
        ///
        /// This publisher uses its upstream publishers’ common failure type.
        public typealias Failure = Upstream.Failure
        
        /// The array of upstream publishers that this publisher merges together.
        public let publishers: [Upstream]
        
        let upstream: AnyPublisher<Upstream.Output, Upstream.Failure>
        
        /// Creates a publisher created by applying the merge function to an arbitrary number of upstream publishers.
        /// - Parameter upstream: A variadic parameter containing zero or more publishers to merge with this publisher.
        public init(_ upstream: Upstream...) {
            self.publishers = upstream
            
            self.upstream = Publishers.Sequence(sequence: upstream)
                .flatMap { $0 }
                .eraseToAnyPublisher()
        }
        
        /// Creates a publisher created by applying the merge function to a sequence of upstream publishers.
        /// - Parameter upstream: A sequence containing zero or more publishers to merge with this publisher.
        public init<S>(_ upstream: S) where Upstream == S.Element, S : Swift.Sequence {
            self.publishers = Array(upstream)
            
            self.upstream = Publishers.Sequence(sequence: upstream)
                .flatMap { $0 }
                .eraseToAnyPublisher()
        }
    }
}

extension Publishers.MergeMany : Publisher {
    public func receive<S>(subscriber: S) where S : Subscriber, Upstream.Failure == S.Failure, Upstream.Output == S.Input {
//        subscriber.receive(subscription: Inner(downstream: subscriber, publishers: publishers))
        upstream.subscribe(subscriber)
    }
}

extension Publishers.MergeMany {
    final class Inner<Downstream: Subscriber> : Subscription
    where Downstream.Input == Output, Downstream.Failure == Failure {
        
        private let downstream: Downstream
        private var subscriptions: [Int : SubscriptionStatus] = [:]
        
        private let lock = UnfairLock.allocate()
        
        private var downstreamDemand = Subscribers.Demand.none
        
        init(downstream: Downstream, publishers: [Upstream]) {
            self.downstream = downstream
            
            for (index, publisher) in publishers.enumerated() {
                publisher.subscribe(UpstreamSubscriber(parent: self, index: index))
            }
        }
        
        deinit {
            lock.deallocate()
        }
        
        func request(_ demand: Subscribers.Demand) {
            demand.assertNonZero()
            
            lock.lock()
            for (_, status) in subscriptions {
                if case .subscribed(let subscription) = status {
                    subscription.request(demand)
                }
            }
            
            if demand == .unlimited {
                downstreamDemand = .unlimited
            } else {
                downstreamDemand = demand * subscriptions.count
            }
            lock.unlock()
        }
        
        func cancel() {
            lock.lock()
            let subscriptions = self.subscriptions
            self.subscriptions = [:]
            lock.unlock()
            
            for (_, status) in subscriptions {
                if case .subscribed(let subscription) = status {
                    subscription.cancel()
                }
            }
        }
        
        //MARK: UpstreamSubscriber
        
        private func receive(subscription: Subscription, at index: Int) {
            lock.lock()
            let status = self.subscriptions[index]
            guard case .awaitingSubscription = status, downstreamDemand > 0 else {
                lock.unlock()
                subscription.cancel()
                return
            }
            self.subscriptions[index] = .subscribed(subscription)
            
            if downstreamDemand != .unlimited {
                downstreamDemand -= 1
            }
            lock.unlock()
        }
        
        private func receive(_ input: Upstream.Output, at index: Int) -> Subscribers.Demand {
            lock.lock()
            let status = self.subscriptions[index]
            guard case .subscribed = status else {
                lock.unlock()
                return .none
            }
            lock.unlock()
            return downstream.receive(input)
        }
        
        private func receive(completion: Subscribers.Completion<Failure>, at index: Int) {
            switch completion {
                case .finished:
                    lock.lock()
                    let subscriptions = self.subscriptions.filter { $0.value == .terminal }
                    lock.unlock()
                    if subscriptions.count > 0 {
                        self.subscriptions[index] = .terminal
                    }
                case .failure:
                    cancel()
                    downstream.receive(completion: completion)
            }
        }
        
        final class UpstreamSubscriber: Subscriber {
            
            let parent: Inner
            let index: Int
            
            typealias Output = Upstream.Output
            
            init(parent: Inner, index: Int) {
                self.parent = parent
                self.index = index
            }
            
            func receive(subscription: Subscription) {
                parent.receive(subscription: subscription, at: index)
            }
            
            func receive(_ input: Output) -> Subscribers.Demand {
                parent.receive(input, at: index)
            }
            
            func receive(completion: Subscribers.Completion<Failure>) {
                parent.receive(completion: completion, at: index)
            }
            
        }
    }
}
