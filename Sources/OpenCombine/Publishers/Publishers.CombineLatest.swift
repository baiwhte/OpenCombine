//
//  Publishers.combineLatest.swift
//  
//
//  Created by baiwhte on 2022/12/8.
//

extension Publisher {
    /**
     Subscribes to an additional publisher and publishes a tuple upon receiving output from either publisher.
     
     Use combineLatest(_:) when you want the downstream subscriber to receive a tuple of the most-recent element
     from multiple publishers when any of them emit a value. To pair elements from multiple publishers,
     use zip(_:) instead. To receive just the most-recent element from multiple publishers rather than tuples, use merge(with:).
     
     - Tip: The combined publisher doesn’t produce elements until each of its upstream publishers publishes at least one element.
     
     The combined publisher passes through any requests to all upstream publishers. However, it still obeys the demand-fulfilling
     rule of only sending the request amount downstream. If the demand isn’t unlimited, it drops values from upstream publishers.
     It implements this by using a buffer size of 1 for each upstream, and holds the most-recent value in each buffer.
     
     In this example, PassthroughSubject pub1 and also pub2 emit values; as combineLatest(_:) receives input from either upstream publisher,
     it combines the latest value from each publisher into a tuple and publishes it.
     
     ```
     let pub1 = PassthroughSubject<Int, Never>()
     let pub2 = PassthroughSubject<Int, Never>()
     
     cancellable = pub1
        .combineLatest(pub2)
        .sink { print("Result: \($0).") }
     
     pub1.send(1)
     pub1.send(2)
     pub2.send(2)
     pub1.send(3)
     pub1.send(45)
     pub2.send(22)
     
     // Prints:
     //    Result: (2, 2).    // pub1 latest = 2, pub2 latest = 2
     //    Result: (3, 2).    // pub1 latest = 3, pub2 latest = 2
     //    Result: (45, 2).   // pub1 latest = 45, pub2 latest = 2
     //    Result: (45, 22).  // pub1 latest = 45, pub2 latest = 22
     
     ```
     When all upstream publishers finish, this publisher finishes. If an upstream publisher never publishes a value, this publisher never finishes.
     
     - Parameter other: Another publisher to combine with this one.
     - Returns: A publisher that receives and combines elements from this and another publisher.
     */
    public func combineLatest<P>(_ other: P) -> Publishers.CombineLatest<Self, P> where P : Publisher, Self.Failure == P.Failure {
        .init(self, other)
    }
    
    ///  ```
    ///  let cancellable = pub1.combineLatest(pub2) { (first, second) in
    ///         return first * second
    ///     }
    ///     .sink { print(“Result: ($0).”) }
    ///
    ///     pub1.send(1)
    ///     pub1.send(2)
    ///     pub2.send(2)
    ///     pub1.send(9)
    ///     pub1.send(3)
    ///     pub2.send(12)
    ///     pub1.send(13)
    /// Prints:
    ///     Result: 4. (pub1 latest = 2, pub2 latest = 2)
    ///     Result: 18. (pub1 latest = 9, pub2 latest = 2)
    ///     Result: 6. (pub1 latest = 3, pub2 latest = 2)
    ///     Result: 36. (pub1 latest = 3, pub2 latest = 12)
    ///     Result: 156. (pub1 latest = 13, pub2 latest = 12)
    /// ```
    ///
    /// All upstream publishers need to finish for this publisher to finish. If an upstream publisher never publishes a value,
    /// this publisher never finishes. If any of the combined publishers terminates with a failure, this publisher also fails.
    ///
    ///  * other: Another publisher to combine with this one.
    ///  * transform: A closure that receives the most-recent value from each publisher and returns a new value to publish.
    public func combineLatest<P, T>(
        _ other: P,
        _ transform: @escaping (Self.Output, P.Output) -> T
    ) -> Publishers.Map<Publishers.CombineLatest<Self, P>, T> where P : Publisher, Self.Failure == P.Failure {
        combineLatest(other)
            .map(transform)
    }
}

extension Publishers {
    /// A publisher that receives and combines the latest elements from two publishers.
    public struct CombineLatest<A, B> where A : Publisher, B : Publisher, A.Failure == B.Failure {
        /// The kind of values published by this publisher.
        ///
        /// This publisher produces two-element tuples of the upstream publishers’ output types.
        public typealias Output = (A.Output, B.Output)
        
        /// The kind of errors this publisher might publish.
        ///
        /// Use `Never` if this `Publisher` does not publish errors.
        public typealias Failure = A.Failure

        public let a: A
        
        public let b: B
        
        /// Creates a publisher that receives and combines the latest elements from two publishers.
        /// - Parameters:
        ///   - a: The first upstream publisher.
        ///   - b: The second upstream publisher.
        public init(_ a: A, _ b: B) {
            self.a = a
            self.b = b
        }
    }
}

extension Publishers.CombineLatest: Publisher {
    public func receive<S>(subscriber: S) where S : Subscriber, B.Failure == S.Failure, S.Input == (A.Output, B.Output) {
        subscriber.receive(subscription: Inner(downstream: subscriber, a, b))
    }
}

extension Publishers.CombineLatest: Equatable where A: Equatable, B: Equatable {
    public static func == (lhs: Publishers.CombineLatest<A, B>, rhs: Publishers.CombineLatest<A, B>) -> Bool {
        lhs.a == rhs.a && lhs.b == rhs.b
    }
}

extension Publishers.CombineLatest {
    private final class Inner<Downstream: Subscriber>: Subscription
    where Downstream.Input == Output, Downstream.Failure == Failure {
        
        typealias Input = Output
        
        enum UpstreamSource {
            case a
            case b
        }
        
        private let lock = UnfairLock.allocate()
        private var demand: Subscribers.Demand = .none
        
        private var status = (SubscriptionStatus.awaitingSubscription, SubscriptionStatus.awaitingSubscription)

        private var outputA: A.Output?
        private var outputB: B.Output?
        
        private let downstream: Downstream
        
        init(downstream: Downstream, _ a: A, _ b: B) {
            self.downstream = downstream
            a.subscribe(UpstreamSubscriber(parent: self, source: UpstreamSource.a))
            b.subscribe(UpstreamSubscriber(parent: self, source: UpstreamSource.b))
        }
        
        deinit {
            lock.deallocate()
        }
        
        //MARK: Subscription
        func request(_ demand: Subscribers.Demand) {
            demand.assertNonZero()
            
            lock.lock()
            if case .subscribed(let subscription) = status.0 {
                subscription.request(demand)
            }
            
            if case .subscribed(let subscription) = status.1 {
                subscription.request(demand)
            }
            self.demand += demand
            lock.unlock()
        }
        
        //MARK: Cancellable
        func cancel() {
            lock.lock()
            demand = .none
            outputA = nil
            outputB = nil
            let status = self.status
            lock.unlock()
            
            if case .subscribed(let subscription) = status.0 {
                subscription.cancel()
            }
            
            if case .subscribed(let subscription) = status.1 {
                subscription.cancel()
            }
        }
        
        //MARK: UpstreamSubscriber
        
        private func receive(subscription: Subscription, from source: UpstreamSource) {
            switch source {
                case UpstreamSource.a:
                    status.0 = .subscribed(subscription)
                case UpstreamSource.b:
                    status.1 = .subscribed(subscription)
            }
        }
        
        private func receive(_ input: Any, from source: UpstreamSource) -> Subscribers.Demand {
            lock.lock()
            switch source {
                case UpstreamSource.a:
                    outputA = input as? A.Output
                case UpstreamSource.b:
                    outputB = input as? B.Output
            }
            
            guard demand > 0 else {
                lock.unlock()
                return .none
            }
            
            if let outputA, let outputB {
                demand -= 1
                lock.unlock()
                let sDemand = downstream.receive((outputA, outputB))
                if sDemand > 0 {
                    lock.lock()
                    demand += sDemand
                    lock.unlock()
                }
            } else {
                lock.unlock()
            }
            
            return .none
        }
        
        private func receive(completion: Subscribers.Completion<Failure>, from source: UpstreamSource) {
            lock.lock()
            switch completion {
                case .finished:
                    switch source {
                        case UpstreamSource.a:
                            status.0 = .terminal
                        case UpstreamSource.b:
                            status.1 = .terminal
                    }
                    
                    switch status {
                        case (.terminal, .terminal):
                            lock.unlock()
                            cancel()
                            downstream.receive(completion: completion)
                        default:
                            lock.unlock()
                            break
                    }
                    
                case .failure(_):
                    lock.unlock()
                    cancel()
                    downstream.receive(completion: completion)
                    break
            }
        }
        
        private final class UpstreamSubscriber<Output>: Subscriber {
            
            private let lock = UnfairLock.allocate()
            private var status = SubscriptionStatus.awaitingSubscription
            private let parent: Inner
            private let source: UpstreamSource
            
            init(parent: Inner, source: UpstreamSource) {
                self.parent = parent
                self.source = source
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
                parent.receive(subscription: subscription, from: source)
            }
            
            func receive(_ input: Output) -> Subscribers.Demand {
                lock.lock()
                guard case .subscribed = status else {
                    lock.unlock()
                    return .none
                }
                lock.unlock()
                
                return parent.receive(input, from: source)
            }
            
            func receive(completion: Subscribers.Completion<Failure>) {
                return parent.receive(completion: completion, from: source)
            }
        }
    }
}
