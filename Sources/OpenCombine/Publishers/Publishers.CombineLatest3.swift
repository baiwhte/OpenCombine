//
//  Publishers.combineLatest3.swift
//  
//
//  Created by baiwhte on 2022/12/8.
//

import Foundation

extension Publisher {
    /// Subscribes to two additional publishers and publishes a tuple upon receiving output from any of the publishers.
    ///
    /// The combined publisher passes through any requests to *all* upstream publishers. However, it still obeys
    /// the demand-fulfilling rule of only sending the request amount downstream. If the demand isn’t `.unlimited`,
    /// it drops values from upstream publishers. It implements this by using a buffer size of 1 for each upstream,
    /// and holds the most recent value in each buffer.
    ///
    /// All upstream publishers need to finish for this publisher to finish. If an upstream publisher never publishes
    /// a value, this publisher never finishes.
    ///
    /// In this example, three instances of PassthroughSubject emit values; as combineLatest(_:_:) receives input from
    /// any of the upstream publishers, it combines the latest value from each publisher into a tuple and publishes it:
    ///
    ///     let pub = PassthroughSubject<Int, Never>()
    ///     let pub2 = PassthroughSubject<Int, Never>()
    ///     let pub3 = PassthroughSubject<Int, Never>()
    ///
    ///      cancellable = pub
    ///          .combineLatest(pub2, pub3)
    ///          .sink { print("Result: \($0).") }
    ///
    ///      pub.send(1)
    ///      pub.send(2)
    ///      pub2.send(2)
    ///      pub3.send(9)
    ///
    ///      pub.send(3)
    ///      pub2.send(12)
    ///      pub.send(13)
    ///      pub3.send(19)
    ///
    ///      // Prints:
    ///      //  Result: (2, 2, 9).
    ///      //  Result: (3, 2, 9).
    ///      //  Result: (3, 12, 9).
    ///      //  Result: (13, 12, 9).
    ///      //  Result: (13, 12, 19).
    ///
    /// If any of the combined publishers terminates with a failure, this publisher also fails.
    ///
    /// - Parameters:
    ///   - publisher1: A second publisher to combine with this one.
    ///   - publisher2: A third publisher to combine with this one.
    /// - Returns: A publisher that receives and combines elements from this publisher and two other publishers.
    public func combineLatest<P, Q>(
        _ publisher1: P,
        _ publisher2: Q
    ) -> Publishers.CombineLatest3<Self, P, Q> where P : Publisher, Q : Publisher, Self.Failure == P.Failure, P.Failure == Q.Failure {
        .init(self, publisher1, publisher2)
    }
    
    /// Subscribes to two additional publishers and invokes a closure upon receiving output from any of the publishers.
    ///
    /// Use combineLatest<P, Q>(_:,_:) to combine the current and two additional publishers and transform them using a
    /// closure you specify to publish a new value to the downstream.
    ///
    /// - Tip: The combined publisher doesn’t produce elements until each of its upstream publishers publishes at least one element.
    ///
    /// The combined publisher passes through any requests to *all* upstream publishers. However, it still obeys the demand-fulfilling
    /// rule of only sending the request amount downstream. If the demand isn’t `.unlimited`, it drops values from upstream publishers.
    /// It implements this by using a buffer size of 1 for each upstream, and holds the most recent value in each buffer.
    /// All upstream publishers need to finish for this publisher to finish. If an upstream publisher never publishes a value,
    /// this publisher never finishes. If any of the combined publishers terminates with a failure, this publisher also fails.
    ///
    /// In the example below, combineLatest() receives the most-recent values published by three publishers, multiplies them together, and republishes the result:
    ///
    ///     let pub = PassthroughSubject<Int, Never>()
    ///     let pub2 = PassthroughSubject<Int, Never>()
    ///     let pub3 = PassthroughSubject<Int, Never>()
    ///
    ///      cancellable = pub
    ///          .combineLatest(pub2, pub3) { firstValue, secondValue, thirdValue in
    ///               return firstValue * secondValue * thirdValue
    ///          }
    ///          .sink { print("Result: \($0).") }
    ///
    ///    pub.send(1)
    ///    pub.send(2)
    ///    pub2.send(2)
    ///    pub3.send(10)
    ///
    ///    pub.send(9)
    ///    pub3.send(4)
    ///    pub2.send(12)
    ///
    ///    // Prints:
    ///    //  Result: 40.     // pub = 2, pub2 = 2, pub3 = 10
    ///    //  Result: 180.    // pub = 9, pub2 = 2, pub3 = 10
    ///    //  Result: 72.     // pub = 9, pub2 = 2, pub3 = 4
    ///    //  Result: 432.    // pub = 9, pub2 = 12, pub3 = 4
    ///
    /// - Parameters:
    ///   - publisher1: A second publisher to combine with this one.
    ///   - publisher2: A third publisher to combine with this one.
    ///   - transform: A closure that receives the most recent value from each publisher and returns a new value to publish.
    /// - Returns: A publisher that receives and combines elements from this publisher and two other publishers.
    public func combineLatest<P, Q, T>(
        _ publisher1: P,
        _ publisher2: Q,
        _ transform: @escaping (Self.Output, P.Output, Q.Output) -> T
    ) -> Publishers.Map<Publishers.CombineLatest3<Self, P, Q>, T> where P : Publisher, Q : Publisher, Self.Failure == P.Failure, P.Failure == Q.Failure {
        combineLatest(publisher1, publisher2)
            .map(transform)
    }
}

extension Publishers {
    /// A publisher that receives and combines the latest elements from three publishers.
    public struct CombineLatest3<A, B, C> where A : Publisher, B : Publisher, C : Publisher, A.Failure == B.Failure, B.Failure == C.Failure {
        
        /// The kind of values published by this publisher.
        ///
        /// This publisher produces three-element tuples of the upstream publishers’ output types.
        public typealias Output = (A.Output, B.Output, C.Output)
        
        /// The kind of errors this publisher might publish.
        ///
        /// Use `Never` if this `Publisher` does not publish errors.
        public typealias Failure = A.Failure
        
        public let a: A
        
        public let b: B
        
        public let c: C
        
        public init(
            _ a: A,
            _ b: B,
            _ c: C
        ) {
            self.a = a
            self.b = b
            self.c = c
        }
    }
}

extension Publishers.CombineLatest3: Publisher {
    public func receive<S>(subscriber: S) where S : Subscriber, C.Failure == S.Failure, S.Input == (A.Output, B.Output, C.Output) {
        a.combineLatest(b)
            .combineLatest(c)
            .map {
                ($0.0, $0.1, $1)
            }
            .receive(subscriber: subscriber)
    }
}

extension Publishers.CombineLatest3: Equatable where A: Equatable, B: Equatable, C: Equatable {
    public static func == (lhs: Publishers.CombineLatest3<A, B, C>, rhs: Publishers.CombineLatest3<A, B, C>) -> Bool {
        lhs.a == rhs.a && lhs.b == rhs.b && lhs.c == rhs.c
    }
}
